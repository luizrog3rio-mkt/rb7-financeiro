# Endpoint: Obter Compras de Assinantes

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Obter compras de assinantes".

Lista os pagamentos de recorrências vinculados a uma assinatura. Útil para métricas e operações sobre uma compra (ex.: reembolso).

`GET /payments/api/v1/subscriptions/:subscriber_code/purchases`

## Parâmetros da requisição (path)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subscriber_code` | sim | Código exclusivo de um assinante. |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/subscriptions/:subscriber_code/purchases' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer :access_token'
```

## Retorno

> O retorno é um **array direto** de compras (sem `items`/`page_info`).

| Campo | Tipo | Descrição |
|---|---|---|
| `transaction` | string | Código de referência da transação (ex.: `HP17715690036014`). |
| `approved_date` | date | Dia em que o pedido foi aprovado. |
| `payment_engine` | string | Plataforma de pagamento (ex.: HotPay, HotPay Internacional). |
| `status` | string | Status da compra (valores abaixo). |
| `price` | object | Dados do preço (`value`, `currency_code`). |
| `payment_type` | string | Tipo de pagamento (valores abaixo). |
| `payment_method` | string | Método de pagamento (valores abaixo). |
| `recurrency_number` | integer | Número da recorrência correspondente. |
| `under_warranty` | boolean | Se a transação está dentro do prazo de garantia. |
| `purchase_subscription` | boolean | Se a compra é referente a um produto de assinatura. |

### `price`

| Campo | Tipo | Descrição |
|---|---|---|
| `value` | double | Valor da transação. |
| `currency_code` | string | Moeda (padrão internacional de 3 letras: `BRL`, `USD`, `EUR`, `MXN`...). |

### Valores de `status`

`APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, `PROTESTED`, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT`.

### Valores de `payment_type`

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

### Valores de `payment_method`

`BACS_DIRECT_DEBIT`, `BALOTO`, `BANK_DEBIT`, `BILLET`, `CREDIT_CARD_AMERICAN_EXPRESS`, `CREDIT_CARD_AURA`, `CREDIT_CARD_DINERS`, `CREDIT_CARD_DISCOVER`, `CREDIT_CARD_ELO`, `CREDIT_CARD_HIPERCARD`, `CREDIT_CARD_MASTERCARD`, `CREDIT_CARD_VISA`, `CUPON_DE_PAGO`, `DIRECT_BANK_TRANSFER_ADYEN_SOFORT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT_ADYEN_ONEY`, `FINANCED_INSTALLMENT_ADYEN_ONEY_10X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_12X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_3X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_4X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_6X`, `GOOGLE_PAY`, `HOTMART`, `HYBRID`, `IN_APP_PURCHASE`, `MULTIBANCO`, `OXXO`, `PAGO_EFECTIVO`, `PAYPAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `SEPA_DIRECT_DEBIT`, `BANK_TRANSFER_BB`, `BANK_TRANSFER_BRADESCO`, `BANK_TRANSFER_ITAU`, `APPLE_PAY`.

### Exemplo de resposta (200 - Success)

```json
[
  {
    "transaction": "HP12315823516751",
    "approved_date": 1583331578000,
    "payment_engine": "HotPay",
    "status": "APPROVED",
    "price": {
      "value": 108.0,
      "currency_code": "BRL"
    },
    "payment_type": "CREDIT_CARD",
    "payment_method": "VISA_CREDIT_CARD",
    "recurrency_number": 1,
    "under_warranty": false,
    "purchase_subscription": true
  }
]
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox. Como os dados são fictícios, use os valores abaixo para obter cada cenário:

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subscriber_code` | `B2HNQAXJ` |
| Assinatura não foi encontrada | `404` | `subscriber_code` | `X53ZPFQZ` |
