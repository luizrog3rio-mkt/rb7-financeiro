# Webhook — Evento de cancelamento de assinatura

> Referência: documentação Hotmart Developers — seção "Webhook" > "Evento de cancelamento de assinatura".
> **Versão:** `2.0.0` · **event:** `SUBSCRIPTION_CANCELLATION` · **Formato:** JSON

Disparado toda vez que uma pessoa cancela a assinatura do seu produto. Traz dados do assinante, produto, plano e datas de cancelamento.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`** em todas as requisições. É a principal garantia de que a requisição vem da Hotmart. **Valide-o antes de tratar os dados.** Para trocar a chave, contate o suporte. |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único de identificação do evento recebido. |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento — sempre `SUBSCRIPTION_CANCELLATION`. |
| `version` | string | Versão do evento — sempre `2.0.0` (escolhida na configuração do Webhook). |
| `data` | object | Dados do cancelamento (abaixo). |

## `data`

| Campo | Tipo | Descrição |
|---|---|---|
| `actual_recurrence_value` | double | Valor pago na última recorrência processada. |
| `cancellation_date` | long | Data de cancelamento da assinatura (ms). |
| `date_next_charge` | long | Data da próxima tentativa de cobrança **caso a assinatura seja reativada**. Nenhuma cobrança ocorre após o cancelamento, só se houver reativação. **Útil para definir até quando o comprador mantém acesso** (ver nota abaixo). |
| `product` | object | Produto cancelado (`name`, `id`). |
| `subscriber` | object | Dados do assinante (abaixo). |
| `subscription` | object | Dados da assinatura (abaixo). |

### `data.subscriber`

| Campo | Tipo | Descrição |
|---|---|---|
| `code` | string | Código exclusivo do assinante. **Um mesmo comprador terá 2 `code` diferentes se assinar dois produtos diferentes.** |
| `name` | string | Nome completo do assinante. |
| `email` | string | E-mail do assinante. |
| `phone` | object | Telefones: `dddPhone`, `phone` (fixo), `dddCell`, `cell` (celular). |

### `data.subscription`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | integer | Código único da assinatura na Hotmart. |
| `plan` | object | Plano: `name`, `id`. |

> **Nota sobre acesso (`date_next_charge`):** o cancelamento é enviado na data em que ocorre, mas o comprador normalmente deve manter acesso até a data em que seria a próxima cobrança. Ex.: assinatura cobrada todo dia 10; se o cliente cancela no dia 20, o evento chega no dia 20, mas o acesso deveria ir até o dia 10 do mês seguinte. Use `date_next_charge` para encerrar o acesso no momento certo.

## Exemplo de payload

```json
{
  "id": "0d7aa966-b887-4617-8c56-9e865bfc8ce4",
  "creation_date": 1632411406874,
  "event": "SUBSCRIPTION_CANCELLATION",
  "version": "2.0.0",
  "data": {
    "date_next_charge": 1580667200000,
    "product": {
      "name": "Product Name",
      "id": 3526906
    },
    "actual_recurrence_value": 50.10,
    "subscriber": {
      "code": "QO4THU04",
      "name": "Subscriber Name",
      "email": "subscriber@email.com",
      "phone": {
        "dddPhone": "31",
        "phone": "33334444",
        "dddCell": "31",
        "cell": "999999999"
      }
    },
    "subscription": {
      "id": 471681,
      "plan": {
        "name": "Plan Name",
        "id": 460805
      }
    },
    "cancellation_date": 1633410850832
  }
}
```
