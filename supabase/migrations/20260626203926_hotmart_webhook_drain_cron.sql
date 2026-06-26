-- ============================================================================
-- Cron de drenagem do webhook Hotmart (rede de segurança)
-- ----------------------------------------------------------------------------
-- A Edge `hotmart-webhook` deriva o evento inline (tempo real). Este cron é a
-- REDE: a cada 1 min reprocessa o que ficou pendente (processed_at IS NULL) — ex.
-- evento cujo apply inline falhou, ou que chegou enquanto o banco oscilava.
-- Diferente dos crons da Hotmart, é SQL puro (a lógica vive no banco), sem
-- net.http_post/Vault. drain_hotmart_webhook_events usa FOR UPDATE SKIP LOCKED,
-- então não corre risco de processar o mesmo evento que o apply inline.
--
-- APLICADA: 2026-06-26 (version 20260626203926)
-- ============================================================================

select cron.schedule('hotmart-webhook-drain', '* * * * *', $$
  select public.drain_hotmart_webhook_events(200);
$$);
