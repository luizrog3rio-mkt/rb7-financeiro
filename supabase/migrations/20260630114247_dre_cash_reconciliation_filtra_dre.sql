-- APLICADA: 20260630114247
-- Auditoria financeira: a dre_cash_reconciliation (tela DRE x Caixa) somava os dois lados
-- so por type, sem filtrar por natureza/conta nem excluir fatura agregada -> incluia
-- lancamentos que nao sao receita/despesa de verdade (e os sem conta), inflando a despesa
-- (R$531k vs R$301k real em RB7 2026). Fix: os dois lados (competencia e caixa) passam a usar
-- os MESMOS lancamentos da DRE real (join no plano + alinhamento natureza<->tipo +
-- invoice_account_id IS NULL). A "Diferenca" vira puro descasamento de tempo. Aprovado pelo
-- Luiz em 2026-06-30. Verificado: despesa DRE da conciliacao = R$301.201 (bate com a real).
-- (Hotmart nao entra aqui de proposito: e entries x entries.)
create or replace function public.dre_cash_reconciliation(p_company_id uuid, p_year integer)
returns table(month_num integer, month_label text, dre_receivable numeric, dre_payable numeric, cash_receivable numeric, cash_payable numeric, dre_net numeric, cash_net numeric, difference numeric)
language plpgsql security definer set search_path to '' as $function$
begin
  return query
  with months as (select generate_series(1, 12) as mn),
  dre_agg as (
    select extract(month from coalesce(e.competency_date, e.issue_date))::int as mn,
      sum(case when e.type='receivable' then e.amount else 0 end) as dre_rec,
      sum(case when e.type='payable'    then e.amount else 0 end) as dre_pay
    from public.entries e
    join public.chart_of_accounts c on c.id = e.chart_of_account_id
    where e.company_id = p_company_id
      and e.status not in ('cancelled','refunded')
      and e.transfer_id is null
      and e.invoice_account_id is null
      and ((c.nature in ('revenue','deduction') and e.type='receivable')
        or (c.nature in ('variable_cost','fixed_cost','financial','depreciation','tax') and e.type='payable'))
      and coalesce(e.competency_date, e.issue_date) is not null
      and extract(year from coalesce(e.competency_date, e.issue_date))::int = p_year
    group by 1
  ),
  cash_agg as (
    select extract(month from e.payment_date)::int as mn,
      sum(case when e.type='receivable' then e.amount else 0 end) as cash_rec,
      sum(case when e.type='payable'    then e.amount else 0 end) as cash_pay
    from public.entries e
    join public.chart_of_accounts c on c.id = e.chart_of_account_id
    where e.company_id = p_company_id
      and e.status = 'paid'
      and e.transfer_id is null
      and e.invoice_account_id is null
      and ((c.nature in ('revenue','deduction') and e.type='receivable')
        or (c.nature in ('variable_cost','fixed_cost','financial','depreciation','tax') and e.type='payable'))
      and e.payment_date is not null
      and extract(year from e.payment_date)::int = p_year
    group by 1
  )
  select m.mn::int, to_char(make_date(p_year, m.mn, 1), 'Mon/YYYY'),
    coalesce(d.dre_rec,0::numeric), coalesce(d.dre_pay,0::numeric),
    coalesce(c.cash_rec,0::numeric), coalesce(c.cash_pay,0::numeric),
    coalesce(d.dre_rec,0::numeric) - coalesce(d.dre_pay,0::numeric),
    coalesce(c.cash_rec,0::numeric) - coalesce(c.cash_pay,0::numeric),
    (coalesce(d.dre_rec,0::numeric) - coalesce(d.dre_pay,0::numeric)) - (coalesce(c.cash_rec,0::numeric) - coalesce(c.cash_pay,0::numeric))
  from months m
  left join dre_agg d on d.mn = m.mn
  left join cash_agg c on c.mn = m.mn
  order by m.mn;
end; $function$;
