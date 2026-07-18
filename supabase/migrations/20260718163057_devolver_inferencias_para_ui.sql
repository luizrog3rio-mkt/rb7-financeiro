-- devolver_inferencias_para_ui
-- ============================================================================================
-- STATUS: APLICADA em 18/07/2026 via MCP, autorizada explicitamente pelo Luiz.
-- Versao real retornada por list_migrations: 20260718163057.
-- Smoke: 2 itens/R$16.400,00 sem conta e sem obra, 0 partidas afetadas, NC-2 visivel na UI,
-- Cristais com 22 itens/R$61.095,75 em estoque e 0 partidas desbalanceadas.
--
-- REGRA: o que nao for conhecido com seguranca fica sem classificacao para o Luiz resolver
-- depois pela UI. Desfaz somente as duas atribuicoes que usaram inferencia operacional no lote
-- 20260718161547: Madeireira do Zetinho e G4 Construcoes. Nenhuma delas tem partidas.
--
-- EFEITO: Cristais passa de 24/R$77.495,75 para 22/R$61.095,75 em estoque. A fila da UI
-- volta a mostrar 2 itens/R$16.400,00 em NC-2. Nenhuma outra classificacao e alterada.
-- ============================================================================================

do $migration$
declare
  v_company uuid;
  v_stock uuid;
  v_cristais uuid;
  v_qtd integer;
  v_estado_ok integer;
  v_valor numeric;
  v_partidas integer;
  v_alterados integer;
begin
  select id into strict v_company
  from public.companies where name='RB7 INCORPORADORA';

  select id into strict v_stock
  from public.chart_of_accounts
  where company_id=v_company and tipo='patrimonial' and code='1.2'
    and nature='asset' and active=true and is_analytical=true;

  select id into strict v_cristais
  from public.obras where company_id=v_company and nome='Cristais';

  if exists (select 1 from public.closed_periods where period='2026-04') then
    raise exception 'Abril/2026 esta fechado; correcao abortada';
  end if;

  select count(*),
         count(*) filter (where e.chart_of_account_id=v_stock and e.obra_id=v_cristais),
         coalesce(sum(e.amount),0),
         count(p.*)
    into v_qtd,v_estado_ok,v_valor,v_partidas
  from public.entries e
  left join public.partidas p on p.entry_id=e.id
  where e.company_id=v_company
    and e.id in (
      'a83fe906-3516-4c59-9c2e-136913df7522'::uuid, -- Madeireira do Zetinho
      'edd997cf-ef47-4cc6-8350-70836869bb52'::uuid  -- G4 Construcoes
    );

  if v_qtd<>2 or v_estado_ok<>2 or v_valor<>16400.00 or v_partidas<>0 then
    raise exception 'Precondicao divergiu: qtd %, estado_ok %, valor %, partidas % (esperado 2/2/16400/0)',
      v_qtd,v_estado_ok,v_valor,v_partidas;
  end if;

  update public.entries
     set chart_of_account_id=null,
         obra_id=null
   where company_id=v_company
     and id in (
      'a83fe906-3516-4c59-9c2e-136913df7522'::uuid,
      'edd997cf-ef47-4cc6-8350-70836869bb52'::uuid
     )
     and chart_of_account_id=v_stock
     and obra_id=v_cristais;

  get diagnostics v_alterados=row_count;
  if v_alterados<>2 then
    raise exception 'UPDATE atingiu % linhas; esperado 2',v_alterados;
  end if;

  if exists (
    select 1 from public.entries
    where id in (
      'a83fe906-3516-4c59-9c2e-136913df7522'::uuid,
      'edd997cf-ef47-4cc6-8350-70836869bb52'::uuid
    ) and (chart_of_account_id is not null or obra_id is not null)
  ) then
    raise exception 'Pos-condicao falhou: classificacao ainda presente';
  end if;

  raise notice 'Dois itens/R$16.400,00 devolvidos para classificacao pela UI';
end;
$migration$;
