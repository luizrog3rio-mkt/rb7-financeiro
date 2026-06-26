-- ============================================================================
-- Webhook Hotmart 2.0 em tempo real — base (tabela de eventos + derivação + Realtime)
-- ----------------------------------------------------------------------------
-- Recebe o webhook da Hotmart numa Edge Function (`hotmart-webhook`) que grava o
-- evento CRU aqui (durável) e dispara a derivação pra `hotmart_sales`. O Postgres
-- é a fila durável: nada de Inngest/Trigger. Convive com os crons da API
-- (hotmart-sync/refresh_status/refresh_commissions), que seguem donos do líquido
-- exato e da reconciliação. Pegadinhas tratadas conforme docs/HOTMART-REFERENCIA.md
-- (§2.4 reentrega fora de ordem, refund sem origin, status faltante, epoch ms).
--
-- Decisões de design (não "corrigir" sem decisão nova):
--  - Idempotência por `dedupe_key` UNIQUE nunca-NULL (payload.id; fallback
--    transaction:event). NULL não colide em UNIQUE e duplicaria reentregas.
--  - Status: mapeado do `event` pra canônico (nunca confiar no default PT
--    'aprovada' nem gravar 'PURCHASE_*'). Anti-regressão por TRIGGER no banco
--    (protege webhook, sync E refresh_status) + newest-wins por webhook_event_at.
--  - Patch NÃO-destrutivo: refund/cancel chegam sem origin/buyer/price → só
--    sobrescreve o que o evento trouxe (COALESCE). Financeiro só quando há price.
--  - Funções SECURITY INVOKER (callers = postgres/service_role, ambos BYPASSRLS;
--    DEFINER seria superfície de escalada desnecessária) + search_path=''.
--  - Tabela de eventos SERVICE-ONLY: o payload cru tem PII (e-mail/telefone/
--    CPF/CNPJ) — nem authenticated nem anon enxergam.
--
-- APLICADA: 2026-06-26 (version 20260626203914)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Tabela append-only do payload cru (fila durável + auditoria)
-- ---------------------------------------------------------------------------
create table public.hotmart_webhook_events (
  id               uuid primary key default gen_random_uuid(),
  dedupe_key       text not null unique,        -- payload.id (fallback transaction:event) — NUNCA null
  event            text,                         -- PURCHASE_APPROVED, PURCHASE_REFUNDED, ...
  transaction_code text,
  payload          jsonb not null,              -- cru completo (reprocesso + auditoria)
  company_id       uuid references public.companies (id) on delete restrict,
  received_at      timestamptz not null default now(),
  processed_at     timestamptz,                 -- NULL = pendente (drain pega)
  process_error    text,
  attempts         int not null default 0       -- trava evento-veneno (drain filtra < 10)
);

create index hotmart_webhook_events_pending_idx
  on public.hotmart_webhook_events (received_at) where processed_at is null;

alter table public.hotmart_webhook_events enable row level security;
-- SERVICE-ONLY: sem policy pra authenticated/anon. Só a Edge (service key, bypassa
-- RLS) escreve; o drain roda como postgres. Sem isto o payload com PII vazaria.
revoke all on table public.hotmart_webhook_events from anon, authenticated;
grant select, insert, update on table public.hotmart_webhook_events to service_role;

-- ---------------------------------------------------------------------------
-- 2) Colunas novas em hotmart_sales
-- ---------------------------------------------------------------------------
alter table public.hotmart_sales add column xcod text;                    -- origin.xcode (webhook-only; a API não traz)
alter table public.hotmart_sales add column webhook_event_at timestamptz; -- creation_date do último evento de webhook aplicado

-- ---------------------------------------------------------------------------
-- 3) Realtime: a UI assina hotmart_sales (sinal-only; sem replica identity full)
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.hotmart_sales;

-- ---------------------------------------------------------------------------
-- 4) Helpers de status
-- ---------------------------------------------------------------------------
-- O `event` é a fonte canônica do status (purchase.status pode faltar no payload,
-- e os nomes crus 'PURCHASE_*' não são status — quebram qualquer ranking).
create or replace function public.hotmart_canonical_status(p_event text, p_status text)
returns text language sql immutable set search_path = '' as $$
  select case p_event
    when 'PURCHASE_APPROVED'       then 'APPROVED'
    when 'PURCHASE_COMPLETE'       then 'COMPLETE'
    when 'PURCHASE_REFUNDED'       then 'REFUNDED'
    when 'PURCHASE_CHARGEBACK'     then 'CHARGEBACK'
    when 'PURCHASE_CANCELED'       then 'CANCELED'
    when 'PURCHASE_EXPIRED'        then 'EXPIRED'
    when 'PURCHASE_PROTEST'        then 'PROTEST'
    when 'PURCHASE_DELAYED'        then 'DELAYED'
    when 'PURCHASE_BILLET_PRINTED' then 'BILLET_PRINTED'
    else coalesce(nullif(upper(p_status), ''), regexp_replace(p_event, '^PURCHASE_', ''))
  end;
