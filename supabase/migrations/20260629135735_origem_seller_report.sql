-- ============================================================================
-- Relatório de vendas por vendedor — lendo do modelo de canais (Fase 2)
-- ----------------------------------------------------------------------------
-- Sucessora de hotmart_by_seller / hotmart_by_person: no modelo v2, uma venda é
-- atribuída a um vendedor quando seu channel_id (derivado pela view) aponta pra um
-- origin_channel com seller_id. Cobre os 3 caminhos de uma vez (sck, afiliado e
-- override manual), sem dupla contagem — cada venda tem exatamente um canal.
-- comissao_afiliado = soma de affiliate_commission das vendas do vendedor.
--
-- Não-destrutiva (só CREATE FUNCTION). Os de-paras antigos seguem vivos até a
-- migration de limpeza da Fase 2 (após o teste do Luiz).
--
-- APLICADA: 2026-06-29 (version 20260629135735)
-- ============================================================================

create function public.hotmart_seller_report(
  p_company uuid default null, p_start date default null,
  p_end date default null, p_currency text default 'BRL'
)
returns table (vendedor text, vendas bigint, bruto numeric, total numeric, liquido numeric, comissao_afiliado numeric)
language sql stable security invoker set search_path = '' as $$
  select s.name, count(*),
         coalesce(sum(h.gross_amount), 0), coalesce(sum(h.total_amount), 0),
         coalesce(sum(h.net_amount), 0), coalesce(sum(h.affiliate_commission), 0)
  from public.hotmart_sales_origin h
  join public.origin_channels c on c.id = h.channel_id and c.seller_id is not null
  join public.sellers s on s.id = c.seller_id
  where h.currency = p_currency
    and h.status ~* 'aprovad|complet|conclu|approved'
    and (p_company is null or h.company_id = p_company)
    and (p_start is null or h.sale_date >= p_start)
    and (p_end   is null or h.sale_date <= p_end)
  group by s.name
  order by sum(h.net_amount) desc;
$$;
revoke execute on function public.hotmart_seller_report(uuid, date, date, text) from public, anon;
grant  execute on function public.hotmart_seller_report(uuid, date, date, text) to authenticated;
