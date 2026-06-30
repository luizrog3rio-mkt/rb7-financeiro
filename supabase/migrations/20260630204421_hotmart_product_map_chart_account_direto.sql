-- APLICADA: 20260630204421
-- Pedido do Luiz 2026-06-30: mapa DIRETO produto Hotmart -> conta de receita (pula o Produto DRE
-- do meio), pra o plano granular (1 conta por curso). A dre_by_competency usa coalesce(direto,
-- via-produto): conta direta tem prioridade, senao cai no dre_products.chart_of_account_id, senao
-- "a classificar". Editavel no select "Conta de Receita (direto)" da tela Mapear produtos.
-- Aprovado pelo Luiz em 2026-06-30. (Upsert independente do dre_product_id -- preserva o mapeamento
-- de produto DRE existente.)
alter table public.hotmart_product_map
  add column chart_of_account_id uuid references public.chart_of_accounts(id) on delete set null;
