-- obra_venda_cpv_ui
-- ============================================================================================
-- STATUS: APLICADA no Supabase em 18/07/2026 (version 20260718165601).
--
-- OBJETIVO: concluir a Fase 4b-2 sem adivinhar dados. A UI passa a mostrar as contrapartidas
-- pendentes de cada custo de obra, deixa o admin escolher a conta que realmente pagou e somente
-- libera a venda quando o estoque estiver completo no razao. Na venda, cria um lancamento
-- contabil sem caixa (D CPV / C Estoque) e marca a obra como vendida na data informada.
--
-- DADOS REAIS NO DRY-RUN 18/07/2026:
--   Alfenas: 34 custos/R$56.676,31, 29 contrapartidas pendentes, 5 completas.
--   Cristais: 22 custos/R$61.095,75, 22 contrapartidas pendentes, 0 completas.
--   Nenhuma obra esta pronta para venda hoje; a migration NAO vende nem classifica nada sozinha.
--
-- SEGURANCA:
--   Funcoes de escrita sao SECURITY INVOKER + is_admin(), RLS continua valendo, PUBLIC/anon sem
--   EXECUTE. A operacao e atomica e respeita periodos fechados. Intercompany continua permitido:
--   a UI lista contas ativas de todas as empresas e o humano escolhe a conta pagadora real.
-- ============================================================================================

-- Conta de resultado propria para a baixa do estoque na venda. Estrutural e compartilhada.
insert into public.chart_of_accounts
  (company_id,tipo,code,name,parent_id,nature,redutora,is_analytical,sort_order,active)
select null,'resultado','4.6','Custo das Obras Vendidas (CPV)',p.id,
       'variable_cost',false,true,4006000,true
from public.chart_of_accounts p
where p.company_id is null and p.tipo='resultado' and p.code='4'
  and not exists (
    select 1 from public.chart_of_accounts c
    where c.company_id is null and c.tipo='resultado' and c.code='4.6'
  );

do $pre$
begin
  if (select count(*) from public.chart_of_accounts
      where company_id is null and tipo='resultado' and code='4.6'
        and name='Custo das Obras Vendidas (CPV)' and nature='variable_cost'
        and active=true and is_analytical=true) <> 1 then
    raise exception 'Conta 4.6 de CPV nao ficou unica e valida';
  end if;
end;
$pre$;

-- Vínculo idempotente do evento contábil de venda. Um evento por obra.
alter table public.obras
  add column cpv_entry_id uuid references public.entries(id) on delete restrict;

create unique index idx_obras_cpv_entry
  on public.obras(cpv_entry_id) where cpv_entry_id is not null;

alter table public.obras
  add constraint obras_cpv_venda_coerente check (
    (status='em_andamento' and data_venda is null and cpv_entry_id is null)
    or (status='vendida' and data_venda is not null and cpv_entry_id is not null)
  );

-- O relatório continua mostrando o custo original, sem dobrar com o lançamento de CPV.
create or replace function public.custo_por_obra(p_company uuid)
returns table(obra_id uuid, obra text, status text, data_venda date,
              conta_code text, conta_name text, valor numeric, qtd bigint)
language sql
stable
security invoker
set search_path = ''
as $$
  select o.id, o.nome, o.status, o.data_venda,
         coalesce(c.code, '(sem conta)') as conta_code,
         coalesce(c.name, '(a classificar)') as conta_name,
         coalesce(sum(e.amount),0::numeric) as valor,
         count(e.id) as qtd
  from public.obras o
  left join public.entries e
    on e.obra_id=o.id
   and e.status not in ('cancelled','refunded')
   and e.id is distinct from o.cpv_entry_id
  left join public.chart_of_accounts c on c.id=e.chart_of_account_id
  where o.company_id=p_company
  group by o.id,o.nome,o.status,o.data_venda,c.code,c.name
  order by o.nome,coalesce(c.code,'zzz');
$$;

revoke all on function public.custo_por_obra(uuid) from public,anon;
grant execute on function public.custo_por_obra(uuid) to authenticated,service_role;

