-- APLICADA: 20260630190737
-- Auditoria resiliencia 2026-06-30: tela do log forense de delecoes (deletions_log). RPC resolve
-- o "quem deletou" (auth.users.email, nao legivel pelo frontend) e formata um resumo do snapshot
-- por tabela. security definer (le auth.users), anon revogado. Aprovado pelo Luiz em 2026-06-30.
-- Verificado: insert+delete transacional -> resumo "ALUGUEL ESCRITORIO — R$ 3500.00"; anon=false.
create or replace function public.listar_delecoes(p_limit int default 100)
returns table(id uuid, quando timestamptz, tabela text, por text, resumo text)
language sql stable security definer set search_path to '' as $function$
  select d.id, d.deleted_at, d.table_name,
    coalesce(u.email, '—'),
    case d.table_name
      when 'entries'  then left(coalesce(d.snapshot->>'description','(sem descrição)'),60) || ' — R$ ' || coalesce(d.snapshot->>'amount','?')
      when 'invoices' then coalesce(d.snapshot->>'name','(fatura)') || ' — R$ ' || coalesce(d.snapshot->>'total','?')
      else d.table_name
    end
  from public.deletions_log d
  left join auth.users u on u.id = d.deleted_by
  order by d.deleted_at desc
  limit greatest(1, least(500, p_limit));
$function$;
revoke execute on function public.listar_delecoes(int) from public;
grant  execute on function public.listar_delecoes(int) to authenticated;
