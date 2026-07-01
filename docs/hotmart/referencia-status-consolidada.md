# Referência consolidada — Status e Enums

> Mapa de reconciliação dos valores de status/enum usados na API Hotmart. Vários conceitos têm **grafias diferentes conforme o endpoint/evento** — esta página existe para você não fazer match exato de string e quebrar.

## 1. Status de assinatura

O mesmo conceito de status aparece com **grafias diferentes** dependendo da fonte. Valores literais por fonte:

| Fonte | Valores |
|---|---|
| [Obter Assinaturas](./endpoint-obter-assinaturas.md) (REST) e [Webhook Eventos de pedidos](./webhook-eventos-pedido.md) (`subscription.status`) | `ACTIVE`, `INACTIVE`, `DELAYED`, `CANCELLED_BY_CUSTOMER`, `CANCELLED_BY_SELLER`, `CANCELLED_BY_ADMIN`, `STARTED`, `OVERDUE` |
| [Webhook Troca de plano](./webhook-evento-troca-plano.md) e [Webhook Troca do dia de cobrança](./webhook-evento-troca-dia-cobranca.md) | `ACTIVE`, `INACTIVE`, `CANCELED_BY_CUSTOMER`, `CANCELED_BY_VENDOR`, `CANCELED_BY_ADMIN`, `OVERDUE`, `STARTED`, `EXPIRED` |
| [Tutorial — Dados de assinaturas via webhook](./webhook-dados-assinaturas.md) | `PAST_DUE` (atrasada), `INACTIVE` (adesão não aprovada), `EXPIRED` (não renovada) |
| [Introdução Assinaturas](./assinaturas-introducao.md) (nomes de exibição PT) | Ativa, Atrasada, Inativa, Vencida, Cancelada pelo Cliente/Vendedor/Administrador |

### ⚠️ Diferenças que quebram match exato

- **Grafia `CANCELLED` vs `CANCELED`:** REST e Eventos de pedidos usam dois "L" (`CANCELLED_BY_*`); Troca de plano e Troca do dia de cobrança usam um "L" (`CANCELED_BY_*`).
- **`SELLER` vs `VENDOR`:** o cancelamento pelo produtor é `CANCELLED_BY_SELLER` (REST/pedidos) **ou** `CANCELED_BY_VENDOR` (troca de plano/dia).
- **Atrasada:** aparece como `DELAYED` (REST/pedidos) ou `PAST_DUE` (tutorial dados de assinaturas).
- **Vencida/expirada:** `EXPIRED` aparece em troca de plano/dia e no tutorial, mas **não** na lista de Obter Assinaturas (que traz `OVERDUE` e `DELAYED`).

> **Recomendação:** normalize os status numa camada própria (ex.: mapeie `CANCELLED_BY_SELLER` e `CANCELED_BY_VENDOR` para um único `CANCELED_BY_SELLER` interno) antes de usar na sua lógica.

## 2. Status de compra / transação

| Fonte | Valores |
|---|---|
| [Histórico de vendas](./endpoint-historico-vendas.md) (`transaction_status`) | `APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, **`PROTESTED`**, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT` |
| [Webhook Eventos de pedidos](./webhook-eventos-pedido.md) (`purchase.status`) | `APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, **`DISPUTE`**, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT` |

### ⚠️ Diferenças

- **`PROTESTED` (vendas) vs `DISPUTE` (webhook)** para o mesmo conceito de contestação. As demais 16 entradas são idênticas.
- **`UNDER_ANALISYS`** é grafado **literalmente assim** (com "I", não `UNDER_ANALYSIS`) nas duas fontes. Use o valor exato.

## 3. Nomes de evento do webhook (`event`)

| Evento | Significado |
|---|---|
| `PURCHASE_APPROVED` | Compra aprovada |
| `PURCHASE_COMPLETE` | Compra completa |
| `PURCHASE_CANCELED` | Compra cancelada |
| `PURCHASE_DELAYED` | Compra atrasada |
| `PURCHASE_EXPIRED` | Compra expirada |
| `PURCHASE_REFUNDED` | Reembolso |
| `PURCHASE_CHARGEBACK` | Chargeback |
| `PURCHASE_PROTEST` | Contestação |
| `PURCHASE_BILLET_PRINTED` | Boleto impresso/gerado |
| `SUBSCRIPTION_CANCELLATION` | Cancelamento de assinatura |
| `SWITCH_PLAN` | Troca de plano |
| `UPDATE_SUBSCRIPTION_CHARGE_DATE` | Troca do dia de cobrança |
| `PURCHASE_OUT_OF_SHOPPING_CART` | Abandono de carrinho |
| `CLUB_FIRST_ACCESS` | Primeiro acesso ao curso |
| `CLUB_MODULE_COMPLETED` | Módulo concluído |
| `ORDER_FULFILLMENT` | Dado logístico (produto físico) |

