# Endpoint: Sumário de Assinaturas

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Sumário de Assinaturas".

Fornece uma visão geral do status atual de cada **Assinatura**, **Smart Installment** e **Smart Recovery**, detalhando a situação da última recorrência — útil para ações de retenção.

`GET /payments/api/v1/subscriptions/summary`

> **Defasagem de até 24h.** Para informações em tempo real, use o endpoint [Obter Assinaturas](./endpoint-obter-assinaturas.md).

## Tipos de cobrança recorrente

Os dados cobrem três tipos (cada `subscription_id` está associado a apenas um):

| Tipo (`billing_type`) | O que é |
|---|---|
| `SUBSCRIPTION` | Assinatura — taxa recorrente pelo acesso a um produto. Nasce de oferta de produto de assinatura. |
| `SMART_INSTALLMENT` | Parcelamento de uma venda de pagamento único (para países sem parcelamento nativo no cartão). **Não permite** o cliente encerrar. |
| `SMART_RECOVERY` | Cria automaticamente uma nova transação recorrente quando uma compra de pagamento único é negada por saldo insuficiente, permitindo recuperar a venda. |

## Parâmetros da requisição (query)

> Todas as datas devem estar em **milissegundos**, a partir de `1970-01-01 00:00:00 UTC`.

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `max_results` | integer | Número máximo de itens por página. |
| `page_token` | string | Cursor de paginação. |
| `product_id` | integer | ID do produto de assinatura (7 dígitos). |
| `subscriber_code` | integer | Código alfanumérico que identifica uma Assinatura-Assinante (um comprador pode ter múltiplos). |
| `accession_date` | date (ms) | Data de início da assinatura. Padrão: atual − 30 dias. |
| `end_accession_date` | date (ms) | Data em que o assinante solicitou o cancelamento. |
| `date_next_charge` | date (ms) | Filtra assinaturas com data de próxima tentativa de pagamento **a partir** desta data. Padrão: data atual. |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/subscriptions/summary?accession_date=1682910000000&end_accession_date=1696374925000&max_results=500' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno

### `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `subscriber_code` | string | Código do assinante. *2 códigos diferentes se assinar dois produtos distintos.* |
| `subscription_id` | integer | Número de identificação da assinatura na Hotmart. |
| `status` | string | Status atual da assinatura (valores abaixo). |
| `lifetime` | integer | Tempo em dias da assinatura desde a adesão (regra abaixo). |
| `accession_date` | date (ms) | Data inicial de liberação de acesso. |
| `end_accession_date` | date (ms) | Data em que o assinante solicitou o cancelamento. |
| `trial` | boolean | `true` se tem/teve período de teste. |
| `plan` | object | Dados do plano (abaixo). |
| `product` | object | Dados do produto (abaixo). |
| `offer` | object | Dados da oferta (abaixo). |
| `last_recurrency` | object | Informação sobre a última recorrência (abaixo). |
| `unpaid_recurrencies` | array | Recorrências não pagas (abaixo). |
| `subscriber` | object | Dados do assinante (abaixo). |

Valores de `status`: `ACTIVE`, `INACTIVE`, `DELAYED`, `CANCELLED_BY_CUSTOMER`, `CANCELLED_BY_SELLER`, `CANCELLED_BY_ADMIN`, `STARTED`, `OVERDUE`.

**Regra do `lifetime`:**
- `ACTIVE`/`DELAYED` → dias até a data corrente.
- `INACTIVE`/`STARTED` → `0`.
- Cancelamentos (`CANCELLED_BY_*`) → período até a data do cancelamento.
- `OVERDUE` → até a data de vencimento da assinatura.

#### `plan`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Plano vigente na **última recorrência** (o comprador pode mudar após a adesão). |
| `recurrency_period` | integer | Duração das recorrências do plano vigente na última recorrência. |

#### `product`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | integer | ID do produto. |
| `name` | string | Nome do produto de assinatura. |

#### `offer`

| Campo | Tipo | Descrição |
|---|---|---|
| `code` | string | Chave da oferta vigente na última recorrência (o comprador pode trocar de plano/oferta após a adesão). |

#### `last_recurrency`

| Campo | Tipo | Descrição |
|---|---|---|
| `number` | integer | Número da última recorrência (regra abaixo). |
| `request_date` | date (ms) | Data em que inicia a última recorrência. Para vigentes (`ACTIVE`/`DELAYED`), é a primeira transação de cobrança da recorrência atual; para as demais, a recorrência máxima do histórico. |
| `status` | string | Status da última recorrência: `REFUNDED`, `CHARGEBACK`, `NOT_PAID`, `CLAIMED`, `PAID`. |
| `transaction_number` | integer | Quantidade de transações de cobrança da última recorrência. |
| `billing_type` | string | `SUBSCRIPTION`, `SMART_RECOVERY` ou `SMART_INSTALLMENT` (ver tabela de tipos acima). |

**Regra do `last_recurrency.number`:**
- `CANCELLED`/`OVERDUE` → recorrência **final** do tempo de vida.
- `STARTED`/`INACTIVE` → **primeira** recorrência.
- `ACTIVE`/`DELAYED` → recorrência **atual**.

#### `unpaid_recurrencies[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `number` | integer | Número da recorrência não paga. |
| `charge_date` | date (ms) | Data de cobrança da recorrência não paga. |

#### `subscriber`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Nome do assinante. |
| `id` | integer | ID numérico único do comprador na Hotmart. |
| `email` | string | E-mail do assinante. |

### `page_info`

| Campo | Tipo | Descrição |
|---|---|---|
| `next_page_token` | string | Referência da próxima página (ausente na última página). |
| `prev_page_token` | string | Referência da página anterior (ausente na primeira página). |
| `results_per_page` | integer | Itens da página atual. |

### Exemplo de resposta (200 - Success)

```json
{
  "items": [
    {
      "subscriber_code": "ABC12DEF",
      "subscription_id": 1223334,
      "status": "ACTIVE",
      "lifetime": 200,
      "accession_date": 1694113403000,
      "end_accession_date": 1694113503000,
      "trial": true,
      "plan": {
        "name": "Plan name",
        "recurrency_period": 180
      },
      "product": {
        "name": "Product name",
        "id": 12345
      },
      "offer": {
        "code": "o1c97lta"
      },
      "last_recurrency": {
        "number": 2,
        "request_date": 1694113403000,
        "status": "NOT_PAID",
        "transaction_number": 1,
        "billing_type": "SMART_INSTALLMENT"
      },
      "unpaid_recurrencies": [
        {
          "number": 2,
          "charge_date": 1694113403000
        }
      ],
      "subscriber": {
        "name": "John",
        "id": 12345,
        "email": "teste@email.com"
      }
    }
  ],
  "page_info": {
    "results_per_page": 0,
    "next_page_token": "05b60506b659c1c6e728db93eada6271e3adcfb4edf507b679874458e31577b3",
    "prev_page_token": "cf1fg8bd082e2864069035c057eca0bac7eb5d604719c5a76e80f0933f49c217"
  }
}
```
