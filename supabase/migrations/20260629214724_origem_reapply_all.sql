-- APLICADA: 20260629214724
-- reapply_all() — fonte da verdade da classificação por regras (Fase 5). Toda mudança
-- de regra (criar/editar/excluir) recomputa o universo do zero por PRECEDÊNCIA
-- (mais específica → mais antiga, determinístico), PRESERVA source='manual' (regra
-- nunca clobbera trabalho à mão) e elimina fantasmas/órfãos (limpa as de regra e
-- reinsere só o que casa hoje → excluir regra devolve as vendas pro 'a classificar').
-- apply_origin_rules e force_apply_origin_rule viram wrappers (frontend chama os mesmos
-- nomes). Aprovada pelo Luiz em 2026-06-29. reapply_all rodado 1x: 0 classificações
-- alteradas, 9911 links de proveniência preenchidos.
create or replace function public.reapply_all()
returns integer language plpgsql security definer set search_path = '' as $$
declare affected integer;
begin
  delete from public.hotmart_sale_class where source = 'rule';

  with matched as (
    select distinct on (hs.transaction_code)
      hs.transaction_code, r.id as rule_id, r.group_id, r.channel_id, r.seller_id
    from public.hotmart_sales hs
    join public.origin_tracking_rules r on
      (case r.src_match
        when 'is_empty'    then (hs.src is null or hs.src = '')
        when 'contains'    then r.src_value is not null and hs.src ilike '%' || r.src_value || '%'
        when 'starts_with' then r.src_value is not null and hs.src ilike r.src_value || '%'
        else r.src_value is null or hs.src = r.src_value end) and
      (case r.sck_match
        when 'is_empty'    then (hs.sck is null or hs.sck = '')
        when 'contains'    then r.sck_value is not null and hs.sck ilike '%' || r.sck_value || '%'
        when 'starts_with' then r.sck_value is not null and hs.sck ilike r.sck_value || '%'
        else r.sck_value is null or hs.sck = r.sck_value end) and
      (case r.xcode_match
        when 'is_empty'    then (hs.xcod is null or hs.xcod = '')
        when 'contains'    then r.xcode_value is not null and hs.xcod ilike '%' || r.xcode_value || '%'
        when 'starts_with' then r.xcode_value is not null and hs.xcod ilike r.xcode_value || '%'
        else r.xcode_value is null or hs.xcod = r.xcode_value end) and
      (case r.afiliado_match
        when 'is_empty'    then (hs.affiliate is null or hs.affiliate = '')
        when 'contains'    then r.afiliado_value is not null and hs.affiliate ilike '%' || r.afiliado_value || '%'
        when 'starts_with' then r.afiliado_value is not null and hs.affiliate ilike r.afiliado_value || '%'
        else r.afiliado_value is null or hs.affiliate = r.afiliado_value end)
    order by hs.transaction_code,
      (case when r.src_value is not null or r.src_match = 'is_empty' then 1 else 0 end +
       case when r.sck_value is not null or r.sck_match = 'is_empty' then 1 else 0 end +
       case when r.xcode_value is not null or r.xcode_match = 'is_empty' then 1 else 0 end +
       case when r.afiliado_value is not null or r.afiliado_match = 'is_empty' then 1 else 0 end) desc,
      r.created_at asc
  )
  insert into public.hotmart_sale_class (transaction_code, group_id, channel_id, seller_id, source, applied_by_rule, updated_at)
  select transaction_code, group_id, channel_id, seller_id, 'rule', rule_id, now() from matched
  on conflict (transaction_code) do update
    set group_id = excluded.group_id, channel_id = excluded.channel_id,
        seller_id = excluded.seller_id, source = 'rule',
        applied_by_rule = excluded.applied_by_rule, updated_at = excluded.updated_at
    where public.hotmart_sale_class.source <> 'manual';

  select count(*) into affected from public.hotmart_sale_class where source = 'rule';
  return affected;
end; $$;

create or replace function public.apply_origin_rules()
returns integer language plpgsql security definer set search_path = '' as $$
begin return public.reapply_all(); end; $$;

create or replace function public.force_apply_origin_rule(p_rule_id uuid)
returns integer language plpgsql security definer set search_path = '' as $$
begin return public.reapply_all(); end; $$;

grant execute on function public.reapply_all() to authenticated;
grant execute on function public.apply_origin_rules() to authenticated;
grant execute on function public.force_apply_origin_rule(uuid) to authenticated;
