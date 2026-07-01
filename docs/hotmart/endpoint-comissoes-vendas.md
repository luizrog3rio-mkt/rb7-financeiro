# Endpoint: Comissões de Vendas

> Referência: documentação Hotmart Developers — seção "Vendas" > "Comissões de vendas".

Exibe as comissões **por participante** da venda — valores em moeda e a fonte de cada comissão.

`GET /payments/api/v1/sales/commissions`

> **Atenção ao filtro de status.** Se você **não** informar `transaction` nem `transaction_status`, a API retorna **apenas os status `APPROVED` e `COMPLETE`**.

## Parâmetros da requisição (query)

> Datas em **milissegundos**, a partir de `1970-01-01 00:00:00 UTC`.

| Parâmetro | Descrição |
|---|---|
| `max_results` | Número máximo de itens por página. |
| `page_token` | Cursor de paginação. |
| `product_id` | ID do produto vendido (7 dígitos). |
| `start_date` | Data inicial do período (filtro). |
| `end_date` | Data final do período (filtro). |
| `transaction` | Código único da transação (ex.: `HP17715690036014`). |
| `commission_as` | Como o usuário foi comissionado: `PRODUCER`, `COPRODUCER`, `AFFILIATE`. |
| `transaction_status` | Status da compra (valores abaixo). |

### Valores de `transaction_status`

`APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, `PROTESTED`, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/sales/commissions?product_id=123' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `transaction` | string | Código único da transação. |
| `product` | object | Dados do produto (`name`, `id`). |
| `exchange_rate_currency_payout` | double | Taxa de conversão usada para converter o valor de compra (sem impostos) no valor bruto da comissão, na moeda respectiva. **`1` quando não há conversão.** |
| `commissions` | array | Comissões por participante (abaixo). |

### `commissions[]`

| Campo | Descrição |
|---|---|
| `commission` | Valor da comissão: `currency_value` (moeda, 3 letras) e `value`. |
| `user` | Participante que recebe a comissão: `ucode`, `name`. |
| `source` | Fonte da comissão: `PRODUCER`, `COPRODUCER`, `AFFILIATE` ou `ADDON`. |

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
      "transaction": "HP12345678901234",
      "product": {
        "name": "Product Test",
        "id": 123456
      },
      "exchange_rate_currency_payout": 0.001334000000,
      "commissions": [
        {
          "commission": {
            "currency_value": "USD",
            "value": 95.00
          },
          "user": {
            "ucode": "1c2fbe3a-e4cb-56ec-b7e8-b9c0f1a234f4",
            "name": "Name User Producer Test"
          },
          "source": "PRODUCER"
        },
        {
          "commission": {
            "currency_value": "USD",
            "value": 4.35
          },
          "user": {
            "ucode": "1c2fbe3a-e4cb-56ec-b7e8-b9c0f1a234f5",
            "name": "Name User Coproducer Test"
          },
          "source": "COPRODUCER"
        },
        {
          "commission": {
            "currency_value": "USD",
            "value": 0.65
          },
          "user": {
            "ucode": "1c2fbe3a-e4cb-56ec-b7e8-b9c0f1a234f6",
            "name": "Name User Addon Test"
          },
          "source": "ADDON"
        }
      ]
    }
  ],
  "page_info": {
    "total_results": 10,
    "results_per_page": 10
  }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `start_date` | `1622689200000` |
| | | `end_date` | `1622948400000` |
