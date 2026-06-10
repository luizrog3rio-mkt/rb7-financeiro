-- Corrige handle_new_user: security definer sem search_path fixo quebra a
-- criação de usuários via GoTrue (sessão roda com search_path = auth e o
-- insert em "perfis" não resolve). Fixa search_path vazio e qualifica nomes.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $fn$
begin
  insert into public.perfis (id, nome, papel)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', new.email), 'operador');
  return new;
end $fn$;
