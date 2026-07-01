# Endpoint: Obter Cupom

> Referência: documentação Hotmart Developers — seção "Cupons de desconto" > "Obter Cupom".

Obtém as informações dos cupons de um produto (código, valor do desconto, validade, fuso horário etc.). É possível filtrar por código de cupom.

`GET /products/api/v1/coupon/product/:product_id`

## Parâmetros da requisição

### Path

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `product_id` | sim | ID do produto vinculado ao cupom (7 dígitos). Obtido via [Obter Produtos](./endpoint-obter-produtos.md). |

### Query

| Parâmetro | Descrição |
|---|---|
| `code` | Filtra por código de cupom. |
| `page_token` | Cursor de paginação. |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/products/api/v1/coupon/product/:product_id?code=:code&page_token=:page_token' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | integer | Identificador único do cupom. |
| `coupon_code` | string | Código do cupom. |
| `discount` | double | Desconto como **fração** (ex.: `0.1` = 10%). |
| `start_date` | integer | Data de início da validade (ms desde 1970-01-01 UTC). |
| `status` | string | Status de validade do cupom (ex.: `valid`). |
| `active` | boolean | Se o cupom está ativo. |
| `time_zone` | object | Fuso horário (abaixo). |

### `time_zone`

| Campo | Descrição |
|---|---|
| `description` | Descrição do fuso (ex.: `Fuso horário de Brasília`). |
| `id` | Região do fuso (ex.: `America/Sao_Paulo`). |
| `name` | Nome da região (ex.: `AMERICA_SAO_PAULO`). |
| `offset` | Offset GMT (ex.: `-03:00`). |

### `page_info`

| Campo | Descrição |
|---|---|
| `next_page_token` | Referência da próxima página (ausente na última). |
| `prev_page_token` | Referência da página anterior (ausente na primeira). |
| `results_per_page` | Itens da página atual. |

## Exemplo de resposta (200)

```json
{
  "page_info": {
    "next_page_token": "05b60506b659c1c6e728db93eada6271e3adcfb4edf507b679874458e31577b3",
    "prev_page_token": "cf1fg8bd082e2864069035c057eca0bac7eb5d604719c5a76e80f0933f49c217",
    "results_per_page": 20
  },
  "items": [
    {
      "coupon_code": "couponCode",
      "active": true,
      "start_date": 16806975000,
      "discount": 0.1,
      "time_zone": {
        "offset": "-03:00",
        "description": "Fuso horário de Brasília",
        "id": "America/Sao_Paulo",
        "name": "AMERICA_SAO_PAULO"
      },
      "status": "valid",
      "id": 123456
    }
  ]
}
```

> **Nota:** o `status` deste endpoint usa valor em minúsculas (`valid`), diferente dos enums em MAIÚSCULAS de outros endpoints.
