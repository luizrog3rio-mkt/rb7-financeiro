-- ============================================================================
-- Origem v2 — modelo de 2 níveis (Grupo › Canal) + override por venda
-- ----------------------------------------------------------------------------
-- Centraliza TODO o mapeamento de origem num modelo unificado (channel grouping):
--   • GRUPO de origem (macro): organico / trafego / comercial / afiliado.
--   • CANAL de origem (nomeado): "Meta Ads", "WhatsApp", "Raphaella" (vendedor)...
--     Cada canal pertence a 1 grupo e pode ter seller_id (quando é vendedor).
-- Substitui os 3 de-paras de hoje (hotmart_origin_map / hotmart_sck_map /
-- hotmart_affiliate_map) por UM só (origin_tracking_map: valor de tracking → canal).
--
-- Precedência (resolvida na view, mais forte → mais fraco):
--   override(venda) > vendedor(sck cru) > afiliado > canal(src) > canal(sck) > a_classificar
--   - sck/afiliado por VALOR CRU (matching exato): canal_base("raphaella_silva") e
--     canal_base("raphaella_pinheiro") colidem em "raphaella" — não dá p/ vendedor.
--   - canal(src/sck) por canal_base (agrupa: organico_*→organico, HOTMART_*→hotmart).
--   ⚠ Muda ~177 vendas que tinham src mapeado E eram de vendedor/afiliado: passam
--     de organico/trafego p/ COMERCIAL (alinhado à regra "vendedor/afiliado = comercial").
--
-- Nada é gravado em hotmart_sales — origem 100% derivada ao vivo pela view v3.
-- Os de-paras antigos e suas RPCs continuam VIVOS (a Fase 2 remove, após migrar as telas).
--
-- APLICADA: 2026-06-29 (version 20260629133817)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Tabelas
-- ---------------------------------------------------------------------------
create table public.origin_channels (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null unique,
  grupo      text not null check (grupo in ('organico','trafego','comercial','afiliado')),
  seller_id  uuid references public.sellers(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.origin_tracking_map (
  dimensao   text not null check (dimensao in ('canal','sck','afiliado')),
  valor      text not null,
  channel_id uuid not null references public.origin_channels(id) on delete cascade,
  primary key (dimensao, valor)
);

create table public.origin_sale_override (
  transaction_code text primary key,
  channel_id       uuid not null references public.origin_channels(id) on delete cascade,
  updated_at       timestamptz not null default now()
);

-- RLS team-model (using/with check true p/ authenticated; espelha hotmart_origin_map)
alter table public.origin_channels      enable row level security;
alter table public.origin_tracking_map  enable row level security;
alter table public.origin_sale_override enable row level security;
create policy authenticated_all on public.origin_channels      for all to authenticated using (true) with check (true);
create policy authenticated_all on public.origin_tracking_map  for all to authenticated using (true) with check (true);
create policy authenticated_all on public.origin_sale_override for all to authenticated using (true) with check (true);
revoke truncate, references, trigger, maintain on table public.origin_channels      from authenticated;
revoke truncate, references, trigger, maintain on table public.origin_tracking_map  from authenticated;
revoke truncate, references, trigger, maintain on table public.origin_sale_override from authenticated;
revoke all on table public.origin_channels      from anon;
revoke all on table public.origin_tracking_map  from anon;
revoke all on table public.origin_sale_override from anon;

-- ---------------------------------------------------------------------------
-- 2) Migração de dados (preserva 100% do que já foi classificado)
-- ---------------------------------------------------------------------------
-- 2a) Um canal Comercial por vendedor que tem sck ou afiliado mapeado
insert into public.origin_channels (nome, grupo, seller_id)
select s.name, 'comercial', s.id
from public.sellers s
where exists (select 1 from public.hotmart_sck_map m       where m.seller_id = s.id)
   or exists (select 1 from public.hotmart_affiliate_map a where a.seller_id = s.id);

-- 2b) sck cru → canal do vendedor (dimensão 'sck', matching exato)
insert into public.origin_tracking_map (dimensao, valor, channel_id)
select 'sck', m.sck, oc.id
from public.hotmart_sck_map m
join public.origin_channels oc on oc.seller_id = m.seller_id
where m.seller_id is not null;

