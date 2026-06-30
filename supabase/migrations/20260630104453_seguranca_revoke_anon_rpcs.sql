-- APLICADA: 20260630104453
-- Auditoria de seguranca (2026-06-30): 6 funcoes SECURITY DEFINER tinham EXECUTE pra PUBLIC
-- (=> role anon herda), entao qualquer um com a chave publishable (publica, vai no bundle JS)
-- chamava via POST /rest/v1/rpc/<nome> SEM login. Como sao definer, furam a RLS de equipe:
--   - escrita (reapply_all/apply_origin_rules/force_apply_origin_rule): recomputo de ~14k vendas
--     por chamada = DoS + reescrita da classificacao de origem da base inteira;
--   - leitura (dre_by_competency/dre_cash_reconciliation/origin_unmapped_values): exfiltracao de
--     DRE/caixa/origem de qualquer empresa sem autenticar.
-- Fix: revogar de PUBLIC/anon. O grant explicito 'authenticated=X' ja existe e PERMANECE, entao o
-- frontend logado segue chamando normal. entry_audit_log_fn e funcao de trigger — nao precisa de
-- EXECUTE por nenhum role de API. Aprovado pelo Luiz em 2026-06-30.
revoke execute on function public.reapply_all()                                  from public, anon;
revoke execute on function public.apply_origin_rules()                           from public, anon;
revoke execute on function public.force_apply_origin_rule(uuid)                  from public, anon;
revoke execute on function public.dre_by_competency(uuid, integer, integer, integer) from public, anon;
revoke execute on function public.dre_cash_reconciliation(uuid, integer)         from public, anon;
revoke execute on function public.origin_unmapped_values(text, uuid, text)       from public, anon;
revoke execute on function public.entry_audit_log_fn()                           from public, anon, authenticated;
