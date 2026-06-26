-- ============================================================================
-- RPCs de vendedores (via sck) — de-para + "Total por vendedor"
-- ----------------------------------------------------------------------------
-- Hardening espelha hotmart_produtos (de-para) e hotmart_by_affiliate (relatório):
-- language sql stable, security invoker, search_path='', revoke public/anon +
-- grant authenticated. Agregação no banco (PostgREST limita resposta a 1000 linhas).
--
-- APLICADA: 2026-06-26 (version 20260626124506)
-- ============================================================================

-- 1) de-para: lista os sck distintos das vendas aprovadas, com vendas/bruto/líquido,
--    LEFT JOIN no mapa (seller_id NULL = a mapear). is_ruido classifica visitor-id
--    (`<ts>_<id>`) e UTM (`a|b|c`) pra UI poder esconder. Ordena candidatos primeiro
--    (is_ruido asc) e por frequência — se o PostgREST truncar em 1000, o que cai é só
--    a cauda de visitor-id (nunca os vendedores, que repetem).
create function public.hotmart_scks(p_currency text default 'BRL')
returns table (sck text, vendas bigint, bruto numeric, liquido numeric, seller_id uuid, is_ruido boolean)
language sql stable security invoker set search_path = '' as $$
  select a.sck, a.vendas, a.bruto, a.liquido, m.seller_id, a.is_ruido
  from (
    select btrim(h.sck) as sck,
           count(*) as vendas,
           coalesce(sum(h.gross_amount), 0) as bruto,
           coalesce(sum(h.net_amount), 0) as liquido,
           (btrim(h.sck) ~ '^\d{10,}_\d+$' or btrim(h.sck) like '%|%') as is_ruido
    from public.hotmart_sales h
    where h.sck is not null and btrim(h.sck) <> ''
      and h.currency = p_currency
      and h.status ~* 'aprovad|complet|conclu|approved'
    group by btrim(h.sck)
  ) a
  left join public.hotmart_sck_map m on m.sck = a.sck
  order by a.is_ruido asc, a.vendas desc, a.sck;
$$;
revoke execute on function public.hotmart_scks(text) from public, anon;
grant  execute on function public.hotmart_scks(text) to authenticated;

-- 2) Total por vendedor: junta vendas → mapa → vendedor (só sck mapeado conta),
--    agrupa por vendedor (variantes de grafia que apontam pro mesmo vendedor somam).
create function public.hotmart_by_seller(
  p_company uuid default null, p_start date default null,
  p_end date default null, p_currency text default 'BRL'
)
returns table (vendedor text, qtd bigint, bruto numeric, total numeric, liquido numeric)
language sql stable security invoker set search_path = '' as $$
  select s.name,
         count(*),
         coalesce(sum(h.gross_amount), 0),
         coalesce(sum(h.total_amount), 0),
         coalesce(sum(h.net_amount), 0)
  from public.hotmart_sales h
  join public.hotmart_sck_map m on m.sck = btrim(h.sck)
  join public.sellers s on s.id = m.seller_id
  where h.currency = p_currency
    and h.status ~* 'aprovad|complet|conclu|approved'
    and (p_company is null or h.company_id = p_company)
    and (p_start is null or h.sale_date >= p_start)
    and (p_end   is null or h.sale_date <= p_end)
  group by s.name
  order by sum(h.net_amount) desc;
$$;
revoke execute on function public.hotmart_by_seller(uuid, date, date, text) from public, anon;
grant  execute on function public.hotmart_by_seller(uuid, date, date, text) to authenticated;
