-- APLICADA: 20260629214649
-- Proveniência da classificação por venda (Fase 5 — integridade do motor de regras).
-- source: 'manual' (feito à mão, regra NUNCA sobrescreve) vs 'rule' (gerado por regra).
-- applied_by_rule: qual regra classificou a venda (FK, ON DELETE SET NULL = rede de
-- segurança; o reapply_all é quem de fato reverte ao excluir). Aprovada pelo Luiz em
-- 2026-06-29. Blast radius medido = 0 (estado atual era 100% coerente com as regras).
alter table public.hotmart_sale_class
  add column source text not null default 'rule',
  add column applied_by_rule uuid references public.origin_tracking_rules(id) on delete set null,
  add constraint hotmart_sale_class_source_check check (source in ('manual','rule'));

create index idx_hotmart_sale_class_applied_by_rule on public.hotmart_sale_class(applied_by_rule);
