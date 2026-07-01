# Endpoint: Histórico de vendas

> Referência: documentação Hotmart Developers — seção "Vendas" > "Histórico de vendas".

Exibe as informações das vendas realizadas na Hotmart. Para detalhes de participantes, comissões e divisão de valores, use os endpoints específicos da seção Vendas.

`GET /payments/api/v1/sales/history`

> **Atenção ao filtro de status.** Se você **não** informar `transaction` nem `transaction_status`, a API retorna **apenas os status `APPROVED` e `COMPLETE`**. Para outros status, é obrigatório passar esses filtros.

## Parâmetros da requisição (query)

> Datas em **milissegundos**, a partir de `1970-01-01 00:00:00 UTC`.

| Parâmetro | Descrição |
|---|---|
| `max_results` | Número máximo de itens por página. |
| `page_token` | Cursor de paginação. |
| `product_id` | ID do produto vendido (7 dígitos). |
| `start_date` | Data inicial do período (filtro). |
| `end_date` | Data final do período (filtro). |
| `sales_source` | Código SRC do link de pagamento (origem). Ex.: `pay.hotmart.com/B00000000T?src=nomedacampanha`. |
| `transaction` | Código único da transação (ex.: `HP17715690036014`). |
| `buyer_name` | Nome do comprador. |
| `buyer_email` | E-mail do comprador (útil para buscar compras de pessoas específicas). |
| `transaction_status` | Status da compra (valores abaixo). |
| `payment_type` | Tipo de pagamento (valores abaixo). |
| `offer_code` | Código de oferta do produto. |
| `commission_as` | Como o usuário foi comissionado: `PRODUCER`, `COPRODUCER`, `AFFILIATE`. |

### Valores de `transaction_status`

`APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, `PROTESTED`, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT`.

### Valores de `payment_type`

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/sales/history?transaction_status=APPROVED' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `product` | object | Dados do produto (`name`, `id`). |
| `buyer` | object | Dados do comprador (abaixo). Só retornados se o comprador disponibilizou no checkout. |
| `producer` | object | Dados do produtor (`name`, `ucode`). |
| `purchase` | object | Dados da compra (abaixo). |

### `buyer`

| Campo | Descrição |
|---|---|
| `name` | Nome do comprador. |
| `ucode` | Identificador único do comprador. |
| `email` | E-mail do comprador. |

### `purchase`

| Campo | Descrição |
|---|---|
| `transaction` | Código único da transação (ex.: `HP17715690036014`). |
| `order_date` | Data do pedido (ms). |
| `approved_date` | Data de aprovação (ms). |
| `status` | Status da compra (mesmos valores de `transaction_status`). |
| `recurrency_number` | Número da recorrência (compras parceladas no cartão ou Parcelamento Inteligente). |
| `is_subscription` | Se o pedido é do tipo assinatura. |
| `commission_as` | Como o usuário foi comissionado: `PRODUCER`, `COPRODUCER`, `AFFILIATE`. |
| `price` | Detalhes do valor (abaixo). |
| `payment` | Informações de pagamento (abaixo). |
| `tracking` | Códigos de rastreamento (abaixo). |
| `warranty_expire_date` | Data de vencimento da garantia (período para solicitar reembolso). |
| `offer` | Informações da oferta (abaixo). |
| `hotmart_fee` | Tarifas cobradas pela Hotmart (abaixo). |

#### `purchase.price`

| Campo | Descrição |
|---|---|
| `currency_code` | Moeda do valor base (3 letras: `BRL`, `USD`, `EUR`, `MXN`...). |
| `value` | Valor total pago pelo comprador, incluindo taxas e juros. |

#### `purchase.payment`

| Campo | Descrição |
|---|---|
| `method` | Método de pagamento (valores abaixo). |
| `installments_number` | Número total de parcelas (compra parcelada em BRL, MXN ou COP). |
| `type` | Tipo de pagamento (mesmos valores de `payment_type`). |

