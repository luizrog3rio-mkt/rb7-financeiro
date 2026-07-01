# Webhook — Evento de troca de plano

> Referência: documentação Hotmart Developers — seção "Webhook" > "Evento de troca de plano".
> **Versão:** `2.0.0` · **event:** `SWITCH_PLAN` · **Formato:** JSON

Disparado toda vez que uma pessoa troca o plano que usa no seu produto. Traz dados do assinante e dos planos (anterior e atual).

> A documentação tem abas **Produtor(a)** e **Afiliado(a)**; o payload abaixo é o da visão **Produtor(a)**.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`**. **Valide-o antes de tratar os dados.** |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único de identificação do evento. |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento — sempre `SWITCH_PLAN`. |
| `version` | string | Versão do evento — sempre `2.0.0`. |
| `data` | object | Dados da troca de plano (abaixo). |

## `data`

| Campo | Tipo | Descrição |
|---|---|---|
| `switch_plan_date` | long | Data da troca do plano (em ms, apesar de a doc citar "unix timestamp UTC"). |
| `subscription` | object | Dados da assinatura (abaixo). |
| `plans` | array | Planos envolvidos (abaixo). |

### `data.subscription`

| Campo | Tipo | Descrição |
|---|---|---|
| `product.id` | integer | Identificador do produto da assinatura. |
| `product.name` | string | Nome do produto. |
| `subscriber_code` | string | Código do assinante. **Um mesmo comprador terá `subscriber_code` diferentes por produto.** |
| `date_next_charge` | long | Data da próxima cobrança (ms). |
| `user.email` | string | E-mail do assinante. |
| `status` | string | Status atual da assinatura (ver enum abaixo). |

#### Valores de `subscription.status`

`ACTIVE`, `INACTIVE`, `CANCELED_BY_CUSTOMER`, `CANCELED_BY_VENDOR`, `CANCELED_BY_ADMIN`, `OVERDUE`, `STARTED`, `EXPIRED`.

> **Atenção (inconsistência entre endpoints):** aqui os status de cancelamento usam **`CANCELED_BY_*`** (um "L"). Em [Obter Assinaturas](./endpoint-obter-assinaturas.md) aparecem como `CANCELLED_BY_*` (dois "L"). Trate ambas as grafias ao mapear status.

### `data.plans[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | long | Identificador do plano. |
| `name` | string | Nome do plano. |
| `offer.key` | string | Código da oferta que gerou a assinatura do plano. |
| `current` | boolean | `true` = plano **atual** da assinatura; `false` = plano anterior. |

> O array `plans` traz o plano novo (`current: true`) e o antigo (`current: false`). Use `current` para identificar para qual plano o assinante migrou.

## Exemplo de payload

```json
{
    "id": "93069d0e-f35b-443e-9146-75b552321a7e",
    "creation_date": 1633003064000,
    "event": "SWITCH_PLAN",
    "version": "2.0.0",
    "data": {
        "switch_plan_date": 1629926054000,
        "subscription": {
            "subscriber_code": "AT3IV3RX",
            "status": "ACTIVE",
            "date_next_charge": 1736337600000,
            "product": {
                "id": 4116023,
                "name": "Product Name"
            },
            "user": {
                "email": "email@hotmart.com"
            }
        },
        "plans": [
            {
                "id": 707635,
                "name": "Plan Test 1",
                "offer": {
                    "key": "py01ycdp"
                },
                "current": true
            },
            {
                "id": 631288,
                "name": "Plan Test 2",
                "offer": {
                    "key": "2nyk0xc3"
                },
                "current": false
            }
        ]
    }
}
```
