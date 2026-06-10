-- Hardening apontado pelos advisors do Supabase (supabase db advisors)

-- 1) search_path fixo em set_atualizado_em (lint: function_search_path_mutable)
create or replace function public.set_atualizado_em()
returns trigger language plpgsql set search_path = '' as $fn$
begin
  new.atualizado_em = now();
  return new;
end $fn$;

-- 2) Funções de trigger não devem ficar expostas via /rest/v1/rpc
--    (lints: anon/authenticated_security_definer_function_executable).
--    Triggers continuam funcionando: o EXECUTE é checado na criação do
--    trigger, não a cada disparo.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_atualizado_em() from public, anon, authenticated;

-- 3) perfis: impede auto-promoção de papel (um operador podia fazer
--    update perfis set papel='admin' no próprio registro — RLS não
--    restringe colunas). Com privilégio de coluna, só "nome" é editável
--    pelo app; mudança de papel fica restrita a SQL (service role/dashboard).
revoke update on table public.perfis from authenticated;
grant update (nome) on table public.perfis to authenticated;

-- 4) Política de update do perfis: (select auth.uid()) evita reavaliação
--    por linha (lint: auth_rls_initplan) e WITH CHECK explícito.
drop policy "perfis: atualiza próprio" on public.perfis;
create policy "perfis: atualiza próprio" on public.perfis
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);
