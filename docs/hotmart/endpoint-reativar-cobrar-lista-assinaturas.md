# Endpoint: Reativar e Cobrar Lista de Assinaturas

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Reativar e cobrar lista de assinaturas".

Reativa uma **lista** de assinaturas inativas em lote, podendo escolher se uma nova cobrança será realizada após o processo.

`POST /payments/api/v1/subscriptions/reactivate`

> **Importante — depende do aceite do assinante.** Cada assinante recebe um **e-mail com link válido por 3 dias** para aceitar ou recusar a reativação. Ver [Reativar e Cobrar Assinatura](./endpoint-reativar-cobrar-assinatura.md) para detalhes.

## Parâmetros da requisição (body)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subscriber_code` | sim | **Array** de códigos de assinantes a reativar. |
| `charge` | não | `true` gera nova cobrança ao reativar; **padrão `false`**. A data de cobrança continua a mesma de antes da desativação. |

### Requisição

```bash
curl --location --request POST 'https://developers.hotmart.com/payments/api/v1/subscriptions/reactivate' \
  --header 'Authorization: Bearer :access_token' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "subscriber_code": [:subscriber_code],
      "charge": :charge
  }'
```

## Retorno

| Campo | Tipo | Descrição |
|---|---|---|
| `success_subscriptions` | array | Assinaturas reativadas com sucesso. |
| `fail_subscriptions` | array | Assinaturas que não foi possível reativar (ex.: código inválido ou já ativa). |

### Campos de cada assinatura (ambas as listas)

| Campo | Tipo | Descrição |
|---|---|---|
| `status` | string | Status atual da assinatura. |
| `subscriber_code` | string | Código exclusivo do assinante. |
| `creation_date` | string | Data de criação da assinatura. |
| `interval_between_charges` | integer | Ciclo de cobranças na adesão: `7` semanal, `30` mensal, `60` bimestral, `90` trimestral, `180` semestral, `360` anual. |
| `shopper` | object | Comprador (`email`, `phone`). |

### Campo extra em `fail_subscriptions[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `error` | string | Motivo da falha (ex.: `SUBSCRIPTION_ALREADY_ACTIVE`). |

### Exemplo de resposta (200 - Success)

```json
{
  "success_subscriptions": [
    {
      "status": "INACTIVE",
      "subscriber_code": "9W2LNSG2",
      "creation_date": "2020-07-20 17:57:42",
      "interval_between_charges": 30,
      "shopper": {
        "email": "subscriber@email.com",
        "phone": "(31) 988888888"
      }
    }
  ],
  "fail_subscriptions": [
    {
      "status": "ACTIVE",
      "error": "SUBSCRIPTION_ALREADY_ACTIVE",
      "subscriber_code": "RGT90XMB",
      "creation_date": "2020-07-08 16:35:57",
      "interval_between_charges": 30,
      "shopper": {
        "email": "subscriber2@email.com.",
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

> O retorno de sucesso traz um exemplo com uma assinatura reativada (`success_subscriptions`) e uma com falha (`fail_subscriptions`), permitindo testar ambos os casos.
