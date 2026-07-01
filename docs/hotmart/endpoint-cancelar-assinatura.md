# Endpoint: Cancelar Assinatura

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Cancelar assinatura".

Cancela uma assinatura, interrompe o ciclo de cobranças e notifica o cancelamento para sub-sistemas como **Club** e **Webhook**.

`POST /payments/api/v1/subscriptions/:subscriber_code/cancel`

## Parâmetros da requisição

### Path

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subscriber_code` | sim | Código exclusivo de um assinante. |

### Body

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `send_mail` | boolean | `true` envia e-mail de notificação de cancelamento ao comprador; `false` não envia. |

### Requisição

```bash
curl --location --request POST 'https://developers.hotmart.com/payments/api/v1/subscriptions/:subscriber_code/cancel' \
--header 'Authorization: Bearer :access_token' \
--header 'Content-Type: application/json' \
--data-raw '{
    "send_mail": :send_mail
}'
```

## Retorno

> **Atenção:** neste endpoint as datas vêm como **string datetime** (`"2020-07-20 17:57:42"`), e **não** em milissegundos como nos endpoints de listagem.

| Campo | Tipo | Descrição |
|---|---|---|
| `status` | string | Status atual da assinatura: `ACTIVE` ou `INACTIVE`. |
| `subscriber_code` | string | Código exclusivo do assinante (pode não ser quem comprou). |
| `creation_date` | string | Data de criação da assinatura. |
| `current_recurrence` | integer | Número da recorrência atual (aumenta conforme novas recorrências são pagas). |
| `date_last_recurrence` | string | Data do último pagamento. |
| `date_next_charge` | string | Data da próxima tentativa de pagamento. |
| `due_day` | integer | Dia das cobranças. Mensais/anuais: dia do mês. Semanais: dia da semana (mapa abaixo). |
| `trial_period` | integer | Dias de período de teste. Após esse período, ocorre a 1ª cobrança. |
| `interval_type_between_charges` | string | Intervalo entre cobranças: `DAY`, `WEEK`, `MONTH` ou `INVOICE`. |
| `interval_between_charges` | integer | Número de cobranças conforme o tipo. Ex.: `MONTH` + `3` = trimestral. |
| `max_charge_cycles` | integer | Recorrências configuradas para o plano. **`0` = sem limite** ("até o cliente cancelar"). |
| `activation_date` | string | Data de ativação da assinatura. |
| `shopper` | object | Usuário responsável pelo pagamento (`email`, `phone`). |

### Mapa de `due_day` (assinaturas semanais)

| Valor | Dia |
|---|---|
| `1` | Segunda-feira |
| `2` | Terça-feira |
| `3` | Quarta-feira |
| `4` | Quinta-feira |
| `5` | Sexta-feira |
| `6` | Sábado |
| `7` | Domingo |

### `shopper`

| Campo | Tipo | Descrição |
|---|---|---|
| `email` | string | E-mail do comprador. |
| `phone` | string | Telefone do comprador. |

### Exemplo de resposta (200 - Success)

```json
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
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox. Valores diferentes dos da tabela retornam erro **404**.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subscriber_code` | `B2HNQAXJ` |
| Impossível cancelar assinatura já cancelada | `400` | `subscriber_code` | `X53ZPFQZ` |