$$;

-- Refund/chargeback/estorno são TERMINAIS: nenhum writer pode des-estornar.
create or replace function public.hotmart_is_terminal(p_status text)
returns boolean language sql immutable set search_path = '' as $$
  select coalesce(p_status ~* 'refund|chargeback|estorn', false);
$$;

-- ---------------------------------------------------------------------------
-- 5) Trigger anti-regressão de status (protege TODOS os writers: webhook, sync
--    diário e refresh_status). COAGE o valor em vez de RAISE — assim não aborta o
--    status_checked_at do mesmo UPDATE do refresh_status.
-- ---------------------------------------------------------------------------
create or replace function public.guard_hotmart_status()
returns trigger language plpgsql set search_path = '' as $$
begin
  if public.hotmart_is_terminal(old.status) and not public.hotmart_is_terminal(new.status) then
    new.status := old.status;   -- refund/chargeback nunca volta pra aprovado
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_hotmart_status() from public, anon, authenticated;

create trigger trg_hotmart_status_guard
  before update of status on public.hotmart_sales
  for each row execute function public.guard_hotmart_status();

-- ---------------------------------------------------------------------------
-- 6) apply_hotmart_webhook_event — deriva UM evento cru pra hotmart_sales
--    - CLAIM atômico (UPDATE ... WHERE processed_at IS NULL RETURNING): só um
--      worker (inline da Edge OU drain) processa cada evento.
--    - UPSERT em statement único: trava a linha no conflito → race-safe.
--    - status: newest-wins (por webhook_event_at) + congela terminal.
--    - financeiro: só quando ESTE evento trouxe price (refund chega sem).
--    - tracking/buyer: não-destrutivo (mantém o que o APPROVED já gravou).
--    - datas: epoch ms → date em UTC (bate com o sync); order_date primeiro.
--    - fallbacks webhook×API: currency_value/currency_code, xcode/xcod.
-- ---------------------------------------------------------------------------
create or replace function public.apply_hotmart_webhook_event(p_event_id text)
returns void language plpgsql set search_path = '' as $$
declare
  v        record;
  p        jsonb;  pur jsonb;  org jsonb;
  v_tx     text;   v_status text;  v_created timestamptz;  v_sale date;  v_money boolean;
  v_total  numeric;  v_gross numeric;  v_fee numeric;  v_net numeric;  v_cur text;
