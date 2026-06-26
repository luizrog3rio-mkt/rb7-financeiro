-- ============================================================================
-- RPCs: de-para de afiliado + "Total por pessoa" (sck + afiliado)
-- ----------------------------------------------------------------------------
-- Hardening padrão (sql stable, security invoker, search_path='', revoke
-- public/anon + grant authenticated). Agregação no banco (PostgREST 1000-row).
--
-- APLICADA: 2026-06-26 (version 20260626142158)
-- ============================================================================

-- de-para: afiliados distintos com vendas/comissão/líquido + seller mapeado.
-- Molde hotmart_scks, mas sem is_ruido (o nome do afiliado é canônico).
create function public.hotmart_affiliates(p_currency text default 'BRL')
returns table (affiliate text, vendas bigint, comissao numeric, liquido numeric, seller_id uuid)
language sql stable security invoker set search_path = '' as $$
  select a.affiliate, a.vendas, a.comissao, a.liquido, m.seller_id
  from (
    select btrim(h.affiliate) as affiliate,
           count(*) as vendas,
           coalesce(sum(h.affiliate_commission), 0) as comissao,
           coalesce(sum(h.net_amount), 0) as liquido
    from public.hotmart_sales h
    where h.affiliate is not null and btrim(h.affiliate) <> ''
      and h.currency = p_currency
      and h.status ~* 'aprovad|complet|conclu|approved'
    group by btrim(h.affiliate)
  ) a
  left join public.hotmart_affiliate_map m on m.affiliate = a.affiliate
  order by a.comissao desc, a.vendas desc;
$$;
revoke execute on function public.hotmart_affiliates(text) from public, anon;
grant  execute on function public.hotmart_affiliates(text) to authenticated;

-- Total por PESSOA: vendas atribuídas por sck E por afiliado, lado a lado (cada
-- canal numa coluna → sem dupla contagem). Junta os 2 de-paras → sellers.
create function public.hotmart_by_person(
  p_company uuid default null, p_start date default null,
  p_end date default null, p_currency text default 'BRL'
)
returns table (
  vendedor text,
  vendas_sck bigint, liquido_sck numeric,
  vendas_afiliado bigint, comissao_afiliado numeric, liquido_afiliado numeric
)
language sql stable security invoker set search_path = '' as $$
  with base as (
    select h.* from public.hotmart_sales h
    where h.currency = p_currency
      and h.status ~* 'aprovad|complet|conclu|approved'
      and (p_company is null or h.company_id = p_company)
      and (p_start is null or h.sale_date >= p_start)
      and (p_end   is null or h.sale_date <= p_end)
  ),
  por_sck as (
    select sm.seller_id, count(*) as vendas, coalesce(sum(b.net_amount), 0) as liquido
    from base b
    join public.hotmart_sck_map sm on sm.sck = btrim(b.sck)
    where sm.seller_id is not null
    group by sm.seller_id
  ),
  por_afi as (
    select am.seller_id, count(*) as vendas,
           coalesce(sum(b.affiliate_commission), 0) as comissao,
           coalesce(sum(b.net_amount), 0) as liquido
    from base b
    join public.hotmart_affiliate_map am on am.affiliate = btrim(b.affiliate)
    where am.seller_id is not null
    group by am.seller_id
  )
  select s.name,
         coalesce(ps.vendas, 0), coalesce(ps.liquido, 0),
         coalesce(pa.vendas, 0), coalesce(pa.comissao, 0), coalesce(pa.liquido, 0)
  from public.sellers s
  left join por_sck ps on ps.seller_id = s.id
  left join por_afi pa on pa.seller_id = s.id
  where coalesce(ps.vendas, 0) + coalesce(pa.vendas, 0) > 0
  order by (coalesce(ps.liquido, 0) + coalesce(pa.liquido, 0)) desc;
$$;
revoke execute on function public.hotmart_by_person(uuid, date, date, text) from public, anon;
grant  execute on function public.hotmart_by_person(uuid, date, date, text) to authenticated;
