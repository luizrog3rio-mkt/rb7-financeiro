# Webhook — Evento de primeiro acesso

> Referência: documentação Hotmart Developers — seção "Webhook" > "Evento de primeiro acesso".
> **Versão:** `2.0.0` · **event:** `CLUB_FIRST_ACCESS` · **Formato:** JSON

Disparado no **primeiro acesso de um aluno a um curso**, identificando o produto e o aluno.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`**. **Valide-o antes de tratar os dados.** |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único de identificação do evento. |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento — sempre `CLUB_FIRST_ACCESS`. |
| `version` | string | Versão do evento — sempre `2.0.0`. |
| `data` | object | Dados do primeiro acesso (abaixo). |

## `data`

| Campo | Tipo | Descrição |
|---|---|---|
| `product.id` | integer | Identificador do produto. |
| `product.name` | string | Nome do produto. |
| `user.name` | string | Nome completo do aluno. |
| `user.email` | string | E-mail do aluno. |

## Exemplo de payload

```json
{
  "id": "27b52d28-acf4-448a-bc5f-4ab4bc8dcb35",
  "creation_date": 1632411406874,
  "event": "CLUB_FIRST_ACCESS",
  "version": "2.0.0",
  "data": {
    "product": {
      "id": 3526906,
      "name": "Product Name"
    },
    "user": {
      "name": "Buyer Name",
      "email": "buyer@email.com"
    }
  }
}
```
