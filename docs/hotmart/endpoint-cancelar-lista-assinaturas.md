# Endpoint: Cancelar Lista de Assinaturas

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Cancelar lista de assinaturas".

Cancela uma **lista** de assinaturas em lote, interrompe os ciclos de cobrança e notifica o cancelamento para sub-sistemas como **Club** e **Webhook**.

`POST /payments/api/v1/subscriptions/cancel`

> Versão em lote do [Cancelar Assinatura](./endpoint-cancelar-assinatura.md). Os campos de cada assinatura no retorno são os mesmos do cancelamento individual.

## Parâmetros da requisição (body)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subscriber_code` | sim | **Array** de códigos de assinantes a cancelar. |
| `send_mail` | não | Envia e-mail de notificação aos compradores. **Padrão: `true`**. Use `false` para não enviar. |

### Requisição

```bash
curl --location --request POST 'https://developers.hotmart.com/payments/api/v1/subscriptions/cancel' \
--header 'Authorization: Bearer :access_token' \
--header 'Content-Type: application/json' \
--data-raw '{
  "subscriber_code": [":subscriber_code"],
  "send_mail": :send_mail
}'
```

## Retorno

O retorno separa os resultados em duas listas:

| Campo | Tipo | Descrição |
|---|---|---|
| `success_subscriptions` | array | Assinaturas canceladas com sucesso. |
| `fail_subscriptions` | array | Assinaturas que **não** foram canceladas (ex.: código inválido ou já cancelada). |

### Campos de cada assinatura (ambas as listas)

> As datas vêm como **string datetime** (`"2020-07-20 17:57:42"`), não em milissegundos.

| Campo | Tipo | Descrição |
|---|---|---|
| `status` | string | `ACTIVE` ou `INACTIVE`. |
| `subscriber_code` | string | Código exclusivo do assinante. |
| `creation_date` | string | Data de criação da assinatura. |
| `current_recurrence` | integer | Número da recorrência atual. |
| `date_last_recurrence` | string | Data do último pagamento. |
| `date_next_charge` | string | Data da próxima tentativa de pagamento. |
| `due_day` | integer | Dia das cobranças (semanais: 1=segunda … 7=domingo — ver [Cancelar Assinatura](./endpoint-cancelar-assinatura.md)). |
| `trial_period` | integer | Dias de período de teste. |
| `interval_type_between_charges` | string | `DAY`, `WEEK`, `MONTH` ou `INVOICE`. |
| `interval_between_charges` | integer | Número de cobranças conforme o tipo (ex.: `MONTH` + `3` = trimestral). |
| `max_charge_cycles` | integer | Recorrências do plano. `0` = sem limite. |
| `activation_date` | string | Data de ativação. |
| `shopper` | object | Comprador (`email`, `phone`). |

### Campo extra em `fail_subscriptions[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `error` | string | Motivo da falha no processamento (ex.: `SUBSCRIPTION_ALREADY_CANCELED_OR_OVERDUE`). |

### Exemplo de resposta (200 - Success)

```json
{
  "success_subscriptions": [
    {
      "status": "INACTIVE",
      "subscriber_code": "9W2LNSG2",
      "creation_date": "2020-07-20 17:57:42",
      "current_recurrence": 1,
      "date_last_recurrence": "2020-07-20 17:57:42",
      "date_next_charge": "2020-08-24 12:00:00",
      "due_day": 24,
      "trial_period": 26,
      "interval_type_between_charges": "MONTH",
      "interval_between_charges": 1,
      "max_charge_cycles": 13,
      "activation_date": "2020-07-20 17:57:44",
      "shopper": {
        "email": "shopper@email.com.br",
        "phone": "(31) 988888888"
      }
    }
  ],
  "fail_subscriptions": [
    {
      "status": "INACTIVE",
      "error": "SUBSCRIPTION_ALREADY_CANCELED_OR_OVERDUE",
      "subscriber_code": "RGT90XMB",
      "creation_date": "2020-07-08 16:35:57",
      "interval_between_charges": 30,
      "shopper": {
        "email": "shopper2@email.com.br",
        "phone": "(31) 988888888"
      }
    }
  ]
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox. Valores diferentes dos da tabela retornam erro **404**.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subscriber_code` | `["B2HNQAXJ","X53ZPFQZ"]` |

> O retorno de sucesso traz um exemplo com uma assinatura cancelada (`success_subscriptions`) e uma com falha (`fail_subscriptions`), permitindo testar ambos os casos.
