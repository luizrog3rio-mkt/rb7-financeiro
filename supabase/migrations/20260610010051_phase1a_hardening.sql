-- ============================================================
-- FASE 1a — HARDENING
-- Projeto: qdnqghefwjpeiidjlzjy (categorizador-fatura, org RB7)
--
-- Corrige todos os achados dos advisors de 2026-06-09:
--   [SEC 0011] handle_new_user com search_path mutável
--   [SEC 0028/0029] handle_new_user (SECURITY DEFINER) executável
--                   via /rest/v1/rpc por anon e authenticated
--   [PERF 0003] 9 policies re-avaliando auth.uid() por linha
--   [PERF 0001] FK purchase_items.user_id sem índice
--   + grants excessivos de anon/authenticated (TRUNCATE etc.)
--
-- Semântica de acesso INALTERADA: usuário autenticado enxerga
-- apenas as próprias linhas (auth.uid() = user_id). O modelo de
-- equipe ("todos veem tudo") é a Fase 1b, NÃO esta migration.
--
-- Passos manuais no dashboard (não existem em SQL) — ver
-- supabase/MIGRATIONS.md:
--   1. Habilitar proteção contra senhas vazadas (HIBP)
--   2. Rotacionar a service key (foi exposta em chat)
-- ============================================================

-- ------------------------------------------------------------
-- 1. handle_new_user: fixar search_path + tirar da API REST
-- ------------------------------------------------------------
-- SECURITY DEFINER se mantém: o INSERT em auth.users roda como
-- supabase_auth_admin, que não tem privilégio em public.profiles.
-- search_path vazio + referências qualificadas = imune a
-- sequestro de schema (recomendação oficial do lint 0011).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

-- Lints 0028/0029: a função não é API. (Na prática o PostgREST
-- nem expõe funções "returns trigger" via /rest/v1/rpc — o revoke
-- é higiene e silencia os advisors.) Postgres checa EXECUTE
-- apenas do role que EXECUTA o CREATE TRIGGER, no momento da
-- criação; no disparo não há checagem de ACL — o trigger já
-- existente em auth.users continua funcionando após o revoke.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- Defensivo: garante EXECUTE caso um futuro CREATE TRIGGER seja
-- rodado como supabase_auth_admin (dono de auth.users). Recriar
-- como postgres dispensa isso (owner da função tem EXECUTE
-- implícito, imune ao revoke acima).
grant execute on function public.handle_new_user() to supabase_auth_admin;

-- ------------------------------------------------------------
-- 2. Policies: TO authenticated + (select auth.uid()) +
--    WITH CHECK explícito  [PERF 0003 + checklist de segurança]
-- ------------------------------------------------------------

-- profiles -----------------------------------------------------
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- categories ---------------------------------------------------
drop policy if exists "Users manage own categories" on public.categories;
create policy "Users manage own categories"
  on public.categories for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- auto_rules ---------------------------------------------------
drop policy if exists "Users manage own rules" on public.auto_rules;
create policy "Users manage own rules"
  on public.auto_rules for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- invoices -----------------------------------------------------
drop policy if exists "Users manage own invoices" on public.invoices;
create policy "Users manage own invoices"
  on public.invoices for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- transactions -------------------------------------------------
drop policy if exists "Users manage own transactions" on public.transactions;
create policy "Users manage own transactions"
  on public.transactions for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- purchase_item_categories ------------------------------------
drop policy if exists "Users manage own purchase categories" on public.purchase_item_categories;
create policy "Users manage own purchase categories"
  on public.purchase_item_categories for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- purchase_items -----------------------------------------------
drop policy if exists "Users manage own purchase items" on public.purchase_items;
create policy "Users manage own purchase items"
  on public.purchase_items for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ------------------------------------------------------------
-- 3. Grants: princípio do menor privilégio
-- ------------------------------------------------------------
-- O app exige login para qualquer operação de dados — anon não
-- tem por que acessar tabela nenhuma (as policies já bloqueavam
-- as linhas; isto remove também a superfície de ataque).
revoke all on table
  public.profiles,
  public.categories,
  public.auto_rules,
  public.invoices,
  public.transactions,
  public.purchase_item_categories,
  public.purchase_items
from anon;

-- authenticated não precisa de TRUNCATE/REFERENCES/TRIGGER nem
-- de MAINTAIN (novo no PG 17: VACUUM/ANALYZE/REINDEX/CLUSTER).
-- TRUNCATE em particular ignora RLS.
revoke truncate, references, trigger, maintain on table
  public.profiles,
  public.categories,
  public.auto_rules,
  public.invoices,
  public.transactions,
  public.purchase_item_categories,
  public.purchase_items
from authenticated;

-- Objetos futuros criados pelo role postgres não ganham mais
-- grant automático para anon (tabelas/sequences), nem privilégios
-- excessivos para authenticated — sem isto, toda tabela nova das
-- Fases 1b/1c renasceria com os grants que revogamos acima.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;
alter default privileges in schema public
  revoke truncate, references, trigger, maintain on tables from authenticated;

-- Para FUNÇÕES o grant default do Postgres vive em PUBLIC (anon e
-- authenticated apenas herdam) — revogar só de anon seria inócuo.
-- Forma oficial do quick-reference do lint 0029. Consequência:
-- funções RPC intencionais futuras precisarão de GRANT EXECUTE
-- explícito para authenticated.
alter default privileges in schema public
  revoke execute on functions from public, anon, authenticated;

-- ------------------------------------------------------------
-- 4. Índice cobrindo a FK purchase_items.user_id  [PERF 0001]
-- ------------------------------------------------------------
create index if not exists idx_purchase_items_user
  on public.purchase_items using btree (user_id);
