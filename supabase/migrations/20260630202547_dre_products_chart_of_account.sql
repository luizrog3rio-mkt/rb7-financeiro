-- APLICADA: 20260630202547
-- Pedido do Luiz 2026-06-30: a DRE por competencia mostrava o Hotmart como 1 linha so ("Vendas
-- Hotmart"), deixando as contas de receita do plano (Mentorias/Cursos) vazias. Esta coluna liga
-- cada Produto DRE -> conta de receita; a dre_by_competency usa a cadeia venda->produto(ja
-- mapeado em hotmart_product_map)->conta pra dividir o bruto Hotmart entre as contas. Editavel no
-- select "Conta de Receita" da tela Produtos DRE. Aprovado pelo Luiz em 2026-06-30.
alter table public.dre_products
  add column chart_of_account_id uuid references public.chart_of_accounts(id) on delete set null;
