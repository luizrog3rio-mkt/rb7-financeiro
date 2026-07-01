# Endpoint: Transações de Assinatura

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Transações de Assinatura".

Fornece o detalhamento de cada transação de **Assinaturas**, **Smart Installments** e **Smart Recovery** — recorrência, histórico, detalhes de pagamento e previsão de liberação.

`GET /payments/api/v1/subscriptions/transactions`

> **Importante:**
> - Os dados têm **defasagem de até 24h**. Para tempo real, use [Obter Assinaturas](./endpoint-obter-assinaturas.md).
> - Por padrão, retorna os **últimos 30 dias** (exceto ao filtrar por `transaction`). Use `transaction_date` / `end_transaction_date` para customizar o período.

Os três tipos de cobrança recorrente (`SUBSCRIPTION`, `SMART_INSTALLMENT`, `SMART_RECOVERY`) são mutuamente exclusivos por `subscription_id` — ver [Sumário de Assinaturas](./endpoint-sumario-assinaturas.md) para a descrição de cada um.

## Parâmetros da requisição (query)

> Datas em **milissegundos**, a partir de `1970-01-01 00:00:00 UTC`.

| Parâmetro | Descrição |
|---|---|
| `max_results` | Número máximo de itens por página. |
| `page_token` | Cursor de paginação. |
| `product_id` | ID do produto vendido (7 dígitos). |
| `transaction` | Código único da transação (ex.: `HP17715690036014`). |
| `subscriber_name` | Nome do comprador. |
| `subscriber_email` | E-mail do comprador. |
| `billing_type` | `SUBSCRIPTION`, `SMART_INSTALLMENT` ou `SMART_RECOVERY`. |
| `subscription_status` | Situação atual da assinatura/compra (valores abaixo). |
| `recurrency_status` | Situação do pagamento da recorrência: `PAID`, `NOT_PAID`, `CLAIMED`, `REFUNDED`, `CHARGEBACK`. |
| `purchase_status` | Situação da transação de compra. |
| `transaction_date` | Data inicial do período (filtro). |
| `end_transaction_date` | Data final do período (filtro). |
| `offer_code` | Chave da oferta (pode mudar se o plano mudar). |
| `purchase_payment_type` | Tipo de pagamento (valores abaixo). |
| `subscriber_code` | Identificador único do assinante. |

### Valores de `subscription_status`

**Para Assinatura (`SUBSCRIPTION`):**

| Status | Significado |
|---|---|
| `STARTED` | Iniciada — gerou a cobrança da 1ª recorrência, pagamento ainda não confirmado. |
| `INACTIVE` | Inativa — 1ª recorrência sem pagamento confirmado e vencida. |
| `ACTIVE` | Ativa — última recorrência em dia e dentro do período vigente. (Atraso anterior "perdoado" se voltou a pagar recorrência posterior.) |
| `DELAYED` | Atrasada — última recorrência atrasada, ainda no período vigente. |
| `CANCELLED_BY_ADMIN` | Cancelada pela Equipe de Suporte Hotmart. |
| `CANCELLED_BY_CUSTOMER` | Cancelada pelo assinante. |
| `CANCELLED_BY_SELLER` | Cancelada pelo Produtor/colaborador. |
| `OVERDUE` | Vencida — acabou o período de duração. **Não é possível reativar o mesmo id**; renovação exige um novo. |

> Na 1ª recorrência, reembolso ou chargeback sempre cancela a assinatura.

**Para Smart Installment / Smart Recovery:**

| Status | Significado |
|---|---|
| `STARTED` | Iniciada — 1ª recorrência gerada, pagamento não confirmado. |
| `INACTIVE` | Inativa — 1ª recorrência sem pagamento confirmado e vencida. |
| `ACTIVE` | Todas as recorrências cobradas até o momento foram pagas. |
| `DELAYED` | Atrasada — deixou de pagar alguma recorrência (diferente da assinatura: mesmo com a última paga, se houver anterior não paga, fica atrasada). |
| `CANCELLED_BY_ADMIN` | Cancelada pela Equipe de Suporte Hotmart. |
| `CANCELLED_BY_SELLER` | Cancelada pelo Produtor/colaborador. |

### Valores de `purchase_payment_type`

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/subscriptions/transactions?transaction_date=1262354400000&end_transaction_date=1735830000000&max_results=500' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

### Campos de topo