-- Situação resumida por obra: a UI não infere; só mostra o que falta.
create or replace function public.obra_situacao_contabil(p_company uuid)
returns table(
  obra_id uuid, obra text, status text, data_venda date,
  total_custo numeric, qtd_custos bigint, qtd_sem_conta bigint,
  qtd_sem_partidas bigint, saldo_estoque_razao numeric,
  pronta_venda boolean, cpv_entry_id uuid
)
language sql
stable
security invoker
set search_path = ''
as $$
  with custos as (
    select o.id as oid,e.id as eid,e.amount,e.account_id,o.conta_estoque_id,
      coalesce((select sum(case when p.natureza='debito' then p.valor else -p.valor end)
                from public.partidas p where p.entry_id=e.id and p.conta_id=o.conta_estoque_id),0) as estoque_liquido,
      coalesce((select sum(p.valor) filter(where p.natureza='debito') from public.partidas p where p.entry_id=e.id),0) as debitos,
      coalesce((select sum(p.valor) filter(where p.natureza='credito') from public.partidas p where p.entry_id=e.id),0) as creditos
    from public.obras o
    join public.entries e
      on e.obra_id=o.id and e.chart_of_account_id=o.conta_estoque_id
     and e.status not in ('cancelled','refunded')
    where o.company_id=p_company
  ), resumo as (
    select oid,count(*) qtd,sum(amount) total,
      count(*) filter(where account_id is null) sem_conta,
      count(*) filter(where estoque_liquido<>amount or debitos<>creditos) sem_partidas
    from custos group by oid
  )
  select o.id,o.nome,o.status,o.data_venda,
         coalesce(r.total,0::numeric),coalesce(r.qtd,0::bigint),
         coalesce(r.sem_conta,0::bigint),coalesce(r.sem_partidas,0::bigint),
         coalesce((
           select sum(case when p.natureza='debito' then p.valor else -p.valor end)
           from public.partidas p
           join public.entries pe on pe.id=p.entry_id
           where pe.obra_id=o.id and p.conta_id=o.conta_estoque_id
         ),0::numeric) as saldo,
         (o.status='em_andamento' and coalesce(r.qtd,0)>0
           and coalesce(r.sem_conta,0)=0 and coalesce(r.sem_partidas,0)=0
           and coalesce((
             select sum(case when p.natureza='debito' then p.valor else -p.valor end)
             from public.partidas p
             join public.entries pe on pe.id=p.entry_id
             where pe.obra_id=o.id and p.conta_id=o.conta_estoque_id
           ),0)=coalesce(r.total,0)) as pronta,
         o.cpv_entry_id
  from public.obras o
  left join resumo r on r.oid=o.id
  where o.company_id=p_company
  order by o.nome;
$$;

revoke all on function public.obra_situacao_contabil(uuid) from public,anon;
grant execute on function public.obra_situacao_contabil(uuid) to authenticated,service_role;

-- Lista somente os custos que ainda precisam de decisão humana sobre a conta pagadora.
create or replace function public.obra_contrapartidas_pendentes(p_company uuid)
returns table(
  entry_id uuid, obra_id uuid, obra text, descricao text,
  valor numeric, data date, account_id uuid
)
language sql
stable
security invoker
set search_path = ''
as $$
  select e.id,o.id,o.nome,e.description,e.amount,
         coalesce(e.payment_date,e.competency_date,e.issue_date,e.due_date),e.account_id
  from public.obras o
  join public.entries e
    on e.obra_id=o.id and e.chart_of_account_id=o.conta_estoque_id
   and e.status not in ('cancelled','refunded')
  where o.company_id=p_company and (
    e.account_id is null
    or coalesce((select sum(case when p.natureza='debito' then p.valor else -p.valor end)
                 from public.partidas p where p.entry_id=e.id and p.conta_id=o.conta_estoque_id),0)<>e.amount
    or coalesce((select sum(p.valor) filter(where p.natureza='debito') from public.partidas p where p.entry_id=e.id),0)
       <> coalesce((select sum(p.valor) filter(where p.natureza='credito') from public.partidas p where p.entry_id=e.id),0)
  )
  order by o.nome,coalesce(e.payment_date,e.competency_date,e.issue_date,e.due_date),e.description;
$$;

revoke all on function public.obra_contrapartidas_pendentes(uuid) from public,anon;
grant execute on function public.obra_contrapartidas_pendentes(uuid) to authenticated,service_role;

