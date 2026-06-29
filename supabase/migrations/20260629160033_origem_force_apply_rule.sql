-- APLICADA: 20260629160033
-- force_apply_origin_rule: re-aplica uma regra específica a TODAS as vendas correspondentes,
-- independente de já estarem classificadas (usado ao editar uma regra).
-- Aprovada pelo Luiz em 2026-06-29

create or replace function public.force_apply_origin_rule(p_rule_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
  r public.origin_tracking_rules;
begin
  select * into r from public.origin_tracking_rules where id = p_rule_id;
  if not found then return 0; end if;

  with matched as (
    select hs.transaction_code
    from public.hotmart_sales hs
    where (r.field = 'src'   and hs.src  = r.value)
       or (r.field = 'sck'   and hs.sck  = r.value)
       or (r.field = 'xcode' and hs.xcod = r.value)
  )
  insert into public.hotmart_sale_class
    (transaction_code, group_id, channel_id, seller_id, updated_at)
  select transaction_code, r.group_id, r.channel_id, r.seller_id, now()
  from matched
  on conflict (transaction_code) do update
    set group_id   = excluded.group_id,
        channel_id = excluded.channel_id,
        seller_id  = excluded.seller_id,
        updated_at = excluded.updated_at;

  get diagnostics affected = row_count;
  return affected;
end;
$$;

grant execute on function public.force_apply_origin_rule(uuid) to authenticated;
