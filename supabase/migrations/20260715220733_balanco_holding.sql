-- balanco_holding — contas patrimoniais (Balanço) da RB7 PARTICIPAÇÕES/Holding (Fase 2b)
-- ============================================================================================
-- STATUS: ✅ APLICADA em 2026-07-15 (version 20260715220733), aprovada pelo Luiz. Padrão idêntico à 2a
--   (verificação read-only: empresa Participações, 0 colisão, 14 natures válidas). Smoke: 14 contas
--   (3 raízes), DRE Participações inalterada (9.425,34), 0 patrimoniais na DRE.
-- ============================================================================================
--
-- O QUE FAZ: seed das contas de Balanço da Holding (aba "RB7 Participações", Bloco B — patrimonial),
--   RE-NUMERADO para o padrão 1=Ativo / 2=Passivo / 3=PL (igual à Digital; a planilha usava 6/7 só
--   porque juntava DRE+patrimonial num plano; aqui a separação é por `tipo`). company_id = Participações,
--   tipo = 'patrimonial'. O ativo principal da holding são os INVESTIMENTOS em participadas (1.3.x).
--   Mesmo padrão da Fase 2a (deriva parent_id/is_analytical/sort_order).
--
-- O QUE NÃO FAZ: NÃO cria a DRE da Holding (Bloco A — receita de participações). Ela depende da decisão
--   equivalência-patrimonial × dividendos E de a listagem-esqueleto da dre_by_competency passar a filtrar
--   por empresa (senão contas de resultado por-empresa poluiriam a DRE das outras). Fica p/ a fase Consolidada.
--   NÃO mexe na dre_by_competency (só patrimonial; o filtro tipo=resultado da Fase 2a já exclui estas contas).
--   NÃO lança saldo (contas vazias até a partida dobrada / lançamentos de saldo inicial).
--
-- NEUTRO PARA A DRE (patrimonial não entra em cálculo nem na listagem, que filtra tipo=resultado).
-- ROLLBACK: delete das patrimoniais da Participações (nenhuma referenciada por lançamento).

insert into public.chart_of_accounts (company_id, tipo, code, name, nature, redutora, is_analytical, sort_order, active)
select 'e2a6c194-ba94-4225-8ade-8d883f504ca3'::uuid, 'patrimonial', v.code, v.name, v.nature, v.redutora,
       true,
       split_part(v.code,'.',1)::int*1000000
         + coalesce(nullif(split_part(v.code,'.',2),'')::int,0)*1000
         + coalesce(nullif(split_part(v.code,'.',3),'')::int,0),
       true
from (values
  ('1','ATIVO','asset',false),
  ('1.1','Caixa e bancos','asset',false),
  ('1.2','Dividendos a receber das participadas','asset',false),
  ('1.3','Investimentos — Participações Societárias','asset',false),
  ('1.3.01','Participação em RB7 Digital','asset',false),
  ('1.3.02','Participação em RB7 Incorporadora','asset',false),
  ('1.3.03','Participação em Molho Digital (Cris)','asset',false),
  ('1.3.04','Participação em Zizem (Maycon)','asset',false),
  ('1.3.05','Outras participações','asset',false),
  ('2','PASSIVO','liability',false),
  ('2.1','Dividendos a pagar aos sócios','liability',false),
  ('3','PATRIMÔNIO LÍQUIDO','equity',false),
  ('3.1','Capital social','equity',false),
  ('3.2','Lucros acumulados','equity',false)
) as v(code, name, nature, redutora);

update public.chart_of_accounts c
set parent_id = p.id
from public.chart_of_accounts p
where c.company_id = 'e2a6c194-ba94-4225-8ade-8d883f504ca3' and c.tipo = 'patrimonial' and c.code ~ '\.'
  and p.company_id = 'e2a6c194-ba94-4225-8ade-8d883f504ca3' and p.tipo = 'patrimonial'
  and p.code = regexp_replace(c.code, '\.[^.]+$', '');

update public.chart_of_accounts c
set is_analytical = false
where c.company_id = 'e2a6c194-ba94-4225-8ade-8d883f504ca3' and c.tipo = 'patrimonial'
  and exists (
    select 1 from public.chart_of_accounts f
    where f.company_id = 'e2a6c194-ba94-4225-8ade-8d883f504ca3' and f.tipo = 'patrimonial' and f.parent_id = c.id
  );
