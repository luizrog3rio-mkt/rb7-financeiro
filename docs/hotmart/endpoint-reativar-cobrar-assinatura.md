# Endpoint: Reativar e Cobrar Assinatura

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Reativar e cobrar assinatura".

Reativa uma **assinatura inativa**, podendo escolher se uma nova cobrança será realizada após o processo.

`POST /payments/api/v1/subscriptions/:subscriber_code/reactivate`

> **Importante — depende do aceite do assinante.** Para reativar (ou reativar e cobrar), o assinante precisa **aceitar a reativação**. O Produtor envia a solicitação e o assinante recebe um **e-mail com um link válido por 3 dias** para aceitar ou recusar. Por isso, o `status` retornado permanece `INACTIVE` até o aceite.

## Parâmetros da requisição

### Path

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subscriber_code` | sim | Código exclusivo do assinante cuja assinatura você deseja reativar. |

### Body

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `charge` | boolean | `true` gera uma nova cobrança ao reativar; **padrão `false`**. A data de cobrança continua a mesma de antes da desativação. |

### Requisição

```bash
curl --location --request POST 'https://developers.hotmart.com/payments/api/v1/subscriptions/:subscriber_code/reactivate' \
  --header 'Authorization: Bearer :access_token' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "charge": :charge
  }'
```

## Retorno

| Campo | Tipo | Descrição |
|---|---|---|
| `status` | string | Status atual: `INACTIVE` (permanece assim até o aceite do assinante). |
| `subscriber_code` | string | Código exclusivo do assinante. |
| `creation_date` | string | Data de criação da assinatura. |
| `interval_between_charges` | integer | Ciclo de cobranças na adesão (valores abaixo). |
| `shopper` | object | Comprador responsável pelo pagamento (`email`, `phone`). |

### Valores de `interval_between_charges`

| Valor | Ciclo |
|---|---|
| `7` | Semanal |
| `30` | Mensal |
| `60` | Bimestral |
| `90` | Trimestral |
| `180` | Semestral |
| `360` | Anual |

### Exemplo de resposta (200 - Success)

```json
{
  "status": "INACTIVE",
  "subscriber_code": "9W2LNSG2",
  "creation_date": "2020-07-20 17:57:42",
  "interval_between_charges": 30,
  "shopper": {
    "email": "shopper@email.com.br",
    "phone": "(31) 988888888"
  }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox. Valores diferentes dos da tabela retornam erro **404**.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subscriber_code` | `B2HNQAXJ` |
| Assinatura não pôde ser reativada | `400` | `subscriber_code` | `X53ZPFQZ` |