begin
  -- CLAIM atômico
  update public.hotmart_webhook_events set processed_at = now()
    where dedupe_key = p_event_id and processed_at is null
  returning * into v;
  if not found then return; end if;

  p := v.payload;  pur := p #> '{data,purchase}';  org := pur -> 'origin';
  v_tx      := nullif(pur ->> 'transaction', '');
  v_created := to_timestamp((p ->> 'creation_date')::bigint / 1000.0);
  v_status  := public.hotmart_canonical_status(v.event, pur ->> 'status');

  -- Evento sem transação (ex.: SUBSCRIPTION_CANCELLATION): não há coluna de
  -- subscriber_code em hotmart_sales — guarda o cru e registra a nota.
  if v_tx is null then
    update public.hotmart_webhook_events
      set process_error = 'sem transaction_code (assinatura?) — não aplicado em hotmart_sales'
      where dedupe_key = p_event_id;
    return;
  end if;

  v_money := (pur #> '{price,value}') is not null;
  v_total := nullif(pur #>> '{price,value}', '')::numeric;
  v_gross := coalesce(nullif(pur #>> '{hotmart_fee,base}', '')::numeric, v_total, 0);
  v_fee   := coalesce(nullif(pur #>> '{hotmart_fee,total}', '')::numeric, 0);
  v_net   := v_gross - v_fee;                                  -- aproximado; refresh_commissions põe o exato
  v_cur   := coalesce(nullif(pur #>> '{price,currency_value}', ''),   -- webhook
                      nullif(pur #>> '{price,currency_code}', ''), 'BRL'); -- API
  v_sale  := coalesce(
    (to_timestamp(nullif(pur #>> '{order_date}', '')::bigint / 1000.0)    at time zone 'UTC')::date,
    (to_timestamp(nullif(pur #>> '{approved_date}', '')::bigint / 1000.0) at time zone 'UTC')::date,
    (v_created at time zone 'UTC')::date);

  insert into public.hotmart_sales as h (
    company_id, transaction_code, product, sale_date, currency,
    total_amount, gross_amount, hotmart_fee, net_amount,
    fee_percentage, installments, payment_method, status, buyer,
    sck, src, external_code, xcod, webhook_event_at
  ) values (
    v.company_id, v_tx, coalesce(nullif(p #>> '{data,product,name}', ''), 'Produto'),
    v_sale, v_cur, coalesce(v_total, 0), v_gross, v_fee, v_net,
    nullif(pur #>> '{hotmart_fee,percentage}', '')::numeric,
    nullif(pur #>> '{payment,installments_number}', '')::int,
    nullif(pur #>> '{payment,type}', ''), v_status, nullif(p #>> '{data,buyer,name}', ''),
    nullif(trim(org ->> 'sck'), ''), nullif(trim(org ->> 'src'), ''),
    nullif(trim(org ->> 'external_code'), ''),
    coalesce(nullif(trim(org ->> 'xcode'), ''), nullif(trim(org ->> 'xcod'), '')),
    v_created
  )
  on conflict (transaction_code) do update set
    status = case
      when public.hotmart_is_terminal(h.status) then h.status                 -- congela terminal
      when excluded.webhook_event_at >= coalesce(h.webhook_event_at, '-infinity'::timestamptz)
        then excluded.status
      else h.status end,                                                       -- newest-wins
    webhook_event_at = greatest(coalesce(h.webhook_event_at, '-infinity'::timestamptz), excluded.webhook_event_at),
    total_amount = case when v_money then excluded.total_amount else h.total_amount end,
    gross_amount = case when v_money then excluded.gross_amount else h.gross_amount end,
    hotmart_fee  = case when v_money then excluded.hotmart_fee  else h.hotmart_fee  end,
    net_amount   = case when v_money then excluded.net_amount   else h.net_amount   end,
    currency     = case when v_money then excluded.currency     else h.currency     end,
    fee_percentage = coalesce(excluded.fee_percentage, h.fee_percentage),
    installments   = coalesce(excluded.installments,   h.installments),
    payment_method = coalesce(excluded.payment_method, h.payment_method),
    buyer          = coalesce(excluded.buyer, h.buyer),
    sck           = coalesce(h.sck, excluded.sck),               -- não-destrutivo
    src           = coalesce(h.src, excluded.src),
    external_code = coalesce(h.external_code, excluded.external_code),
    xcod          = coalesce(h.xcod, excluded.xcod);
    -- NÃO toca: sale_date, affiliate*, coproduction*, coproducer, status_checked_at,
    -- commission_checked_at (donos: crons da API refresh_status/refresh_commissions).

exception when others then
  update public.hotmart_webhook_events
    set process_error = left(sqlerrm, 500), attempts = attempts + 1
    where dedupe_key = p_event_id;   -- rollback do claim → processed_at volta a NULL → drain retenta
end;
$$;

-- ---------------------------------------------------------------------------
-- 7) drain_hotmart_webhook_events — rede: reprocessa pendentes (cron de 1 min).
--    FOR UPDATE SKIP LOCKED evita corrida com o apply inline da Edge.
-- ---------------------------------------------------------------------------
create or replace function public.drain_hotmart_webhook_events(p_limit int default 200)
returns int language plpgsql set search_path = '' as $$
declare r record; n int := 0;
begin
  for r in
    select dedupe_key from public.hotmart_webhook_events
     where processed_at is null and attempts < 10
     order by received_at
     limit p_limit
     for update skip locked
  loop
    perform public.apply_hotmart_webhook_event(r.dedupe_key);
    n := n + 1;
  end loop;
  return n;
end;
$$;

-- ---------------------------------------------------------------------------
-- 8) Grants (default privileges de funções foram revogados na Fase 1a).
--    A Edge chama apply via RPC com a service key; o cron roda como postgres
--    (dono → execute implícito). authenticated: NADA (a UI nunca chama).
-- ---------------------------------------------------------------------------
grant execute on function public.apply_hotmart_webhook_event(text) to service_role;
grant execute on function public.drain_hotmart_webhook_events(int) to service_role;