-- 2c) afiliado → canal do vendedor (dimensão 'afiliado'; internos = comercial)
insert into public.origin_tracking_map (dimensao, valor, channel_id)
select 'afiliado', a.affiliate, oc.id
from public.hotmart_affiliate_map a
join public.origin_channels oc on oc.seller_id = a.seller_id
where a.seller_id is not null;

-- 2d) canais técnicos do origin_map (1:1, dimensão 'canal'). Nomes não colidem
--     com os de vendedor (técnicos são lowercase-hifenizados). O Luiz consolida
--     os redundantes (ex.: técnico "raphaella" vs vendedor "Raphaella Silva") na tela.
insert into public.origin_channels (nome, grupo)
select om.canal, om.origem from public.hotmart_origin_map om;

insert into public.origin_tracking_map (dimensao, valor, channel_id)
select 'canal', om.canal, oc.id
from public.hotmart_origin_map om
join public.origin_channels oc on oc.nome = om.canal and oc.grupo = om.origem;

-- ---------------------------------------------------------------------------
-- 3) View v3 — resolve channel por precedência via LEFT JOINs alinhados
-- ---------------------------------------------------------------------------
create or replace view public.hotmart_sales_origin with (security_invoker = true) as
  select h.*,
    coalesce(ovc.grupo, vc.grupo, ac.grupo, sc.grupo, kc.grupo, 'a_classificar') as origem,
    coalesce(ov.channel_id, vend.channel_id, afil.channel_id, csrc.channel_id, csck.channel_id) as channel_id,
    coalesce(ovc.nome,  vc.nome,  ac.nome,  sc.nome,  kc.nome) as canal
  from public.hotmart_sales h
  left join public.origin_sale_override ov  on ov.transaction_code = h.transaction_code
  left join public.origin_channels      ovc on ovc.id = ov.channel_id
  left join public.origin_tracking_map  vend on vend.dimensao = 'sck'      and vend.valor = btrim(h.sck)
  left join public.origin_channels      vc   on vc.id = vend.channel_id
  left join public.origin_tracking_map  afil on afil.dimensao = 'afiliado' and afil.valor = btrim(h.affiliate)
  left join public.origin_channels      ac   on ac.id = afil.channel_id
  left join public.origin_tracking_map  csrc on csrc.dimensao = 'canal'    and csrc.valor = public.hotmart_canal_base(h.src)
  left join public.origin_channels      sc   on sc.id = csrc.channel_id
  left join public.origin_tracking_map  csck on csck.dimensao = 'canal'    and csck.valor = public.hotmart_canal_base(h.sck)
  left join public.origin_channels      kc   on kc.id = csck.channel_id;

-- ---------------------------------------------------------------------------
-- 4) RPCs novas (security invoker; grant explícito p/ authenticated)
-- ---------------------------------------------------------------------------
-- 4a) Total por grupo (sucessora de hotmart_by_origin; soma = hotmart_totals)
create function public.hotmart_by_group(
  p_company uuid default null, p_start date default null,
  p_end date default null, p_currency text default 'BRL'
)
returns table (grupo text, vendas bigint, bruto numeric, total numeric, liquido numeric)
language sql stable security invoker set search_path = '' as $$
  select h.origem, count(*),
         coalesce(sum(h.gross_amount),0), coalesce(sum(h.total_amount),0), coalesce(sum(h.net_amount),0)
  from public.hotmart_sales_origin h
  where h.currency = p_currency
    and h.status ~* 'aprovad|complet|conclu|approved'
    and (p_company is null or h.company_id = p_company)
    and (p_start is null or h.sale_date >= p_start)
    and (p_end   is null or h.sale_date <= p_end)
  group by h.origem
  order by 5 desc;
$$;

