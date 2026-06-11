-- ============================================================================
-- Move pg_net do schema public pro extensions (advisor 0014 extension_in_public)
-- ============================================================================
-- APLICADA em 2026-06-10 (version vivo 20260611021420). Verificada: pg_net em
-- extensions, advisor 0014 limpo, net.http_post→função respondeu (cron vivo).
-- A enable_cron_net instalou o pg_net sem especificar schema → caiu no public
-- (deslize; pg_cron foi pro pg_catalog sozinho). A API do pg_net vive no schema
-- `net` independente do schema de instalação (verificado: net.http_post
-- funcionou com a extensão em public), então mover NÃO quebra o cron — o job
-- hotmart-sync-diario referencia net.http_post por texto, reavaliado a cada
-- execução. A fila net._http_response é recriada vazia (transiente, ok).
-- ============================================================================

drop extension pg_net;
create extension pg_net with schema extensions;
