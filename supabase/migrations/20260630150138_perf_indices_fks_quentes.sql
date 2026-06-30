-- APLICADA: 20260630150138
-- Auditoria performance 2026-06-30: FKs sem indice. hotmart_sale_class (10.626 linhas) faz
-- seq scan no RESTRICT-check ao excluir/editar grupo ou vendedor + no churn do reapply_all.
-- Os 2 primeiros matam isso; os 3 seguintes sao baratos/future-proof (self-joins de entries
-- e do Plano). Indices parciais (where not null) -- menores; seller_id e nulo na maioria.
-- NAO indexa channel_id (morto, sai na limpeza do CANAL). Aprovado pelo Luiz em 2026-06-30.
-- Verificado: EXPLAIN do lookup por group_id = Index Only Scan using idx_hsc_group (Heap Fetches 0).
create index if not exists idx_hsc_group     on public.hotmart_sale_class(group_id)  where group_id is not null;
create index if not exists idx_hsc_seller    on public.hotmart_sale_class(seller_id) where seller_id is not null;
create index if not exists idx_entries_parent on public.entries(parent_entry_id)     where parent_entry_id is not null;
create index if not exists idx_entries_refund on public.entries(refund_of_entry_id)  where refund_of_entry_id is not null;
create index if not exists idx_coa_parent    on public.chart_of_accounts(parent_id)  where parent_id is not null;