-- 4b) Total por canal (com grupo e vendedor)
create function public.hotmart_by_channel(
  p_company uuid default null, p_start date default null,
  p_end date default null, p_currency text default 'BRL'
)
returns table (canal text, grupo text, vendas bigint, bruto numeric, total numeric, liquido numeric)
language sql stable security invoker set search_path = '' as $$
  select coalesce(h.canal,'(a classificar)'), h.origem, count(*),
         coalesce(sum(h.gross_amount),0), coalesce(sum(h.total_amount),0), coalesce(sum(h.net_amount),0)
  from public.hotmart_sales_origin h
  where h.currency = p_currency
    and h.status ~* 'aprovad|complet|conclu|approved'
    and (p_company is null or h.company_id = p_company)
    and (p_start is null or h.sale_date >= p_start)
    and (p_end   is null or h.sale_date <= p_end)
  group by h.canal, h.origem
  order by 5 desc;
$$;

-- 4c) Canais cadastrados + nº de vendas (p/ a tela)
create function public.origin_channels_list(p_currency text default 'BRL')
returns table (id uuid, nome text, grupo text, seller_id uuid, seller_nome text, vendas bigint, liquido numeric)
language sql stable security invoker set search_path = '' as $$
  select c.id, c.nome, c.grupo, c.seller_id, s.name,
         coalesce(v.vendas,0), coalesce(v.liquido,0)
  from public.origin_channels c
  left join public.sellers s on s.id = c.seller_id
  left join (
    select h.channel_id, count(*) as vendas, coalesce(sum(h.net_amount),0) as liquido
    from public.hotmart_sales_origin h
    where h.currency = p_currency and h.status ~* 'aprovad|complet|conclu|approved'
    group by h.channel_id
  ) v on v.channel_id = c.id
  order by c.grupo, c.nome;
$$;

-- 4d) Valores de tracking ainda SEM canal (sucessora de hotmart_channels):
--     dimensão 'canal' (canal_base de src, ou de sck de não-vendedor) + 'afiliado'.
create function public.origin_tracking_unmapped(p_currency text default 'BRL')
returns table (dimensao text, valor text, vendas bigint, bruto numeric, liquido numeric, sugestao text, is_ruido boolean)
language sql stable security invoker set search_path = '' as $$
  with vc as (
    select case
             when public.hotmart_canal_base(h.src) is not null then public.hotmart_canal_base(h.src)
             when not exists (select 1 from public.origin_tracking_map t where t.dimensao='sck' and t.valor = btrim(h.sck))
               then public.hotmart_canal_base(h.sck)
             else null
           end as valor,
           h.gross_amount, h.net_amount
    from public.hotmart_sales h
    where h.currency = p_currency and h.status ~* 'aprovad|complet|conclu|approved'
  )
  select 'canal'::text, vc.valor, count(*), coalesce(sum(vc.gross_amount),0), coalesce(sum(vc.net_amount),0),
         public.hotmart_origin_suggest(vc.valor),
         (vc.valor ~ '\{\{' or vc.valor ~ '^\d+$' or vc.valor ~ '^\d{10,}[._]\d+$')
  from vc
  where vc.valor is not null
    and not exists (select 1 from public.origin_tracking_map t where t.dimensao='canal' and t.valor = vc.valor)
  group by vc.valor
  union all
  select 'afiliado'::text, btrim(h.affiliate), count(*), coalesce(sum(h.gross_amount),0), coalesce(sum(h.net_amount),0),
         null::text, false
  from public.hotmart_sales h
  where h.currency = p_currency and h.status ~* 'aprovad|complet|conclu|approved'
    and h.affiliate is not null and btrim(h.affiliate) <> ''
    and not exists (select 1 from public.origin_tracking_map t where t.dimensao='afiliado' and t.valor = btrim(h.affiliate))
  group by btrim(h.affiliate)
  order by 3 desc;
$$;

revoke execute on function public.hotmart_by_group(uuid,date,date,text)      from public, anon;
revoke execute on function public.hotmart_by_channel(uuid,date,date,text)    from public, anon;
revoke execute on function public.origin_channels_list(text)                 from public, anon;
revoke execute on function public.origin_tracking_unmapped(text)             from public, anon;
grant  execute on function public.hotmart_by_group(uuid,date,date,text)      to authenticated;
grant  execute on function public.hotmart_by_channel(uuid,date,date,text)    to authenticated;
grant  execute on function public.origin_channels_list(text)                 to authenticated;
grant  execute on function public.origin_tracking_unmapped(text)             to authenticated;
