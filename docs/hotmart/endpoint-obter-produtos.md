# Endpoint: Obter Produtos

> Referência: documentação Hotmart Developers — seção "Produto" > "Obter Produtos".

Lista os produtos do creator, retornando ID, nome, status, data de criação, formato, indicação de assinatura, período de garantia, entre outros. Útil para dashboards de catálogo, automação de gerenciamento de produtos e análise de desempenho.

`GET /products/api/v1/products`

## Parâmetros da requisição (query)

| Parâmetro | Descrição |
|---|---|
| `max_results` | Número máximo de itens por página. **Padrão: 50.** |
| `page_token` | Cursor de paginação. |
| `id` | ID do produto (7 dígitos). |
| `status` | Status do produto (valores abaixo). |
| `format` | Formato do produto (valores abaixo). |

### Valores de `status`

`DRAFT`, `ACTIVE`, `PAUSED`, `NOT_APPROVED`, `IN_REVIEW`, `DELETED`, `CHANGES_PENDING_ON_PRODUCT`.

### Valores de `format`

`EBOOK`, `SOFTWARE`, `MOBILE_APPS`, `VIDEOS`, `AUDIOS`, `TEMPLATES`, `IMAGES`, `ONLINE_COURSE`, `SERIAL_CODES`, `ETICKET`, `ONLINE_SERVICE`, `ONLINE_EVENT`, `BUNDLE`, `COMMUNITY`, `AGENT`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/products/api/v1/products' \
 --header 'Content-Type: application/json' \
 --header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | long | ID do produto (7 dígitos). |
| `name` | string | Nome do produto. |
| `ucode` | string | ID do produto em formato UUID. |
| `status` | string | Status do produto (ver valores acima). |
| `created_at` | long | Data de criação (ms desde 1970-01-01 UTC). |
| `format` | string | Formato do produto (ver valores acima). |
| `is_subscription` | boolean | Se o produto é assinatura. **Smart Installment e Smart Recovery retornam `false`.** Para Combo, depende do método de cobrança (recorrente ou único). |
| `warranty_period` | integer | Período de garantia padrão do produto. |

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
    "id": 698441,
    "name": "Product A",
    "ucode": "f2b3be1f-313f-4a2d-b5b7-1c39d67dd3ee",
    "status": "DRAFT",
    "created_at": 1586459699000,
    "format": "EBOOK",
    "is_subscription": false,
    "warranty_period": 7
  },
  {
    "id": 1117869,
    "name": "Product B",
    "ucode": "26a97448-2ac2-458d-9e03-bcc01e82bdd8",
    "status": "DRAFT",
    "created_at": 1603816477000,
    "format": "ONLINE_COURSE",
    "is_subscription": true,
    "warranty_period": 15
  },
  {
   "id": 486869,
   "name": "Product C",
   "ucode": "6505e7ed-ff32-4d1a-8baa-62958d5c790a",
   "status": "CHANGES_PENDING_ON_PRODUCT",
   "created_at": 1569933453000,
   "format": "ETICKET",
   "is_subscription": false,
   "warranty_period": 7
  },
  {
    "id": 4319408,
    "name": "Product D",
    "ucode": "e211d636-dd19-4411-9397-ab3428e966a2",
    "status": "DRAFT",
    "created_at": 1721077570000,
    "format": "BUNDLE",
    "is_subscription": true,
    "warranty_period": 7
  }
 ],
 "page_info": {
  "next_page_token": "eyJyb3dzIjo1LCJwYWdlIjozfQ==",
  "prev_page_token": "eyJyb3dzIjo1LCJwYWdlIjoxfQ==",
  "results_per_page": 4
 }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.
