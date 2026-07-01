# Webhook — Evento de módulo completo

> Referência: documentação Hotmart Developers — seção "Webhook" > "Evento de módulo completo".
> **Versão:** `2.0.0` · **event:** `CLUB_MODULE_COMPLETED` · **Formato:** JSON

Disparado quando um aluno **completa um módulo** do curso, identificando módulo, aluno e produto.

> Para alunos que consomem via **mobile**, a notificação ocorre dependendo da versão do Hotmart App instalada no dispositivo.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`**. **Valide-o antes de tratar os dados.** |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único de identificação do evento. |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento — sempre `CLUB_MODULE_COMPLETED`. |
| `version` | string | Versão do evento — sempre `2.0.0`. |
| `data` | object | Dados do módulo completo (abaixo). |

## `data`

| Campo | Tipo | Descrição |
|---|---|---|
| `product.id` | integer | Identificador do produto. |
| `product.name` | string | Nome do produto. |
| `user.name` | string | Nome completo do aluno. |
| `user.email` | string | E-mail do aluno. |
| `module.id` | string | Identificador do módulo (mesmo `module_id` do endpoint [Obter Módulos](./endpoint-obter-modulos.md)). |
| `module.name` | string | Nome mais atualizado do módulo. |

## Exemplo de payload

```json
{
  "id": "27b52d28-acf4-448a-bc5f-4ab4bc8dcb35",
  "creation_date": 1632411406874,
  "event": "CLUB_MODULE_COMPLETED",
  "version": "2.0.0",
  "data": {
    "product": {
      "id": 3526906,
      "name": "Product Name"
    },
    "user": {
      "name": "User Name",
      "email": "user@email.com"
    },
    "module": {
      "id": "j14okvB4pL",
      "name": "Module Name"
    }
  }
}
```
