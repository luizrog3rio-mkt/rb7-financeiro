-- ============================================================================
-- Origem das vendas Hotmart (Orgânico / Tráfego / Comercial) — de-para canal→origem
-- ----------------------------------------------------------------------------
-- Classifica cada venda por ORIGEM via um de-para `canal → origem`, espelhando o
-- de-para sck→vendedor da tela /vendedores. A origem é DERIVADA ao vivo (view), SEM
-- coluna em hotmart_sales, SEM trigger, SEM tocar o webhook/sync: remapear um canal
-- reclassifica as ~14,9k vendas na hora, zero backfill.
--
-- `src` exato tem 1.318 valores (inviável), mas o CANAL-BASE (1º segmento antes de
-- | _ ou espaço) reduz pra ~50 — gerenciável como os sck de vendedores. Precedência
-- da classificação: canal mapeado > vendedor (sck_map) → 'comercial' > 'a_classificar'
-- (decisão de negócio; trocar = inverter o coalesce na view). 26% das vendas não têm
-- src nem sck → ficam permanentemente em 'a_classificar' (teto estrutural, exibido).
--
-- Tudo read-only + 1 tabela de-para; nada muta hotmart_sales.
--
-- APLICADA: 2026-06-26 (version 20260627010255)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Normalização do canal-base (PURA/immutable — folding por translate, não
--    unaccent que é STABLE e impediria immutable). Não usar . ou - como delimitador
--    (quebraria luiz-otavio, l.facebook.com).
-- ---------------------------------------------------------------------------
create or replace function public.hotmart_canal_base(p_src text)
returns text language sql immutable set search_path = '' as $$
  select nullif(
    split_part(split_part(split_part(
      translate(lower(btrim(coalesce(p_src, ''))),
                'áàâãäéèêëíìîïóòôõöúùûüç', 'aaaaaeeeeiiiiooooouuuuc'),
    '|', 1), '_', 1), ' ', 1),
  '');
$$;

-- ---------------------------------------------------------------------------
-- 2) Sugestão conservadora: só quando o canal CONTÉM a palavra da origem.
--    NUNCA sugere facebook/ig/instagram (ambíguo: orgânico vs pago no mesmo canal).
-- ---------------------------------------------------------------------------
create or replace function public.hotmart_origin_suggest(p_canal text)
returns text language sql immutable set search_path = '' as $$
  select case
    when p_canal is null then null
    when p_canal ~ 'organic|^direto$|^direct$|^bio$' then 'organico'
    when p_canal ~ 'comercial|^vendas?$'             then 'comercial'
    when p_canal ~ 'trafego|traffic|^ads?$|paid'     then 'trafego'
    else null
  end;
$$;

-- ---------------------------------------------------------------------------
-- 3) De-para canal → origem (espelha hotmart_sck_map; global, sem company_id)
-- ---------------------------------------------------------------------------
create table public.hotmart_origin_map (
  canal      text primary key,
  origem     text not null check (origem in ('organico', 'trafego', 'comercial')),
  updated_at timestamptz not null default now()
);
alter table public.hotmart_origin_map enable row level security;
create policy "authenticated all" on public.hotmart_origin_map
  for all to authenticated using (true) with check (true);
revoke truncate, references, trigger, maintain on table public.hotmart_origin_map from authenticated;
revoke all on table public.hotmart_origin_map from anon;

-- ---------------------------------------------------------------------------
-- 4) View canônica — fonte ÚNICA da classificação (a RPC de total E a coluna da
--    tela Hotmart leem daqui, nunca divergem). security_invoker herda o RLS de
--    hotmart_sales. Precedência: canal > vendedor > a_classificar.
-- ---------------------------------------------------------------------------
create view public.hotmart_sales_origin with (security_invoker = true) as
  select h.*,
    coalesce(
      om.origem,
      case when sm.seller_id is not null then 'comercial' end,
      'a_classificar'
    ) as origem
  from public.hotmart_sales h
  left join public.hotmart_origin_map om on om.canal = public.hotmart_canal_base(h.src)
  left join public.hotmart_sck_map  sm on sm.sck = btrim(h.sck) and sm.seller_id is not null;

-- ---------------------------------------------------------------------------
-- 5) RPC de-para: lista os canais-base a mapear (espelha hotmart_scks). Vazios
--    (src nulo) somem (canal IS NULL); não-mapeados e não-ruído sobem ao topo.
-- ---------------------------------------------------------------------------
create function public.hotmart_channels(p_currency text default 'BRL')
returns table (canal text, vendas bigint, bruto numeric, liquido numeric,
               origem text, sugestao text, is_ruido boolean)
language sql stable security invoker set search_path = '' as $$
  select a.canal, a.vendas, a.bruto, a.liquido,
         m.origem,
         public.hotmart_origin_suggest(a.canal),
         (a.canal ~ '\{\{' or a.canal ~ '^\d+$')
  from (
    select public.hotmart_canal_base(h.src) as canal,
           count(*) as vendas,
           coalesce(sum(h.gross_amount), 0) as bruto,
           coalesce(sum(h.net_amount), 0)  as liquido
    from public.hotmart_sales h
    where h.currency = p_currency
      and h.status ~* 'aprovad|complet|conclu|approved'
      and public.hotmart_canal_base(h.src) is not null
    group by public.hotmart_canal_base(h.src)
  ) a
  left join public.hotmart_origin_map m on m.canal = a.canal
  order by (m.origem is not null), 7, 2 desc, 1;
$$;

-- ---------------------------------------------------------------------------
-- 6) RPC total por origem (lê a view → partição garantida: soma bate com
--    hotmart_totals). Filtros idênticos a hotmart_totals/hotmart_by_seller.
-- ---------------------------------------------------------------------------
create function public.hotmart_by_origin(
  p_company uuid default null, p_start date default null,
  p_end date default null, p_currency text default 'BRL'
)
returns table (origem text, vendas bigint, bruto numeric, total numeric, liquido numeric)
language sql stable security invoker set search_path = '' as $$
  select h.origem,
         count(*),
         coalesce(sum(h.gross_amount), 0),
         coalesce(sum(h.total_amount), 0),
         coalesce(sum(h.net_amount), 0)
  from public.hotmart_sales_origin h
  where h.currency = p_currency
    and h.status ~* 'aprovad|complet|conclu|approved'
    and (p_company is null or h.company_id = p_company)
    and (p_start is null or h.sale_date >= p_start)
    and (p_end   is null or h.sale_date <= p_end)
  group by h.origem
  order by 5 desc;
$$;

-- ---------------------------------------------------------------------------
-- 7) Grants (default privileges de funções revogados na Fase 1a). canal_base e
--    origin_suggest são internas (usadas pela view/RPCs) — sem grant a authenticated.
-- ---------------------------------------------------------------------------
revoke execute on function public.hotmart_channels(text) from public, anon;
grant  execute on function public.hotmart_channels(text) to authenticated;
revoke execute on function public.hotmart_by_origin(uuid, date, date, text) from public, anon;
grant  execute on function public.hotmart_by_origin(uuid, date, date, text) to authenticated;
