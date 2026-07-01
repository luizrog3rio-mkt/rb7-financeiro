-- APLICADA: 20260701001316
-- Auditoria 2026-06-30: o net_amount (liquido) de ~145 vendas BRL com afiliado estava inflado
-- (gravado como bruto-taxa, sem descontar o afiliado). Confirmado por inspecao read-only na API
-- Hotmart (modo inspect_commissions da edge): a linha PRODUCER (=o que o produtor recebe) =
-- bruto-taxa-afiliado-coproducao, e o banco guardava bruto-taxa. Ex.: HP4172399093 -> PRODUCER
-- 2243.39, banco tinha 2312.77 (diff = 69.38 = o afiliado). Causa: o mapSale do sync diario grava
-- net=bruto-taxa e re-clobbra por cima; a cron de comissao (PRODUCER) nao corrige todas as recentes
-- (teto 400/dia). Backfill: net = bruto-taxa-afi-cop (= o PRODUCER validado) SO nas erradas
-- (afiliado/coprod > 0 E net atual == bruto-taxa). + default 0 no net_amount pra o mapSale parar de
-- emitir net (fim do re-clobber; a edge v24 tira o net do mapSale e faz o refresh_commissions
-- deterministico PRODUCER-ou-formula). Aprovado pelo Luiz em 2026-06-30. Verificado: 292 corretas,
-- 0 erradas, HP417=2243; refresh_commissions=60 rodou 200/OK sem re-quebrar.
update public.hotmart_sales
set net_amount = round(gross_amount - hotmart_fee - coalesce(affiliate_commission,0) - coalesce(coproduction_commission,0), 2)
where coalesce(affiliate_commission,0) + coalesce(coproduction_commission,0) > 0
  and abs(net_amount - (gross_amount - hotmart_fee)) < 0.01;

alter table public.hotmart_sales alter column net_amount set default 0;
