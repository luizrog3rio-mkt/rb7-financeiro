---
name: rb7-financeiro-supabase
description: Projeto Supabase de produção do rb7-financeiro — ref, org, keys e decisões de setup
metadata:
  type: project
---

**⚠️ DECISÃO 2026-06-09 (Luiz): o rb7-financeiro será APOSENTADO.** Os dados dele são fictícios (só seed). O app sobrevivente é o **categorizador-fatura** (Supabase `qdnqghefwjpeiidjlzjy`, deploy Vercel, dados reais da Lívia: 3 faturas Sicoob, 519 transações categorizadas). As features/implementações do rb7 (lançamentos, contas, multi-empresa, Hotmart, hardening) serão portadas PARA o categorizador. Não há migração de dados — só schema/código. Ver [[unificacao-no-categorizador]].

Projeto Supabase criado em 2026-06-09: **rb7-financeiro**, ref `qnjjipkqjcmsmumcqltg`, org RB7 DIGITAL LTDA (`dsdlunrddmdugmdysows`), região sa-east-1. Repo local linkado via `supabase link`; migrations aplicadas com `supabase db push`.

**CLI removido da máquina (2026-06-09, a pedido do Luiz):** `supabase logout` + desinstalado o global do npm. Não há mais token em `~/.supabase/access-token`. Para operações futuras: usar `npx supabase ...` (baixa sob demanda) e pedir ao Luiz um access token novo (dashboard → Account → Access Tokens) via `$env:SUPABASE_ACCESS_TOKEN`; `db push` pede a senha do banco, que está com ele. Ver [[confirmar-antes-de-recursos-cloud]].

- `.env` local usa a key **publishable** (`sb_publishable_...`) em `VITE_SUPABASE_ANON_KEY` — funciona com supabase-js e é a recomendação atual; as keys legadas existem mas não são usadas.
- Usuário admin: luizrogerio@rb7digital.com.br (id `89f8006f-2a0e-4496-8ad5-44c7e8c8c278`), criado via Auth Admin API; senha temporária entregue ao usuário no chat de setup.
- Senha do banco foi rotacionada via Management API (`PATCH /v1/projects/{ref}/database/password`) — não existe comando no CLI pra isso.
- Decisões de hardening (migration `20260609180002`): coluna `perfis.papel` não-editável pelo app (privilégio de coluna, só `nome`); funções de trigger com `set search_path = ''` e EXECUTE revogado de anon/authenticated; HIBP leaked-password protection ligado, senha mínima 8.
- Avisos `rls_policy_always_true` dos advisors nas 6 tabelas de negócio são **design intencional** (equipe pequena: qualquer autenticado tem acesso total) — não "corrigir".
- Regra ESLint `react-hooks/set-state-in-effect` rebaixada pra `warn` (app inteiro usa fetch-on-mount); dívida técnica conhecida, ver [[ps51-encoding-gotchas]] para o ambiente.