> O evento `PURCHASE_CANCELED` é grafado com um "L" (CANCELED). Note que isso difere do status de assinatura `CANCELLED_*` (dois "L") em algumas fontes.

## 4. `payment_mode` — inglês (Ofertas) vs português (Planos)

O **modo de pagamento** muda de idioma conforme o endpoint:

| Conceito | [Obter Ofertas](./endpoint-obter-ofertas-produto.md) (EN) | [Obter Planos](./endpoint-obter-planos-produto.md) (PT) |
|---|---|---|
| Pagamento único | `UNIQUE_PAYMENT` | `PAGAMENTO_UNICO` |
| Assinatura | `SUBSCRIPTION` | `ASSINATURA` |
| Múltiplos pagamentos | `MULTIPLE_PAYMENTS` | `MULTIPLOS_PAGAMENTOS` |
| Pagamento à vista | `PAY_IN_FULL` | `PAGAMENTO_VISTA` |
| Não definido | `NOT_DEFINED` | `NOT_DEFINED` |
| Fatura | `INVOICE` | `INVOICE` |
| Smart Installment | `SMART_INSTALLMENT` | `SMART_INSTALLMENT` |
| Parcelamento de boleto | `BILLET_INSTALLMENT` | `BILLET_INSTALLMENT` |
| Boleto financiado | `FINANCED_BILLET` | *(não listado em Planos)* |

## 5. `payment.type` — forma de pagamento real

Usado em vendas e no webhook de pedidos (`purchase.payment.type`):

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

> `PAYPAL_INTERNACIONAL` é grafado com "C" (mistura PT/EN) — use o valor exato.

## 6. Periodicidade de assinatura

Há **duas representações** da periodicidade:

| Conceito | Numérico (`recurrency_period` / `interval_between_charges`) | String (`periodicity` em Planos) |
|---|---|---|
| Semanal | `7` | `WEEKLY` |
| Mensal | `30` | `MONTHLY` |
| Bimestral | `60` | `BIMONTHLY` |
| Trimestral | `90` | `QUARTERLY` |
| Semestral | `180` | `BIANNUAL` |
| Anual | `360` | `ANNUAL` |
| Parcela única | — | `SINGLE_INSTALLMENT` |

> Em Planos, `BIANNUAL` é usado para **semestral** (6 meses) e `ANNUAL` para anual.

## 7. Status de ingresso de evento (`ticket_status`)

[Lista de ingressos e participantes](./endpoint-lista-ingressos-participantes.md):

`SOLD` (pago/confirmado), `INVITE` (convite enviado), `INVITE_CANCELED` (convite removido), `REFUNDED` (reembolsado), `CHARGEBACK`, `EXCLUDED` (excluído), `AVAILABLE` (não atribuído), `RESERVED` (pagamento pendente ou convite atribuído).

## 8. Status de cupom

[Obter Cupom](./endpoint-obter-cupom.md) usa `status` em **minúsculas** (ex.: `valid`) — diferente de todos os outros enums em MAIÚSCULAS.

## 9. Fonte de comissão (`commissions.source`)

`PRODUCER`, `COPRODUCER`, `AFFILIATE`, `ADDON` — e `MARKETPLACE` aparece no exemplo de payload do [Webhook Eventos de pedidos](./webhook-eventos-pedido.md), embora não conste na lista descritiva.

---

### Resumo dos "tropeços" mais perigosos

1. `CANCELLED_*` (2 L) vs `CANCELED_*` (1 L) e `SELLER` vs `VENDOR` no status de assinatura.
2. `PROTESTED` (vendas) vs `DISPUTE` (webhook) no status de compra.
3. `UNDER_ANALISYS` e `PAYPAL_INTERNACIONAL` com grafia "errada" mas literal.
4. `payment_mode` em inglês (Ofertas) vs português (Planos).
5. `date_next_charge` em **ms** na maioria dos webhooks, mas em **string ISO** no de troca do dia de cobrança.
6. Status de cupom em minúsculas.
