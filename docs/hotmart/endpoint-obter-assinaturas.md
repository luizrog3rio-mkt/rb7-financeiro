# Endpoint: Obter Assinaturas

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Obter assinaturas".

Exibe informações detalhadas das assinaturas/assinantes do produtor. Usado para listagem de assinaturas e seus detalhes.

`GET /payments/api/v1/subscriptions`

## Parâmetros da requisição (query)

> Todas as datas devem estar em **milissegundos**, a partir de `1970-01-01 00:00:00 UTC`.

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `max_results` | integer | Número máximo de itens por página. |
| `page_token` | string | Cursor de paginação (use `next_page_token`/`prev_page_token`). |
| `product_id` | long | ID do produto de assinatura (número de 7 dígitos). |
| `plan` | string | Nome do plano. **Aceita múltiplos valores** — repita a chave com valores diferentes. |
| `plan_id` | long | Identificador único do plano. |
| `accession_date` | date (ms) | Data de início da assinatura. Padrão: data atual − 30 dias. |
| `end_accession_date` | date (ms) | Data em que o assinante solicitou o cancelamento. |
| `status` | string | Status da assinatura (valores abaixo). |
| `subscriber_code` | string | Código exclusivo do assinante (pode não ser quem comprou). |
| `subscriber_email` | string | E-mail do assinante. |
| `transaction` | string | Identificador único da transação (ex.: `HP17715690036014`). |
| `trial` | boolean | Filtra assinaturas com/sem período de teste. |
| `cancelation_date` | date (ms) | Assinaturas canceladas **a partir** desta data. Padrão: atual − 30 dias. |
| `end_cancelation_date` | date (ms) | Assinaturas canceladas **até** esta data. Padrão: data atual. |
| `date_next_charge` | date (ms) | Filtra assinaturas com data de próxima tentativa de pagamento **a partir** desta data. Padrão: data atual. |
| `end_date_next_charge` | date (ms) | Filtra assinaturas com data de próxima tentativa de pagamento **até** esta data. Padrão: data atual. |

### Valores possíveis de `status`

`ACTIVE`, `INACTIVE`, `DELAYED`, `CANCELLED_BY_CUSTOMER`, `CANCELLED_BY_SELLER`, `CANCELLED_BY_ADMIN`, `STARTED`, `OVERDUE`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/subscriptions?status=CANCELLED_BY_SELLER&status=ACTIVE' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno

### `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `subscriber_code` | string | Código do assinante. *Um mesmo comprador terá 2 `subscriber_code` diferentes se assinar dois produtos.* |
| `subscription_id` | — | Número de identificação da assinatura na Hotmart. |
| `status` | string | Status atual (mesmos valores da query). |
| `accession_date` | date (ms) | Data inicial de liberação de acesso ao conteúdo. |
| `end_accession_date` | date (ms) | Data em que o assinante solicitou o cancelamento. |
| `request_date` | date (ms) | Data de criação da assinatura. |
| `date_next_charge` | date (ms) | Data da próxima tentativa de pagamento. Em assinaturas canceladas, indica a última data de acesso (nenhuma cobrança após). |
| `trial` | boolean | `true` se a assinatura tem/teve período de teste. |
| `transaction` | string | Identificador único da transação (ex.: `HP17715690036014`). |
| `plan` | object | Dados do plano (abaixo). |
| `product` | object | Dados do produto (abaixo). |
| `price` | object | Dados do preço (abaixo). |
| `subscriber` | object | Dados do assinante (abaixo). |

> **Sobre `date_next_charge`:** se o produto é cobrado todo dia 10 e o assinante cancela no dia 20, o campo retorna o dia 10 do mês seguinte (última data de acesso).

#### `plan`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Nome do plano. |
| `id` | long | Identificador único do plano. |
| `recurrency_period` | integer | Periodicidade da recorrência (valores abaixo). |
| `max_charge_cycles` | integer | Número máximo de recorrências. **Se não retornado**, a cobrança ocorre até o assinante cancelar. |

Valores de `recurrency_period`:

| Valor | Período |
|---|---|
| `7` | Semanal |
| `30` | Mensal |
| `60` | Bimestral |
| `90` | Trimestral |
| `180` | Semestral |
| `360` | Anual |

#### `product`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | integer | ID do produto. |
| `name` | string | Nome do produto de assinatura. |
| `ucode` | string | Identificação externa do produto (use no seu sistema para identificá-lo). |

#### `price`

| Campo | Tipo | Descrição |
|---|---|---|
| `value` | double | Preço de cada recorrência. |
| `currency_code` | string | Código internacional da moeda (ex.: `BRL`, `USD`, `EUR`). |

#### `subscriber`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Nome do assinante. |
| `email` | string | E-mail do assinante. |
| `ucode` | string | Identificação externa do assinante. |

### `page_info`

| Campo | Tipo | Descrição |
|---|---|---|
| `total_results` | integer | Total de itens da lista (pode não vir em todos os endpoints). |
| `next_page_token` | string | Referência da próxima página (ausente na última página). |
| `prev_page_token` | string | Referência da página anterior (ausente na primeira página). |
| `results_per_page` | integer | Itens da página atual. |

### Exemplo de resposta (200 - Success)

```json
{
  "items": [
    {
      "subscriber_code": "ABC12DEF",
      "subscription_id": 123456,
      "status": "ACTIVE",
      "accession_date": 1577847600,
      "end_accession_date": 1641005999,
      "request_date": 1577847600,
      "date_next_charge": 1580558059,
      "trial": false,
      "transaction": "HP16616613605324",
      "plan": {
        "name": "Plan name",
        "id": 726420,
        "recurrency_period": 30,
        "max_charge_cycles": 6
      },
      "product": {
        "id": 123456,
        "name": "Product Name",
        "ucode": "12a34bcd-56e7-4847-fg89-h1i23j4567l8"
      },
      "price": {
        "value": 123.45,
        "currency_code": "BRL"
      },
      "subscriber": {
        "name": "Subscriber name",
        "email": "subscriber@email.com.br",
        "ucode": "10a98bcd-76e5-4321-fg09-h8i76j5432l1"
      }
    }
  ],
  "page_info": {
    "total_results": 30,
    "next_page_token": "05b60506b659c1c6e728db93eada6271e3adcfb4edf507b679874458e31577b3",
    "prev_page_token": "cf1fg8bd082e2864069035c057eca0bac7eb5d604719c5a76e80f0933f49c217",
    "results_per_page": 10
  }
}
```

## Sandbox

Para testar no Sandbox, troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.