| Campo | Descrição |
|---|---|
| `subscription_id` | Código único numérico da assinatura. |
| `last_update` | Data da última atualização da transação. |
| `subscriber_code` | Código alfanumérico Assinatura-Assinante (um comprador pode ter vários). |
| `status` | Situação atual da assinatura. |
| `billing_type` | `SUBSCRIPTION`, `SMART_INSTALLMENT` ou `SMART_RECOVERY`. |
| `adoption_date` | Data/hora da solicitação de adesão. Existe inclusive em `STARTED`/`INACTIVE`. Diferente da data de ativação. |
| `date_next_charge` | Data agendada da próxima cobrança. |
| `last_recurrency_start_date` | Data/hora de início da última recorrência. Vigentes (`ACTIVE`/`DELAYED`): 1ª transação da recorrência atual; demais: recorrência máxima do histórico. |
| `cancellation_date` | Data/hora do cancelamento. Fica nula se reativada (possível enquanto não Vencida). |
| `max_cycles` | Máximo de recorrências do Produto-Plano. Se ausente, cobra até cancelar. |
| `last_recurrency_number` | Número da última recorrência (mesma regra do Sumário: `CANCELLED`/`OVERDUE`→final, `STARTED`/`INACTIVE`→1ª, `ACTIVE`/`DELAYED`→atual). |
| `has_unpaid_recurrency` | `true` se a assinatura tem qualquer recorrência "NÃO PAGA" (aplica-se a todas as linhas da assinatura). |
| `has_credit_card_change` | `true` se a cobrança foi suspensa por restrições na forma de pagamento. |
| `is_paid_anticipation` | `true` se possui transação de antecipação paga. |
| `is_paid_negotiation` | `true` se possui transações de negociação paga. |

### `product`

| Campo | Descrição |
|---|---|
| `id` | Código do produto vendido. |
| `name` | Nome do produto. |

### `trial_info`

| Campo | Descrição |
|---|---|
| `trial` | `true` se teve período de trial. |
| `trial_period` | Duração do trial em dias. |
| `trial_end` | Data do fim do trial (usada no cálculo da análise de última recorrência). |

### `plan`

| Campo | Descrição |
|---|---|
| `name` | Nome da assinatura. |
| `recurrency_period` | Frequência de cobrança em dias (ex.: 30, 360). Padrão `30` se não houver plano. |
| `recurrency_type` | Frequência de faturamento (mensal, anual etc.). Padrão Mensal se não houver plano. |
| `coupon_code` | Código de cupom. Preenchido em recorrência de antecipação (`transaction_type = ANTICIPATION`). |
| `offer` | Dados da oferta: `code`, `description`, `key`. |

### `recurrency`

| Campo | Descrição |
|---|---|
| `status` | Situação do pagamento da recorrência: `PAID`, `NOT_PAID`, `CLAIMED`, `REFUNDED`, `CHARGEBACK`. |
| `number` | Número sequencial da recorrência (incrementa conforme a periodicidade). |
| `start_datetime` | Início da recorrência (= data de vencimento / 1ª transação de cobrança). |
| `payment_delay_days` | Dias sem pagamento, da última ordem de transação até hoje. |
| `transaction_type` | `AUTOMATIC`, `ANTICIPATION` ou `NEGOTIATION`. |
| `number_list` | Lista de números de recorrência antecipada/negociada (separados por vírgula). |
| `transaction_sequence` | Enumera as transações da mesma assinatura-recorrência por data-hora (inicia em 1). |
| `is_current_purchase` | Indica a compra atual da recorrência. Recorrência com compra paga = 1; senão, a última gerada (mais recente) = 1. |
| `has_retry` | `true` se já houve retentativas automáticas. *Até 4 retentativas quando a 1ª transação é recusada com `CREDIT_CARD`, `APPLE_PAY`, `GOOGLE_PAY` ou `PAYPAL`.* |
| `scheduled_retry` | Data/hora da próxima retentativa automática, se programada. |

### `purchase`

| Campo | Descrição |
|---|---|
| `transaction` | Identificação alfanumérica da transação de compra. |
| `order_date` | Data/hora da transação de compra. |
| `approved_date` | Data/hora da confirmação do pagamento. |
| `status` | Situação da transação (valores abaixo). |
| `payment` | Dados de pagamento (abaixo). |
| `installment` | Dados de parcelamento (abaixo). |
| `price` | Dados de preço (abaixo). |
| `commission` | Dados de comissão (abaixo). |

