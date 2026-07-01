# Endpoint: Obter Planos de Produto

> Referência: documentação Hotmart Developers — seção "Produto" > "Obter Planos de Produto".

Retorna os planos de assinatura de um produto: código, nome, descrição, valor, periodicidade, moeda, modo de pagamento, período de trial, recuperação de assinatura e se a troca de planos está habilitada.

`GET /products/api/v1/products/:ucode/plans`

## Parâmetros da requisição

| Local | Parâmetro | Descrição |
|---|---|---|
| Path | `ucode` | Identificador único (UUID) do produto (obtido via [Obter Produtos](./endpoint-obter-produtos.md)). |
| Query | `max_results` | Número máximo de itens por página. |
| Query | `page_token` | Cursor de paginação. |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/products/api/v1/products/:ucode/plans' \
 --header 'Content-Type: application/json' \
 --header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `code` | string | Identificador do plano de assinatura. |
| `name` | string | Nome do plano. |
| `description` | string | Descrição cadastrada do plano. |
| `price` | object | Preço do plano: `value` e `currency_code` (ex.: `BRL`, `USD`, `EUR`, `MXN`). |
| `periodicity` | string | Duração das recorrências (valores abaixo). |
| `max_installments` | integer | Quantidade máxima de parcelas. |
| `payment_mode` | string | Modo de pagamento (valores abaixo). |
| `trial_period` | integer | Período de trial em dias. *(Só presente quando há trial.)* |
| `is_subscription_recovery_enabled` | boolean | Se a recuperação de assinatura está habilitada. |
| `is_switch_plan_enabled` | boolean | Se a troca de plano está habilitada. |

> **Nota de estrutura:** a documentação de campos lista `value` e `currency_code` separados, mas no JSON de resposta eles vêm aninhados dentro do objeto `price`.

### Valores de `periodicity`

`SINGLE_INSTALLMENT`, `WEEKLY`, `MONTHLY`, `BIMONTHLY`, `QUARTERLY`, `ANNUAL`, `BIANNUAL`.

### Valores de `payment_mode`

`PAGAMENTO_UNICO`, `ASSINATURA`, `MULTIPLOS_PAGAMENTOS`, `PAGAMENTO_VISTA`, `NOT_DEFINED`, `INVOICE`, `SMART_INSTALLMENT`, `BILLET_INSTALLMENT`.

> **Atenção:** aqui os valores de `payment_mode` estão em **português** (`ASSINATURA`, `PAGAMENTO_UNICO`...), diferente do endpoint [Obter Ofertas de Produto](./endpoint-obter-ofertas-produto.md), que usa os equivalentes em inglês (`SUBSCRIPTION`, `UNIQUE_PAYMENT`...).

### `page_info`

| Campo | Descrição |
|---|---|
| `next_page_token` | Referência da próxima página (ausente na última). |
| `prev_page_token` | Referência da página anterior (ausente na primeira). |
| `results_per_page` | Itens da página atual. |

## Exemplo de resposta (200 - Success)

```json
{
 "items": [
  {
    "price": {
      "currency_code": "BRL",
      "value": 10
    },
    "payment_mode": "ASSINATURA",
    "is_subscription_recovery_enabled": false,
    "is_switch_plan_enabled": true,
    "description": "Plano básico mensal",
    "periodicity": "MONTHLY",
    "name": "Básico Mensal",
    "max_installments": 1,
    "code": "tz12qeev"
  },
  {
    "price": {
      "currency_code": "BRL",
      "value": 350
    },
    "payment_mode": "ASSINATURA",
    "is_subscription_recovery_enabled": false,
    "is_switch_plan_enabled": false,
    "description": "Plano avançado semestral",
    "periodicity": "BIANNUAL",
    "name": "Avançado Semestral",
    "max_installments": 3,
    "code": "x1n6kb1y"
  },
  {
    "price": {
      "currency_code": "EUR",
      "value": 45.99
    },
    "payment_mode": "ASSINATURA",
    "is_subscription_recovery_enabled": false,
    "is_switch_plan_enabled": false,
    "description": "Plano internacional anual",
    "periodicity": "ANNUAL",
    "name": "Internacional EUR",
    "max_installments": 4,
    "trial_period": 14,
    "code": "6xrozvay"
  }
 ],
 "page_info": {
   "results_per_page": 7
 }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Success | `200` | `ucode` | `3f9e2d5a-4cb8-4f13-9d2e-8b7c4a0f1e92` |
