-- ============================================================================
-- hotmart_totals — agregação de vendas Hotmart pros KPIs (Fase 2 / sync API)
-- ============================================================================
-- Version placeholder — renomear pós-apply (rito do projeto).
--
-- Por quê: o PostgREST limita respostas a 1000 linhas (max-rows), então somar
-- bruto/taxas/líquido no cliente undercount com volume alto (a Hotmart traz
-- ~13k vendas/ano). Esta função soma no banco e devolve só os 5 números —
-- correto a qualquer volume.
--
-- Hardening (padrão Fase 1a): SECURITY INVOKER (respeita o RLS de equipe —
-- authenticated já pode SELECT em hotmart_sales), set search_path = '',
-- EXECUTE revogado de public/anon e concedido só a authenticated.
-- ============================================================================

create or replace function public.hotmart_totals(
  p_company uuid default null,
  p_start   date default null,
  p_end     date default null
)
returns table (qtd bigint, bruto numeric, taxas numeric, afiliados numeric, liquido numeric)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    count(*),
    coalesce(sum(gross_amount), 0),
    coalesce(sum(hotmart_fee), 0),
    coalesce(sum(affiliate_commission + coproduction_commission), 0),
    coalesce(sum(net_amount), 0)
  from public.hotmart_sales
  where status ~* 'aprovad|complet|conclu|approved'     -- mesma allowlist do app
    and (p_company is null or company_id = p_company)
    and (p_start   is null or sale_date >= p_start)
    and (p_end     is null or sale_date <= p_end);
$$;

revoke execute on function public.hotmart_totals(uuid, date, date) from public, anon;
grant  execute on function public.hotmart_totals(uuid, date, date) to authenticated;
