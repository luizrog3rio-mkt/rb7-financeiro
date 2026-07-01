# Webhook — Evento de troca do dia de cobrança de assinatura

> Referência: documentação Hotmart Developers — seção "Webhook" > "Evento de troca do dia de cobrança de assinatura".
> **Versão:** `2.0.0` · **event:** `UPDATE_SUBSCRIPTION_CHARGE_DATE` · **Formato:** JSON

Disparado quando uma pessoa troca o dia do mês em que deseja ser cobrada pela assinatura. Traz o dia antigo, o novo e a próxima cobrança.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`**. **Valide-o antes de tratar os dados.** |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único de identificação do evento. |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento — sempre `UPDATE_SUBSCRIPTION_CHARGE_DATE`. |
| `version` | string | Versão do evento — sempre `2.0.0`. |
| `data` | object | Dados da troca (abaixo). |

## `data`

### `data.subscriber`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Nome completo do assinante. |
| `email` | string | E-mail do assinante. |
| `code` | string | Código exclusivo do assinante. **Um mesmo comprador terá 2 `code` diferentes se assinar dois produtos.** |

### `data.subscription`

| Campo | Tipo | Descrição |
|---|---|---|
| `product.name` | string | Nome do produto da assinatura. |
| `product.id` | integer | Identificador do produto. |
| `old_charge_day` | integer | Dia do mês em que era cobrado **antes** da alteração. |
| `new_charge_day` | integer | **Novo** dia do mês de cobrança. |
| `date_next_charge` | string | Data da próxima tentativa de pagamento — **formato string ISO datetime** (ex.: `2022-09-01T12:00:00.000Z`). Em assinaturas canceladas, indica a última data de acesso (ver nota). |
| `status` | string | Status da assinatura no momento da alteração (ver enum abaixo). |

> **Atenção (tipo de data):** aqui `date_next_charge` vem como **string ISO datetime**, diferente de outros eventos (cancelamento, troca de plano) em que vem como **long (ms)**.

> **Nota sobre `date_next_charge`:** para assinatura cancelada, indica a última data de acesso (nenhuma cobrança após isso). Ex.: cobrança todo dia 10; se cancela no dia 20, o campo mostra o dia 10 do mês seguinte. A data já considera a alteração do dia de cobrança, mas em alguns casos isso só vale no próximo ciclo.

#### Valores de `subscription.status`

`ACTIVE`, `INACTIVE`, `CANCELED_BY_CUSTOMER`, `CANCELED_BY_VENDOR`, `CANCELED_BY_ADMIN`, `OVERDUE`, `STARTED`, `EXPIRED`.

> Usa `CANCELED_BY_*` (um "L", `VENDOR`) — igual ao [Evento de troca de plano](./webhook-evento-troca-plano.md) e diferente do [Eventos de pedidos](./webhook-eventos-pedido.md) (`CANCELLED_BY_SELLER`).

### `data.plan`

| Campo | Tipo | Descrição |
|---|---|---|
| `offer.code` | string | Código da oferta que gerou a assinatura. |
| `name` | string | Nome do plano. |
| `id` | integer | Identificador do plano. |

## Exemplo de payload

```json
{
	"id": "bc91fa06-0bd3-4cf5-853a-1fbf4716a10b",
	"creation_date": 1663951146081,
	"event": "UPDATE_SUBSCRIPTION_CHARGE_DATE",
	"version": "2.0.0",
	"data": {
		"subscriber": {
			"name": "Bruno Souza",
			"email": "bruno.souza+br@hotmart.com",
			"code": "QG5LHFHP"
		},
		"subscription": {
			"product": {
				"name": "Assinatura Trapalhoes",
				"id": 4756866
			},
			"old_charge_day": 7,
			"new_charge_day": 6,
			"date_next_charge": "2022-09-01T12:00:00.000Z",
			"status": "ACTIVE"
		},
		"plan": {
			"offer": {
				"code": "gp2z4nti"
			},
			"name": "assinatura",
			"id": 827121
		}
	}
}
```
