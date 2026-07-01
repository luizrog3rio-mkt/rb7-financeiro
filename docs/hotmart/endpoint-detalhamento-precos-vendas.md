# Endpoint: Detalhamento de preços de vendas

> Referência: documentação Hotmart Developers — seção "Vendas" > "Detalhamento de preços de vendas".

Exibe o detalhamento dos valores da compra — valor total, valor base para comissão, impostos, cupons de desconto, juros, entre outros.

`GET /payments/api/v1/sales/price/details`

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
| `transaction_status` | Status da transação (valores abaixo). |
| `payment_type` | Tipo de pagamento (valores abaixo). |

### Valores de `transaction_status`

`STARTED`, `COMPLETE`, `PRINTED_BILLET`, `WAITING_PAYMENT`, `APPROVED`, `UNDER_ANALISYS`, `CANCELLED`, `PROTESTED`, `REFUNDED`, `CHARGEBACK`, `BLOCKED`, `OVERDUE`, `EXPIRED`, `PARTIALLY_REFUNDED`.

### Valores de `payment_type`

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/sales/price/details?transaction_status=CANCELLED&payment_type=CREDIT_CARD' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

Cada objeto de valor abaixo tem o par `currency_code` (moeda, 3 letras) + `value`.

| Campo | Descrição |
|---|---|
| `transaction` | Código único da transação. |
| `product` | Dados do produto (`name`, `id`). |
| `base` | Valor base — usado para a divisão de comissão entre produtor, afiliados e coprodutores; dele são retiradas as taxas dos addons. |
| `total` | Preço total — composição de `base` + `vat` + `fee`. |
| `vat` | VAT (Value Added Tax) — imposto sobre o valor agregado. **Cobrado apenas em vendas no território europeu e mexicano.** |
| `fee` | Juros de compra parcelada em BRL ou MXN. Pago pelo produtor **ou** pelo comprador, conforme a config do produto. |
| `coupon` | Cupom de desconto, se aplicado: `code` e `value` (porcentagem entre 0 e 1). |
| `real_conversion_rate` | Taxa de conversão do valor original da oferta para a moeda local do comprador. |

## Exemplo de resposta (200 - Success)

```json
{
  "items": [
    {
      "transaction": "HP14916251567230",
      "product": {
        "id": 8547854,
        "name": "product1"
      },
      "base": {
        "value": 930,
        "currency_code": "MXN"
      },
      "total": {
        "value": 486.25,
        "currency_code": "MXN"
      },
      "vat": {
        "value": 193.25,
        "currency_code": "BRL"
      },
      "fee": {
        "value": 55,
        "currency_code": "USD"
      },
      "coupon": {
        "code": "coupon1",
        "value": 22.9
      },
      "real_conversion_rate": 708.75
    }
  ],
  "page_info": {
    "total_results": 14,
    "next_page_token": "eyJyb3dzIjoxMCwicGFnZSI6Mn0=",
    "results_per_page": 10
  }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `start_date` | `1623726000000` |
| | | `end_date` | `1624158000000` |
