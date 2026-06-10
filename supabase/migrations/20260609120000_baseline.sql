-- ============================================================
-- BASELINE — snapshot fiel do schema VIVO de produção
-- Projeto: qdnqghefwjpeiidjlzjy (categorizador-fatura, org RB7)
-- Extraído em 2026-06-09 via pg_catalog/information_schema (PG 17.6)
-- Fonte: supabase/audit/live-catalog-20260609.json
--
-- ⚠️ NÃO EXECUTAR contra o banco de produção — os objetos já
-- existem lá. Este arquivo é o marco zero do histórico de
-- migrations: deve ser REGISTRADO como aplicado (ver
-- supabase/MIGRATIONS.md), não rodado.
--
-- Fidelidade: este arquivo reproduz o estado vivo COM os
-- problemas conhecidos (handle_new_user sem search_path,
-- policies sem TO authenticated). As correções vêm na migration
-- seguinte (phase1a_hardening), preservando a história real.
--
-- O que NÃO aparece aqui (e por quê):
-- * Extensões — o vivo tem pgcrypto, uuid-ossp, pg_stat_statements
--   e supabase_vault, todas defaults de projeto Supabase; nada no
--   schema depende delas (gen_random_uuid() é core no PG 17).
-- * GRANTs — anon/authenticated/service_role recebem privilégios
--   via default privileges do Supabase; um replay em projeto
--   Supabase limpo os reproduz automaticamente.
-- ============================================================

-- ------------------------------------------------------------
-- 1. profiles (estende auth.users; preenchida por trigger)
-- ------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- ------------------------------------------------------------
-- 2. handle_new_user + trigger em auth.users
--    (estado vivo: SECURITY DEFINER **sem** set search_path —
--    corrigido na migration de hardening)
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------
-- 3. categories (categorias de transação, por usuário)
-- ------------------------------------------------------------
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color_index integer not null default 0,
  created_at timestamptz default now(),
  unique (user_id, name)
);

alter table public.categories enable row level security;

create policy "Users manage own categories"
  on public.categories for all
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 4. auto_rules (regras de auto-categorização)
-- ------------------------------------------------------------
create table public.auto_rules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  keywords text[] not null,
  category text not null,
  created_at timestamptz default now()
);

alter table public.auto_rules enable row level security;

create policy "Users manage own rules"
  on public.auto_rules for all
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 5. invoices (uma por import de OFX)
-- ------------------------------------------------------------
create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text,
  total numeric default 0,
  transaction_count integer default 0,
  imported_at timestamptz default now()
);

alter table public.invoices enable row level security;

create policy "Users manage own invoices"
  on public.invoices for all
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 6. transactions
--    fit_id NÃO é chave de dedupe (Sicoob deriva de data+valor;
--    parcelamentos repetem entre faturas — ver CLAUDE.md)
-- ------------------------------------------------------------
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  invoice_id uuid references public.invoices (id) on delete cascade,
  fit_id text,
  memo text not null,
  amount numeric not null,
  date text not null,
  category text,
  auto_categorized boolean default false,
  created_at timestamptz default now()
);

alter table public.transactions enable row level security;

create policy "Users manage own transactions"
  on public.transactions for all
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 7. purchase_item_categories (categorias das compras anotadas)
-- ------------------------------------------------------------
create table public.purchase_item_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color_index integer not null default 0,
  created_at timestamptz default now(),
  unique (user_id, name)
);

alter table public.purchase_item_categories enable row level security;

create policy "Users manage own purchase categories"
  on public.purchase_item_categories for all
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 8. purchase_items (compras anotadas; não afetam totais)
--    Colunas month/purchase_date/payment_method e invoice_id
--    NULLABLE só existiam em produção — o repo antigo estava
--    desatualizado; este baseline reflete o vivo.
-- ------------------------------------------------------------
create table public.purchase_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  invoice_id uuid references public.invoices (id) on delete cascade,
  description text not null,
  amount numeric,
  category text,
  created_at timestamptz default now(),
  month text,
  purchase_date text,
  payment_method text
);

alter table public.purchase_items enable row level security;

create policy "Users manage own purchase items"
  on public.purchase_items for all
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 9. Índices (além dos criados por PK/UNIQUE)
-- ------------------------------------------------------------
create index idx_auto_rules_user on public.auto_rules using btree (user_id);
create index idx_categories_user on public.categories using btree (user_id);
create index idx_invoices_user on public.invoices using btree (user_id);
create index idx_purchase_item_categories_user on public.purchase_item_categories using btree (user_id);
create index idx_purchase_items_invoice on public.purchase_items using btree (invoice_id);
create index idx_transactions_invoice on public.transactions using btree (invoice_id);
create index idx_transactions_user on public.transactions using btree (user_id);
