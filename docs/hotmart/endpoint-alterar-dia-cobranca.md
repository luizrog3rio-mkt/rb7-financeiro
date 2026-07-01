# Endpoint: Alterar dia de cobrança

> Referência: documentação Hotmart Developers — seção "Assinaturas" > "Alterar dia de cobrança".

Altera o dia de cobrança de uma assinatura **em vigência**, modificando as próximas datas de renovação e respeitando a periodicidade do plano.

`PATCH /payments/api/v1/subscriptions/:subscriber_code`

## Regras importantes

- A alteração só vale a partir do **mês subsequente à próxima parcela** — ou seja, depois que a cobrança já programada for processada.
  - *Ex.: assinatura mensal renova todo dia 10; em 11/jan você altera para o dia 5. A próxima mensalidade ainda será em 10/fev, e só depois em 05/mar.*
- Disponível **apenas** para assinaturas com status **Ativa** ou **Atrasada**.
- Pode ser feita **quantas vezes** o assinante desejar.
- **Não** funciona em assinaturas em **período de teste (trial)**, pois o 1º pagamento ainda não ocorreu (assinatura não está em vigência).

## Parâmetros da requisição

### Path

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subscriber_code` | sim | Código exclusivo de um assinante. |

### Body

| Parâmetro | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `due_day` | integer | sim | Novo dia de cobrança, entre **1 e 31**. Se `31` e o mês corrente só tiver 30 dias, o dia será 30. Valores fora de 1–31 retornam erro. |

### Requisição

```bash
curl --location --request PATCH 'https://developers.hotmart.com/payments/api/v1/subscriptions/:subscriber_code' \
--header 'Authorization: Bearer :access_token' \
--header 'Content-Type: application/json' \
--data-raw '{
  "due_day": :due_day
}'
```

## Retorno

Em caso de sucesso, retorna HTTP **200** com **corpo vazio**.

Exemplo de erro (400 — assinatura em trial):

```json
{
  "error": "subscription_in_trial_period",
  "error_description": "The subscription due day cannot be changed during the trial period.",
  "error_uri": "https://developers.hotmart.com/docs/pt-BR/start/http-response-codes/"
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subscriber_code` | `B2HNQAXJ` |
| Assinatura em período de teste | `400` | `subscriber_code` | `X53ZPFQZ` |

> Em ambos os casos, se o `due_day` do body não estiver entre 1 e 31, a API responde **400**. O mesmo erro ocorre se qualquer valor diferente dos da tabela for enviado.
