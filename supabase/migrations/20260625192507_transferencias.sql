-- ============================================================================
-- Migration: transferência entre contas (coluna transfer_id em entries)
-- APLICADA em 2026-06-25 via MCP apply_migration — version 20260625192507
-- (renomeada do placeholder 20260625000002). Pós-apply: coluna + índice OK.
-- ----------------------------------------------------------------------------
-- Uma transferência = DOIS lançamentos pagos amarrados por transfer_id: saída
-- (payable) na conta de origem + entrada (receivable) na de destino, ambos SEM
-- chart_of_account (neutros na DRE). Cada perna fica na empresa da sua própria
-- conta (suporta transferência entre empresas). Os saldos (account_balances/
-- account_ledger) já incluem essas pernas — é o efeito desejado. Aditiva.
--
-- Também exclui as pernas de transferência da RPC dre_cash_reconciliation (que
-- soma por type SEM filtro de conta DRE) pra não inflar os números BRUTOS da
-- Conciliação DRE — o líquido já se anularia, mas o bruto inflava.
-- ============================================================================

alter table public.entries add column if not exists transfer_id uuid;

create index if not exists idx_entries_transfer
  on public.entries (transfer_id) where transfer_id is not null;

-- dre_cash_reconciliation: idêntica à viva + "and e.transfer_id is null" nos 2 CTEs.
create or replace function public.dre_cash_reconciliation(p_company_id uuid, p_year integer)
returns table(month_num integer, month_label text, dre_receivable numeric, dre_payable numeric, cash_receivable numeric, cash_payable numeric, dre_net numeric, cash_net numeric, difference numeric)
language plpgsql security definer set search_path to '' as $function$
begin
  return query
  with months as (
    select generate_series(1, 12) as mn
  ),
  dre_agg as (
    select
      extract(month from coalesce(e.competency_date, e.issue_date))::int as mn,
      sum(case when e.type = 'receivable' then e.amount else 0 end)       as dre_rec,
      sum(case when e.type = 'payable'    then e.amount else 0 end)       as dre_pay
    from public.entries e
    where e.company_id = p_company_id
      and e.status not in ('cancelled', 'refunded')
      and e.transfer_id is null
      and coalesce(e.competency_date, e.issue_date) is not null
      and extract(year from coalesce(e.competency_date, e.issue_date))::int = p_year
    group by 1
  ),
  cash_agg as (
    select
      extract(month from e.payment_date)::int                             as mn,
      sum(case when e.type = 'receivable' then e.amount else 0 end)       as cash_rec,
      sum(case when e.type = 'payable'    then e.amount else 0 end)       as cash_pay
    from public.entries e
    where e.company_id = p_company_id
      and e.status = 'paid'
      and e.transfer_id is null
      and e.payment_date is not null
      and extract(year from e.payment_date)::int = p_year
    group by 1
  )
  select
    m.mn::int,
    to_char(make_date(p_year, m.mn, 1), 'Mon/YYYY'),
    coalesce(d.dre_rec,  0::numeric),
    coalesce(d.dre_pay,  0::numeric),
    coalesce(c.cash_rec, 0::numeric),
    coalesce(c.cash_pay, 0::numeric),
    coalesce(d.dre_rec,  0::numeric) - coalesce(d.dre_pay,  0::numeric),
    coalesce(c.cash_rec, 0::numeric) - coalesce(c.cash_pay, 0::numeric),
    (coalesce(d.dre_rec,  0::numeric) - coalesce(d.dre_pay,  0::numeric))
    - (coalesce(c.cash_rec, 0::numeric) - coalesce(c.cash_pay, 0::numeric))
  from months m
  left join dre_agg  d on d.mn = m.mn
  left join cash_agg c on c.mn = m.mn
  order by m.mn;
end; $function$;

grant execute on function public.dre_cash_reconciliation(uuid, int) to authenticated;