-- Escolha humana da conta pagadora + geração atômica D Estoque / C Caixa ou obrigação.
create or replace function public.definir_conta_pagadora_obra(p_entry uuid,p_account uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_entry public.entries%rowtype;
  v_stock uuid;
  v_counterpart uuid;
  v_active boolean;
begin
  if not coalesce(public.is_admin(),false) then
    raise exception 'Apenas administradores podem definir a conta pagadora'
      using errcode='insufficient_privilege';
  end if;

  select e.* into strict v_entry
  from public.entries e
  where e.id=p_entry
  for update;

  select o.conta_estoque_id into strict v_stock
  from public.obras o where o.id=v_entry.obra_id;

  if v_entry.chart_of_account_id is distinct from v_stock then
    raise exception 'O lancamento nao e custo de estoque da obra';
  end if;
  if v_entry.status<>'paid' or v_entry.payment_date is null then
    raise exception 'Informe o pagamento do lancamento antes da conta pagadora';
  end if;
  if exists(select 1 from public.partidas p where p.entry_id=p_entry) then
    raise exception 'O lancamento ja possui partidas; revise pelo razao';
  end if;

  select a.conta_contabil_id,a.active into strict v_counterpart,v_active
  from public.accounts a where a.id=p_account;
  if not v_active or v_counterpart is null then
    raise exception 'A conta selecionada esta inativa ou sem vinculo contabil';
  end if;

  update public.entries set account_id=p_account where id=p_entry;

  insert into public.partidas(entry_id,conta_id,natureza,valor,memo) values
    (p_entry,v_stock,'debito',v_entry.amount,'contrapartida definida pela UI de obras'),
    (p_entry,v_counterpart,'credito',v_entry.amount,'contrapartida definida pela UI de obras');
end;
$$;

revoke all on function public.definir_conta_pagadora_obra(uuid,uuid) from public,anon;
grant execute on function public.definir_conta_pagadora_obra(uuid,uuid) to authenticated;

-- Evento de venda: só roda quando todas as contrapartidas já fecharam o estoque no razão.
create or replace function public.finalizar_venda_obra(p_obra uuid,p_data_venda date)
returns table(cpv_entry_id uuid,custo numeric)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_obra public.obras%rowtype;
  v_cpv uuid;
  v_qtd bigint;
  v_custo numeric;
  v_incompletos bigint;
  v_saldo numeric;
  v_entry uuid;
begin
  if not coalesce(public.is_admin(),false) then
    raise exception 'Apenas administradores podem finalizar a venda da obra'
      using errcode='insufficient_privilege';
  end if;
  if p_data_venda is null or p_data_venda not between date '2015-01-01' and date '2040-01-01' then
    raise exception 'Informe uma data de venda valida';
  end if;

  select * into strict v_obra from public.obras where id=p_obra for update;
  if v_obra.status<>'em_andamento' or v_obra.data_venda is not null or v_obra.cpv_entry_id is not null then
    raise exception 'A obra ja foi vendida ou esta em estado incompativel';
  end if;
  if v_obra.conta_estoque_id is null then
    raise exception 'A obra nao possui conta de estoque configurada';
  end if;
  if exists(select 1 from public.closed_periods cp
            where cp.company_id=v_obra.company_id and cp.period=to_char(p_data_venda,'YYYY-MM')) then
    raise exception 'O periodo da venda esta fechado. Reabra antes de finalizar.';
  end if;

  select id into strict v_cpv from public.chart_of_accounts
  where company_id is null and tipo='resultado' and code='4.6'
    and nature='variable_cost' and active=true and is_analytical=true;

  with estado as (
    select e.id,e.amount,e.account_id,
      coalesce((select sum(case when p.natureza='debito' then p.valor else -p.valor end)
                from public.partidas p where p.entry_id=e.id and p.conta_id=v_obra.conta_estoque_id),0) estoque_liquido,
      coalesce((select sum(p.valor) filter(where p.natureza='debito') from public.partidas p where p.entry_id=e.id),0) debitos,
      coalesce((select sum(p.valor) filter(where p.natureza='credito') from public.partidas p where p.entry_id=e.id),0) creditos
    from public.entries e
    where e.obra_id=p_obra and e.chart_of_account_id=v_obra.conta_estoque_id
      and e.status not in ('cancelled','refunded')
  )
  select count(*),coalesce(sum(amount),0),
         count(*) filter(where account_id is null or estoque_liquido<>amount or debitos<>creditos)
    into v_qtd,v_custo,v_incompletos
  from estado;

  select coalesce(sum(case when p.natureza='debito' then p.valor else -p.valor end),0)
    into v_saldo
  from public.partidas p
  join public.entries e on e.id=p.entry_id
  where e.obra_id=p_obra and p.conta_id=v_obra.conta_estoque_id;

  if v_qtd=0 or v_custo<=0 then
    raise exception 'A obra nao possui custo de estoque para baixar';
  end if;
  if v_incompletos<>0 or v_saldo<>v_custo then
    raise exception 'Ainda existem % contrapartidas pendentes. Resolva pela UI antes da venda.',v_incompletos;
  end if;

  insert into public.entries(
    company_id,type,description,amount,issue_date,due_date,competency_date,
    payment_date,status,counterparty,notes,created_by,chart_of_account_id,obra_id
  ) values (
    v_obra.company_id,'payable','CPV - Venda da obra '||v_obra.nome,v_custo,
    p_data_venda,p_data_venda,p_data_venda,null,'paid','Reclassificacao interna',
    'Lancamento automatico sem efeito de caixa: baixa do estoque para CPV.',
    auth.uid(),v_cpv,p_obra
  ) returning id into v_entry;

  insert into public.partidas(entry_id,conta_id,natureza,valor,memo) values
    (v_entry,v_cpv,'debito',v_custo,'venda da obra: reconhecimento do CPV'),
    (v_entry,v_obra.conta_estoque_id,'credito',v_custo,'venda da obra: baixa do estoque');

  update public.obras
     set status='vendida',data_venda=p_data_venda,cpv_entry_id=v_entry
   where id=p_obra;

  return query select v_entry,v_custo;
end;
$$;

revoke all on function public.finalizar_venda_obra(uuid,date) from public,anon;
grant execute on function public.finalizar_venda_obra(uuid,date) to authenticated;
