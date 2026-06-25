-- ============================================================================
-- Migration: remoção TOTAL do conceito de "categoria"
-- APLICADA em 2026-06-25 via MCP apply_migration — version 20260625163650
-- (renomeada do placeholder 20260625000000). Verificado pós-apply: 0 colunas,
-- 0 tabelas e 0 RPCs de categoria restantes. APROVADO pelo Luiz.
-- ----------------------------------------------------------------------------
-- A classificação financeira passou a ser feita só pelo Plano de Contas
-- (chart_of_accounts) + Produto DRE (dre_products). O frontend já parou de ler
-- e gravar categoria nas Fases 1 e 2 (2026-06-25): telas Lançamentos, Faturas/
-- Fatura, Compras, Extratos, Dashboard, exports; e as telas Categorias e
-- Relatório de Categorias foram removidas.
--
-- IRREVERSÍVEL — apagou dado real de produção:
--   transactions.category ...... 915 categorizadas (de 1112)
--   entries.category_id ........ 76
--   purchase_items.category .... 10
--   auto_rules ................. 62 regras
--   categories ................. 13 (dicionário)
--   purchase_item_categories ... 8 (dicionário)
--   bank_transactions.category_id / auto_categorized ... 0 (colunas nunca usadas)
-- ============================================================================

-- 1) RPCs órfãs que liam categoria. A DRE viva usa dre_by_competency (por
--    chart_of_accounts/natureza) — estas duas não tinham mais caller no frontend.
drop function if exists public.relatorio_categorias(date, date, uuid, text, boolean, boolean, boolean);
drop function if exists public.dre_competencia(uuid, date, date, text);

-- 2) Colunas de categoria. Dropar entries.category_id e bank_transactions.
--    category_id remove junto as FKs para categories.
alter table public.entries            drop column if exists category_id;
alter table public.bank_transactions  drop column if exists category_id;
alter table public.bank_transactions  drop column if exists auto_categorized;
alter table public.transactions       drop column if exists category;
alter table public.transactions       drop column if exists auto_categorized;
alter table public.purchase_items     drop column if exists category;

-- 3) Tabelas-dicionário de categoria (sem mais FKs apontando para elas).
drop table if exists public.auto_rules;
drop table if exists public.categories;
drop table if exists public.purchase_item_categories;