Valores de `payment.method`: `BACS_DIRECT_DEBIT`, `BALOTO`, `BANK_DEBIT`, `BILLET`, `CREDIT_CARD_AMERICAN_EXPRESS`, `CREDIT_CARD_AURA`, `CREDIT_CARD_DINERS`, `CREDIT_CARD_DISCOVER`, `CREDIT_CARD_ELO`, `CREDIT_CARD_HIPERCARD`, `CREDIT_CARD_MASTERCARD`, `CREDIT_CARD_VISA`, `CUPON_DE_PAGO`, `DIRECT_BANK_TRANSFER_ADYEN_SOFORT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT_ADYEN_ONEY`, `FINANCED_INSTALLMENT_ADYEN_ONEY_10X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_12X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_3X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_4X`, `FINANCED_INSTALLMENT_ADYEN_ONEY_6X`, `GOOGLE_PAY`, `HOTMART`, `HYBRID`, `IN_APP_PURCHASE`, `MULTIBANCO`, `OXXO`, `PAGO_EFECTIVO`, `PAYPAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `SEPA_DIRECT_DEBIT`, `BANK_TRANSFER_BB`, `BANK_TRANSFER_BRADESCO`, `BANK_TRANSFER_ITAU`, `APPLE_PAY`, `UNKNOWN_CREDIT_CARD`, `UNKNOWN`.

#### `purchase.tracking`

| Campo | Descrição |
|---|---|
| `source` | Código de rastreamento do campo `src` (origem cadastrada pelo vendedor). |
| `source_sck` | Código `sck` do produtor (exclusivo, identifica uma página de checkout). |
| `external_code` | Código de rastreamento do campo `xcod` na URL do checkout. |

#### `purchase.offer`

| Campo | Descrição |
|---|---|
| `payment_mode` | Modo de pagamento (valores abaixo). |
| `code` | Código identificador da oferta. |

Valores de `offer.payment_mode`: `SUBSCRIPTION`, `BILLET_INSTALLMENT`, `INVOICE`, `MULTIPLE_PAYMENTS`, `NOT_DEFINED`, `UNIQUE_PAYMENT`, `PAY_IN_FULL`, `SMART_INSTALLMENT`.

#### `purchase.hotmart_fee`

| Campo | Descrição |
|---|---|
| `fixed` | Tarifa fixa sobre a transação (na moeda da comissão). |
| `base` | Valor base usado para a cobrança da tarifa. |
| `percentage` | Percentual da tarifa sobre o valor base. |
| `total` | Tarifa total cobrada pela Hotmart (na moeda da comissão). |
| `currency_code` | Moeda do valor base (3 letras). |

### `page_info`

| Campo | Descrição |
|---|---|
| `total_results` | Total de itens da lista (pode não vir em todos os endpoints). |
| `next_page_token` | Referência da próxima página (ausente na última). |
| `prev_page_token` | Referência da página anterior (ausente na primeira). |
| `results_per_page` | Itens da página atual. |

## Exemplo de resposta (200 - Success)

```json
{
  "items": [
    {
      "product": {
        "name": "Product06",
        "id": 2125812
      },
      "buyer": {
        "name": "Ian Victor Baptista",
        "ucode": "839F1A4F-43DC-F60F-13FE-6C8BD23F6781",
        "email": "ian@teste.com"
      },
      "producer": {
        "name": "Bárbara Sebastiana Cardoso",
        "ucode": "252A74C5-4A97-143A-9349-E45D871C6018"
      },
      "purchase": {
        "transaction": "HP12455690122399",
        "order_date": 1622948400000,
        "approved_date": 1622948400000,
        "status": "UNDER_ANALISYS",
        "recurrency_number": 2,
        "is_subscription": false,
        "commission_as": "PRODUCER",
        "price": {
          "value": 235.76,
          "currency_code": "USD"
        },
        "payment": {
          "method": "BILLET",
          "installments_number": 1,
          "type": "BILLET"
        },
        "tracking": {
          "source_sck": "HOTMART_PRODUCT_PAGE",
          "source": "HOTMART",
          "external_code": "FD256D24-401C-7C93-284C-C5E0181CD5DB"
        },
        "warranty_expire_date": 1625022000000,
        "offer": {
          "payment_mode": "INVOICE",
          "code": "k2pasun0"
        },
        "hotmart_fee": {
          "total": 36.75,
          "fixed": 0,
          "currency_code": "EUR",
          "base": 11.12,
          "percentage": 9.9
        }
      }
    }
  ],
  "page_info": {
    "total_results": 14,
    "next_page_token": "eyJyb3dzIjo1LCJwYWdlIjozfQ==",
    "prev_page_token": "eyJyb3dzIjo1LCJwYWdlIjoxfQ==",
    "results_per_page": 5
  }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.
