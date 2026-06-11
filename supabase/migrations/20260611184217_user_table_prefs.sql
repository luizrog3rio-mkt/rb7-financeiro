-- Preferências de coluna por usuário (ordem, larguras, colunas escondidas) por
-- tabela da UI. Guarda o layout que cada um monta nas tabelas reordenáveis/
-- redimensionáveis, sincronizando entre dispositivos (o front cacheia em
-- localStorage e usa o banco como fonte da verdade).
--
-- DIVERGE do modelo de equipe (using(true)) de PROPÓSITO: preferência de coluna
-- é PRIVADA por usuário — se fosse compartilhada, um colega sobrescreveria o
-- layout do outro. Por isso é owner-scoped (auth.uid() = user_id), igual às
-- tabelas per-user do baseline. Os advisors confirmam: NÃO entra nos WARNs
-- rls_policy_always_true. Grant explícito (default privileges revogados na Fase 1a).
--
-- APLICADA: 2026-06-11 (version 20260611184217)

create table public.user_table_prefs (
  user_id    uuid not null references auth.users (id) on delete cascade,
  table_key  text not null,
  config     jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, table_key)
);

alter table public.user_table_prefs enable row level security;

create policy "Users manage own table prefs" on public.user_table_prefs
  for all to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

grant select, insert, update, delete on table public.user_table_prefs to authenticated;
revoke all on table public.user_table_prefs from anon;
