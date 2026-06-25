-- ============================================================================
-- Migration: novo tipo de conta "Conta caixa" (cash)
-- APLICADA em 2026-06-25 via MCP apply_migration — version 20260625185947
-- (renomeada do placeholder 20260625000001). Enum pós-apply:
-- checking, cash, credit_card, inter_company.
-- ----------------------------------------------------------------------------
-- Adiciona 'cash' ao enum public.account_type. Conta caixa = dinheiro em
-- espécie: sem OFX, saldo = saldo inicial + lançamentos pagos (as RPCs
-- account_balances/account_ledger já tratam tudo que não é 'checking com OFX'
-- por esse caminho — sem mudança). Aditiva e backward-compatible (o frontend
-- antigo ignora o valor novo).
-- ============================================================================

alter type public.account_type add value if not exists 'cash' after 'checking';
