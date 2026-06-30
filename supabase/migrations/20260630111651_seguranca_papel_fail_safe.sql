-- APLICADA: 20260630111651
-- Auditoria de seguranca: papel "fail-open". profiles.role tinha DEFAULT 'admin' e o
-- handle_new_user nao setava role -> TODO usuario novo nascia ADMIN. E a policy "Users can
-- update own profile" + grant UPDATE(role) deixava o proprio usuario se autopromover
-- viewer->admin. Aprovado pelo Luiz em 2026-06-30. (A edge function user-management foi
-- deployada junto: fallbacks ?? 'admin' -> 'viewer' e create seta o papel explicito.)
-- Verificado pos-fix: role_default='viewer', authenticated perdeu o UPDATE em profiles.

-- 1) default fail-safe: usuario novo nasce SEM privilegio
alter table public.profiles alter column role set default 'viewer';

-- 2) handle_new_user grava 'viewer' explicito (nao depende do default)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, email, role) values (new.id, new.email, 'viewer');
  return new;
end; $$;

-- 3) bloqueia autopromocao: tira o UPDATE de profiles do authenticated. O frontend so LE
-- profiles (AppContext/PeriodosFechados sao select); role muda so via user-management
-- (service key, nao afetada por este revoke). DELETE/INSERT remanescentes sao barrados pela
-- RLS (sem policy de DELETE; INSERT so own-row).
revoke update on public.profiles from authenticated;