#### Valores de `purchase.status`

| Status | Significado |
|---|---|
| `APPROVED` | Pagamento realizado com sucesso. |
| `COMPLETE` | Pagamento aprovado e prazo de garantia encerrado (sem reembolso possível). |
| `STARTED` | Compra iniciada, pagamento ainda não reconhecido (comum em assinatura/cartão de débito). |
| `UNDER_ANALYSIS` | Compra em análise pelo meio de pagamento (comum em cartão de crédito/PayPal). |
| `WAITING_PAYMENT` | Cobrança cash payment (Pix, Picpay, Baloto) ainda não vencida. |
| `PRINTED_BILLET` | Boleto emitido e ainda não vencido. |
| `DELAYED` | A partir da 2ª recorrência, pagamento não confirmado ou com falha. |
| `PARTIALLY_REFUNDED` | Reembolso parcial liberado e em processamento. Irreversível. |
| `REFUNDED` | Reembolso finalizado (valor não recuperável). Na 1ª recorrência, cancela a assinatura. |
| `PROTESTED` | Estado de transição após solicitação de reembolso (pode virar Reembolsado ou voltar a Aprovado). |
| `CANCELLED` | Para assinaturas: cobrança de adesão instantânea com falha. Outros tipos: todas as transações com falha. |
| `CHARGEBACK` | Comprador solicitou devolução à operadora do cartão. Na 1ª recorrência, cancela a assinatura. |
| `EXPIRED` | Transação de adesão com pagamento não instantâneo (boleto/pix) que venceu sem ser paga. |

#### `purchase.payment`

| Campo | Descrição |
|---|---|
| `payment_type` | Forma de pagamento (cartão, boleto, pix, saldo Hotmart etc.). |
| `credit_card_flag` | Bandeira do cartão informada no checkout. |
| `refusal_message` | Motivo da recusa (valores abaixo). |
| `refund_chargeback_date` | Data/hora do reembolso/chargeback (quando aplicável). |
| `pix_expiration_date` | Validade do código Pix gerado. |
| `billet_expiration_date` | Vencimento do boleto. |
| `billet_reprint_code` | URL do boleto para reconsulta. |
| `billet_recovery_type` | Em recuperação por boleto: `AUTOMATIC` ou `MANUAL`. |

Valores de `refusal_message`: `INSUFFICIENT FUNDS`, `TRANSACTION DECLINED`, `CARD ISSUER UNAVAILABLE`, `CARD HAS NOT BEEN UNBLOCKED BY THE CARDHOLDER`, `CARD DETAILS NOT PROVIDED`, `INVALID SECURITY CODE`, `INVALID CARD EXPIRY DATE`, `INVALID CARD NUMBER`, `INVALID CARD DATA`, `INVALID AMOUNT`, `INVALID CARD`, `RESTRICTED CARD`, `ERROR NOT IDENTIFIED`, `CARD EXPIRED`, `DEBIT CARD IS NOT ENABLED FOR THE OPERATION`, `CARD DOES NOT SUPPORT INSTALLMENT PURCHASES`, `INVALID NUMBER OF INSTALLMENTS`, `THIS SESSION HAS ALREADY BEEN STARTED`, `DUPLICATE TRANSACTION`.

#### `purchase.installment`

| Campo | Descrição |
|---|---|
| `installment_type` | `CONVENTIONAL_INSTALLMENT` (tradicional), `SMART_INSTALLMENT`, `SMART_RECOVERY` ou `ONE_TIME_PAYMENT` (à vista). |
| `installment_number` | Quantidade de parcelas por recorrência (quando periodicidade > mensal). |

#### `purchase.price`

| Campo | Descrição |
|---|---|
| `currency` | Moeda do pagamento da adesão (usada por toda a vigência). |
| `value` | Valor total cobrado pela recorrência. |
| `total_value` | Valor total da compra, incluindo taxas de parcelamento e impostos. |

#### `purchase.commission`

