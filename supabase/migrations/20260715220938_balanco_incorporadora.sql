-- balanco_incorporadora — contas patrimoniais (Balanço) da RB7 INCORPORADORA (Fase 2c)
-- ============================================================================================
-- STATUS: ✅ APLICADA em 2026-07-15 (version 20260715220938), aprovada pelo Luiz (Balanço enxuto derivado).
--   Smoke: 11 contas (3 raízes), DRE Incorporadora inalterada (341.282,78), 0 patrimoniais na DRE.
--   Total do grupo: 75 contas patrimoniais (Digital 50 + Holding 14 + Incorporadora 11).
-- ============================================================================================
--
-- O QUE FAZ: seed do Balanço ENXUTO da Incorporadora. ⚠️ A planilha NÃO tem um Balanço explícito
--   da Incorporadora (só as abas "Custo por Obra" e "DRE Incorporadora"). Por decisão do Luiz
--   (2026-07-15), este Balanço é DERIVADO: espelha a estrutura da Digital no essencial + a conta de
--   ESTOQUE DE OBRAS que a aba "Custo por Obra" descreve ("enquanto a obra NÃO for vendida, este custo
--   é ESTOQUE (Ativo no Balanço)"). company_id = Incorporadora, tipo = 'patrimonial'. Mesmo padrão da 2a/2b.
--
--   Conta-chave: `1.2 Estoque de obras em andamento` — é onde o custo de obra vai ACUMULAR (ativo) e
--   será ligada a `obras.conta_estoque_id` na Fase 4b (estoque + evento de venda → CPV).
--
-- O QUE NÃO FAZ: não cria as contas de CUSTO de obra (Terreno/Mão de obra/Material… da aba Custo por
--   Obra) nem a DRE Incorporadora nem o mecanismo de estoque→venda — isso é a Fase 4b. Não lança saldo.
--   Não mexe na dre_by_competency (só patrimonial; o filtro tipo=resultado da 2a já exclui).
--
-- NEUTRO PARA A DRE. ROLLBACK: delete das patrimoniais da Incorporadora (nenhuma referenciada ainda).

insert into public.chart_of_accounts (company_id, tipo, code, name, nature, redutora, is_analytical, sort_order, active)
select '7bd4e9e2-3d39-4f84-9534-50bf840abc6b'::uuid, 'patrimonial', v.code, v.name, v.nature, v.redutora,
       true,
       split_part(v.code,'.',1)::int*1000000
         + coalesce(nullif(split_part(v.code,'.',2),'')::int,0)*1000
         + coalesce(nullif(split_part(v.code,'.',3),'')::int,0),
       true
from (values
  ('1','ATIVO','asset',false),
  ('1.1','Caixa e bancos','asset',false),
  ('1.2','Estoque de obras em andamento','asset',false),
  ('1.3','Terrenos','asset',false),
  ('2','PASSIVO','liability',false),
  ('2.1','Fornecedores a pagar','liability',false),
  ('2.2','Empréstimos e financiamentos','liability',false),
  ('2.3','Débitos com partes relacionadas','liability',false),
  ('3','PATRIMÔNIO LÍQUIDO','equity',false),
  ('3.1','Capital social','equity',false),
  ('3.2','Lucros acumulados','equity',false)
) as v(code, name, nature, redutora);

update public.chart_of_accounts c
set parent_id = p.id
from public.chart_of_accounts p
where c.company_id = '7bd4e9e2-3d39-4f84-9534-50bf840abc6b' and c.tipo = 'patrimonial' and c.code ~ '\.'
  and p.company_id = '7bd4e9e2-3d39-4f84-9534-50bf840abc6b' and p.tipo = 'patrimonial'
  and p.code = regexp_replace(c.code, '\.[^.]+$', '');

update public.chart_of_accounts c
set is_analytical = false
where c.company_id = '7bd4e9e2-3d39-4f84-9534-50bf840abc6b' and c.tipo = 'patrimonial'
  and exists (
    select 1 from public.chart_of_accounts f
    where f.company_id = '7bd4e9e2-3d39-4f84-9534-50bf840abc6b' and f.tipo = 'patrimonial' and f.parent_id = c.id
  );
