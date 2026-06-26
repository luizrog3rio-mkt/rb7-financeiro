-- ============================================================================
-- Afiliados unificados na pessoa (vendedor) + tracking extra (src/external_code)
-- ----------------------------------------------------------------------------
-- O afiliado vinha como TEXTO solto em hotmart_sales.affiliate; agora vincula à
-- MESMA entidade `sellers` do vendedor por sck (são as mesmas pessoas: a pessoa
-- vende ora pelo link de afiliado, ora por sck). `hotmart_affiliate_map` espelha
-- `hotmart_sck_map`. O nome do afiliado vem da Hotmart (/sales/commissions
-- user.name) — canônico, pouca variante de grafia.
--
-- + colunas de tracking de origem/marketing (purchase.tracking): `src` (=source)
-- e `external_code`. ⚠️ NÃO carregam vendedor (só o sck carrega); `xcode` a API
-- /sales/history NÃO traz (webhook-only).
--
-- APLICADA: 2026-06-26 (version 20260626142135)
-- ============================================================================

create table public.hotmart_affiliate_map (
  affiliate  text primary key,
  seller_id  uuid references public.sellers(id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.hotmart_affiliate_map enable row level security;
create policy "authenticated all" on public.hotmart_affiliate_map
  for all to authenticated using (true) with check (true);
revoke truncate, references, trigger, maintain on table public.hotmart_affiliate_map from authenticated;
revoke all on table public.hotmart_affiliate_map from anon;

alter table public.hotmart_sales add column src text;            -- purchase.tracking.source
alter table public.hotmart_sales add column external_code text;  -- purchase.tracking.external_code
