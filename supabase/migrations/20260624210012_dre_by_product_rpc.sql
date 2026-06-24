-- ============================================================================
-- dre_by_product — DRE gerencial por produto (margem de contribuição por produto)
-- ============================================================================
-- APLICADA em 2026-06-24 — version 20260624210012. Verificado (RB7 DIGITAL 2025):
-- Apruma R$1,79M, Cursos R$356k, (A classificar) R$319k, Palestras R$77k. Custos
-- variáveis = 0 (Hotmart /sales/history não traz comissões — limitação herdada).
--
-- Passo 2/2 da "DRE por produto". Devolve (dre_product_id, bloco, valor):
--   ACIMA DA MARGEM (rateado por produto):
--     - Hotmart por SKU mapeado (hotmart_product_map): gross→receita_bruta,
--       hotmart_fee→deducao, afiliados+coprod→custo_variavel. SKU sem mapa
--       (dre_product_id NULL) = "Não Rateado".
--     - entries de contas rateáveis (nature revenue/deduction/variable_cost),
--       agrupados por dre_product_id (NULL = Não Rateado). Exclui o lançamento
--       de pagamento de fatura (invoice_account_id) p/ não dobrar.
--   ESTRUTURA (empresa, NÃO rateada → dre_product_id NULL):
--     - entries fixed_cost/financial/depreciation/tax por natureza.
-- O frontend pivota (produtos nas colunas) e calcula RL, MC, EBITDA, LAIR, Lucro.
-- Classificação é pela NATUREZA da conta (sem filtro de type) — autoridade é o
-- plano de contas. Hardening = espelha hotmart_totals.
-- ============================================================================

create or replace function public.dre_by_product(
  p_company    uuid default null,
  p_year       int  default null,
  p_month_from int  default 1,
  p_month_to   int  default 12,
  p_currency   text default 'BRL'
) returns table (dre_product_id uuid, bloco text, valor numeric)
language sql stable security invoker set search_path = '' as $$
  -- Hotmart por produto (acima da margem)
  select hp.dre_product_id, v.bloco, v.valor
  from (
    select m.dre_product_id,
           coalesce(sum(h.gross_amount), 0)                                  as rb,
           coalesce(sum(h.hotmart_fee), 0)                                   as ded,
           coalesce(sum(h.affiliate_commission + h.coproduction_commission), 0) as cv
    from public.hotmart_sales h
    left join public.hotmart_product_map m on m.product = btrim(h.product)
    where h.currency = p_currency
      and h.status ~* 'aprovad|complet|conclu|approved'
      and (p_company is null or h.company_id = p_company)
      and (p_year is null or extract(year from h.sale_date)::int = p_year)
      and extract(month from h.sale_date)::int between p_month_from and p_month_to
    group by m.dre_product_id
  ) hp
  cross join lateral (values
    ('receita_bruta', hp.rb), ('deducao', hp.ded), ('custo_variavel', hp.cv)
  ) as v(bloco, valor)

  union all

  -- entries por produto (acima da margem)
  select e.dre_product_id,
         case coa.nature when 'revenue'   then 'receita_bruta'
                         when 'deduction' then 'deducao'
                         else                  'custo_variavel' end,
         coalesce(sum(e.amount), 0)
  from public.entries e
  join public.chart_of_accounts coa on coa.id = e.chart_of_account_id
  where e.status not in ('cancelled', 'refunded')
    and e.invoice_account_id is null
    and coa.nature in ('revenue', 'deduction', 'variable_cost')
    and (p_company is null or e.company_id = p_company)
    and (p_year is null or extract(year from coalesce(e.competency_date, e.issue_date))::int = p_year)
    and extract(month from coalesce(e.competency_date, e.issue_date))::int between p_month_from and p_month_to
  group by e.dre_product_id, coa.nature

  union all

  -- entries estrutura (abaixo da margem: empresa, não rateada)
  select null::uuid,
         case coa.nature when 'fixed_cost'   then 'despesa_fixa'
                         when 'financial'    then 'financeiro'
                         when 'depreciation' then 'depreciacao'
                         else                     'imposto' end,
         coalesce(sum(e.amount), 0)
  from public.entries e
  join public.chart_of_accounts coa on coa.id = e.chart_of_account_id
  where e.status not in ('cancelled', 'refunded')
    and e.invoice_account_id is null
    and coa.nature in ('fixed_cost', 'financial', 'depreciation', 'tax')
    and (p_company is null or e.company_id = p_company)
    and (p_year is null or extract(year from coalesce(e.competency_date, e.issue_date))::int = p_year)
    and extract(month from coalesce(e.competency_date, e.issue_date))::int between p_month_from and p_month_to
  group by coa.nature;
$$;

revoke execute on function public.dre_by_product(uuid, int, int, int, text) from public, anon;
grant  execute on function public.dre_by_product(uuid, int, int, int, text) to authenticated;
