-- ============================================================================
-- Vendedores diretos (rastreados pelo sck do checkout) — base
-- ----------------------------------------------------------------------------
-- Às vezes o vendedor fecha a venda SEM ser afiliado: a atribuição vem pelo
-- parâmetro de tracking do link. Validado contra dados reais (2026-06-26): a API
-- /sales/history traz `purchase.tracking.source_sck` (NÃO `sck`); os valores são
-- ou ids por visitante (`<ts>_<id>`, ruído) ou UTMs (`a|b|c`, ruído) ou CÓDIGOS
-- FIXOS DE VENDEDOR (ex.: `raphaella_silva`, `maikom_vinicius`, `luiz_otavio`).
--
--  - sellers: cadastro do vendedor (nome/código/ativo), modelo-equipe
--  - hotmart_sck_map: de-para sck → vendedor (espelha hotmart_product_map; a
--    grafia varia — luiz_otavio/luiz-otavio/luizotavio → 3 linhas, 1 vendedor)
--  - hotmart_sales.sck: o source_sck capturado por venda
--  - hotmart_sales.sck_checked_at: rodízio do backfill (mirror commission_checked_at;
--    distingue "já chequei o tracking" de "esta venda tem sck")
--
-- APLICADA: 2026-06-26 (version 20260626124334)
-- ============================================================================

create table public.sellers (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  code       text,
  active     boolean not null default true,
  company_id uuid references public.companies(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.sellers enable row level security;
create policy "authenticated all" on public.sellers
  for all to authenticated using (true) with check (true);
revoke truncate, references, trigger, maintain on table public.sellers from authenticated;
revoke all on table public.sellers from anon;

create table public.hotmart_sck_map (
  sck        text primary key,
  seller_id  uuid references public.sellers(id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.hotmart_sck_map enable row level security;
create policy "authenticated all" on public.hotmart_sck_map
  for all to authenticated using (true) with check (true);
revoke truncate, references, trigger, maintain on table public.hotmart_sck_map from authenticated;
revoke all on table public.hotmart_sck_map from anon;

alter table public.hotmart_sales add column sck text;
alter table public.hotmart_sales add column sck_checked_at timestamptz;
