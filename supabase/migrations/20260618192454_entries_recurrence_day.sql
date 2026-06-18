-- APLICADA 2026-06-18 (version 20260618192454)
-- Âncora do dia de vencimento das séries recorrentes. Guarda o dia "alvo"
-- (1-31) para a recorrência manter SEMPRE o dia original: faz clamp só no mês
-- que não tem o dia (ex.: 31 → 28/fev) e volta ao dia cheio no mês seguinte
-- que o comporta (→ 31/mar). Sem isso, a série "desce" e fica no dia menor.
-- Coluna nullable: só lançamentos recorrentes a preenchem; null nos demais.

alter table public.entries
  add column if not exists recurrence_day smallint
  check (recurrence_day is null or recurrence_day between 1 and 31);

-- backfill: lançamentos recorrentes já existentes herdam o dia do vencimento atual
update public.entries
  set recurrence_day = extract(day from due_date)::smallint
  where is_recurring = true and recurrence_day is null;