| Campo | Descrição |
|---|---|
| `conversion_rate` | Taxa de conversão da moeda da compra para a moeda da comissão. |
| `currency` | Moeda da comissão (pode mudar durante a vigência — gera uma linha por moeda). |
| `original_value` | Comissão total prevista da venda (independe de pagamento), convertida para a moeda de comissão. |
| `original_paid_value` | Valor pago pelo comprador convertido para a moeda de comissão (status Aprovado/Completo). Zerado em reembolso/chargeback. |
| `producer_value` | Valor previsto de comissão do produtor (independe de pagamento). |
| `producer_paid_value` | Valor real de comissão do produtor (transações pagas, sem reembolso/chargeback). Independe da data de liberação para saque. |

### `subscriber`

| Campo | Descrição |
|---|---|
| `id` | ID numérico único do comprador na Hotmart. |
| `name` | Nome do comprador. |
| `email` | E-mail informado na compra. |
| `phone_ddd` | DDD do telefone informado na compra. |
| `phone` | Telefone informado na compra. |

### `producer`

| Campo | Descrição |
|---|---|
| `name` | Nome do produtor. |

### `page_info`

| Campo | Descrição |
|---|---|
| `next_page_token` | Referência da próxima página (ausente na última). |
| `prev_page_token` | Referência da página anterior (ausente na primeira). |
| `results_per_page` | Itens da página atual. |

## Exemplo de resposta (200 - Success)

```json
{
  "items": [
    {
      "last_recurrency_start_date": 1694113403000,
      "has_unpaid_recurrency": false,
      "product": {
        "name": "Product A",
        "id": 1001
      },
      "subscriber": {
        "phone": "1234567890",
        "name": "Subscriber A",
        "id": 10001,
        "phone_ddd": "12",
        "email": "subscriberA@example.com"
      },
      "recurrency": {
        "number": 1,
        "scheduled_retry": 1534204800000,
        "number_list": "3, 4",
        "transaction_sequence": 1,
        "start_datetime": 1694113403000,
        "payment_delays_days": 0,
        "transaction_type": "RECURRING",
        "is_current_purchase": true,
        "has_retry": false,
        "status": "PAID"
      },
      "last_recurrency_number": 1,
      "trial_info": {
        "trial_end": 1696705403000,
        "trial_period": 30,
        "trial": true
      },
      "purchase": {
        "order_date": 1577890800000,
        "price": {
          "total_value": 29.99,
          "currency": "USD",
          "value": 29.99
        },
        "installment": {
          "installment_number": 1,
          "installment_type": "MONTHLY"
        },
        "payment": {
          "refusal_message": "INSUFFICIENT FUNDS",
          "refund_chargeback_date": 1558051200000,
          "payment_type": "CREDIT_CARD",
          "billet_expiration_date": 1639008000000,
          "billet_recovery_type": "MANUAL",
          "pix_expiration_date": 1639008000000,
          "billet_reprint_code": "https://www.boletobancario.com/boletofacil/charge/boleto.html?token=9986502:m:4d70d7725a589dcc2351b8f13fa3066ccd87fc191f2190723666c5de4ae4832e",
          "credit_card_flag": "VISA"
        },
        "commission": {
          "original_value": 29.99,
          "producer_paid_value": 20.0,
          "currency": "USD",
          "original_paid_value": 29.99,
          "conversion_rate": 1.0,
          "producer_value": 20.0
        },
        "approved_date": 1577890800000,
        "transaction": "TXN000001",
        "status": "APPROVED"
      },
      "cancellation_date": 1536883200000,
      "is_paid_anticipation": false,
      "max_cycles": 12,
      "adoption_date": 1694113403000,
      "subscriber_code": "SUB000001",
      "date_next_charge": 1696705403000,
      "is_paid_negotiation": false,
      "last_update": 1577890800000,
      "billing_type": "SUBSCRIPTION",
      "producer": {
        "name": "Producer A"
      },
      "subscription_id": 1,
      "has_credit_card_change": false,
      "plan": {
        "offer": {
          "code": "OFFER_CODE_A",
          "description": "Offer A",
          "key": "OFFER_KEY_A"
        },
        "recurrency_period": 30,
        "coupon_code": "COUPON001",
        "recurrency_type": "MONTHLY",
        "name": "Plan A"
      },
      "status": "ACTIVE"
    }
  ],
  "page_info": {
    "results_per_page": 1,
    "next_page_token": "05b60506b659c1c6e728db93eada6271e3adcfb4edf507b679874458e31577b3",
    "prev_page_token": "cf1fg8bd082e2864069035c057eca0bac7eb5d604719c5a76e80f0933f49c217"
  }
}
```
