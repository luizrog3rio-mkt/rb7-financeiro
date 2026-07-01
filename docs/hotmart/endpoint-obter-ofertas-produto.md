# Endpoint: Obter Ofertas de Produto

> Referência: documentação Hotmart Developers — seção "Produto" > "Obter Ofertas de Produto".

Retorna informações detalhadas das ofertas de um produto: código, nome, descrição, valor, moeda, modo de pagamento, conversão de moeda, recuperação inteligente e se é a oferta principal.

`GET /products/api/v1/products/:ucode/offers`

## Parâmetros da requisição

| Local | Parâmetro | Descrição |
|---|---|---|
| Path | `ucode` | Identificador único (UUID) do produto (obtido via [Obter Produtos](./endpoint-obter-produtos.md)). |
| Query | `max_results` | Número máximo de itens por página. |
| Query | `page_token` | Cursor de paginação. |

### Requisição

```bash
curl --location 'https://developers.hotmart.com/products/api/v1/products/:ucode/offers' \
 --header 'Content-Type: application/json' \
 --header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `code` | string | Identificador único da oferta. |
| `name` | string | Nome de exibição da oferta. |
| `description` | string | Descrição detalhada da oferta. |
| `price` | object | Preço da oferta: `value` e `currency_code` (ex.: `BRL`, `USD`, `EUR`, `MXN`). |
| `payment_mode` | string | Modo de pagamento (valores abaixo). |
| `is_currency_conversion_enabled` | boolean | Se a conversão de moeda para vendas internacionais está habilitada. |
| `is_smart_recovery_enabled` | boolean | Se a oferta tem recuperação inteligente habilitada. |
| `is_main_offer` | boolean | Se é a oferta principal do produto. |

### Valores de `payment_mode`

`UNIQUE_PAYMENT`, `SUBSCRIPTION`, `MULTIPLE_PAYMENTS`, `PAY_IN_FULL`, `NOT_DEFINED`, `INVOICE`, `SMART_INSTALLMENT`, `BILLET_INSTALLMENT`, `FINANCED_BILLET`.

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
    "is_currency_conversion_enabled": true,
    "is_main_offer": true,
    "is_smart_recovery_enabled": false,
    "price": {
      "value": 10,
      "currency_code": "BRL"
    },
    "code": "02mhofjd",
    "description": "",
    "name": "",
    "payment_mode": "PAY_IN_FULL"
  }
 ],
 "page_info": {
   "next_page_token": "eyJwYWdlIjoyLCJzaXplIjoxOH0=",
   "prev_page_token": null,
   "results_per_page": 1
 }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox. Valores diferentes dos da tabela retornam erro **404**.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Success | `200` | `ucode` | `ab907e46-a9aa-4d25-ae4f-cec316d01560` |
