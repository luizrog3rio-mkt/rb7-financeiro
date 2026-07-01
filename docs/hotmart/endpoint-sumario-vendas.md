# Endpoint: Sumário de Vendas

> Referência: documentação Hotmart Developers — seção "Vendas" > "Sumário de vendas".

Exibe os valores de **comissões totalizados por moeda**.

`GET /payments/api/v1/sales/summary`

> **Atenção ao filtro de status.** Se você **não** informar `transaction` nem `transaction_status`, a API considera **apenas os status `APPROVED` e `COMPLETE`**.

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
| `affiliate_name` | Nome do Afiliado responsável pela venda (quando aplicável). |
| `payment_type` | Tipo de pagamento (valores abaixo). |
| `offer_code` | Código da oferta do produto. |
| `transaction` | Código único da transação (ex.: `HP17715690036014`). |
| `transaction_status` | Status da compra (valores abaixo). |

### Valores de `payment_type`

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

### Valores de `transaction_status`

`APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, `PROTESTED`, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/sales/summary?product_id=1234567' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `total_items` | long | Quantidade de comissões totalizadas. |
| `total_value` | object | Valor total das comissões por moeda (`currency_code`, `value`). |

### `total_value`

| Campo | Tipo | Descrição |
|---|---|---|
| `currency_code` | string | Código da moeda. |
| `value` | double | Valor total de comissões no período. |

### `page_info`

| Campo | Descrição |
|---|---|
| `total_results` | Total de itens da lista (pode não vir em todos os endpoints). |
| `next_page_token` | Referência da próxima página (ausente na última). |
| `prev_page_token` | Referência da página anterior (ausente na primeira). |
| `results_per_page` | Itens da página atual. |

### Exemplo de resposta (200 - Success)

```json
{
  "items": [
    {
      "total_items": 2,
      "total_value": {
        "value": 3.7,
        "currency_code": "USD"
      }
    }
  ],
  "page_info": {
    "total_results": 1,
    "results_per_page": 1
  }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `product_id` | `15434864` |
| | | `start_date` | `1623380400000` |
| | | `end_date` | `1623639600000` |
| | | `sales_source` | `campaignName6` |
| | | `affiliate_name` | `Regina Malu Aragão` |
| | | `payment_type` | `BILLET` |
| | | `offer_code` | `k0lphun9` |
