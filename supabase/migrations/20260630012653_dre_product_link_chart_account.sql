-- APLICADA: 20260630012653
-- Vínculo conta do plano → produto DRE. Antes a DRE por produto só atribuía produto via:
-- (1) mapa SKU→produto do Hotmart e (2) seletor manual dre_product_id em CADA lançamento
-- (quase nunca preenchido: 1 de 28). O flag chart_of_accounts.rateio_por_produto era MORTO
-- (nenhuma função/UI o lia). Agora a conta aponta pro produto (dre_product_id) e a receita
-- lançada nela cai no produto automaticamente. Aprovada pelo Luiz em 2026-06-30.
--
-- Não-destrutivo: a coluna nasce NULL em todas as contas → comportamento idêntico ao atual
-- até o Luiz ligar conta→produto no Plano de Contas. O seletor por lançamento vira override
-- (coalesce(e.dre_product_id, coa.dre_product_id)).
alter table public.chart_of_accounts
  add column dre_product_id uuid references public.dre_products(id) on delete set null;

create or replace function public.dre_by_product(
  p_company uuid default null, p_year integer default null,
  p_month_from integer default 1, p_month_to integer default 12, p_currency text default 'BRL')
returns table(dre_product_id uuid, bloco text, valor numeric)
language sql stable set search_path to '' as $function$
  select hp.dre_product_id, v.bloco, v.valor
  from (
    select m.dre_product_id,
           coalesce(sum(h.gross_amount), 0) as rb,
           coalesce(sum(h.hotmart_fee), 0)  as ded,
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

  select coalesce(e.dre_product_id, coa.dre_product_id),
         case coa.nature when 'revenue' then 'receita_bruta'
                         when 'deduction' then 'deducao'
                         else 'custo_variavel' end,
         coalesce(sum(e.amount), 0)
  from public.entries e
  join public.chart_of_accounts coa on coa.id = e.chart_of_account_id
  where e.status not in ('cancelled', 'refunded')
    and e.invoice_account_id is null
    and coa.nature in ('revenue', 'deduction', 'variable_cost')
    and (p_company is null or e.company_id = p_company)
    and (p_year is null or extract(year from coalesce(e.competency_date, e.issue_date))::int = p_year)
    and extract(month from coalesce(e.competency_date, e.issue_date))::int between p_month_from and p_month_to
  group by coalesce(e.dre_product_id, coa.dre_product_id), coa.nature

  union all

  select null::uuid,
         case coa.nature when 'fixed_cost' then 'despesa_fixa'
                         when 'financial' then 'financeiro'
                         when 'depreciation' then 'depreciacao'
                         else 'imposto' end,
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
$function$;
