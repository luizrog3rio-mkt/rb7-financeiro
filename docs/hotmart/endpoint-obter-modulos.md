# Endpoint: Obter Módulos

> Referência: documentação Hotmart Developers — seção "Área de membros" > "Obter módulos".

Busca o conteúdo (módulos) criado pelo produtor dentro de uma Área de Membros — módulos principais e também os **extras** (conteúdo adicional).

`GET /club/api/v1/modules`

## Parâmetros da requisição (query)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subdomain` | sim | Subdomínio da Área de Membros (definido na administração do Club). Indica de qual Club os dados são requisitados. |
| `is_extra` | não | `true` retorna os módulos extras; `false` retorna apenas os principais. **Padrão: `false`**. |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/club/api/v1/modules?subdomain=my-subdomain&is_extra=false' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno

> O retorno é um **array direto** de módulos (sem paginação).

| Campo | Tipo | Descrição |
|---|---|---|
| `module_id` | string | Identificador único do módulo. |
| `name` | string | Nome do módulo (definido pelo produtor). |
| `sequence` | integer | Ordem de exibição do módulo para os alunos. |
| `is_public` | boolean | `true` se o módulo é **gratuito** (disponível para quem ainda não comprou o curso). |
| `is_extra` | boolean | `true` se é um módulo **extra** (conteúdo adicional). |
| `is_extra_paid` | boolean | Para módulo extra: `true` se é **pago**, `false` se gratuito. |
| `classes` | array | Aulas do módulo. |
| `total_pages` | integer | Quantidade total de páginas do módulo. |

### Exemplo de resposta (200 - Success)

```json
[
  {
    "module_id": "2z7ramxejw",
    "name": "Hotmart Club - Module 1",
    "sequence": 1,
    "is_extra": false,
    "is_extra_paid": false,
    "is_public": false,
    "classes": [
      "qV7y1Jm7Jn"
    ],
    "total_pages": 2
  },
  {
    "module_id": "j14okvB4pL",
    "name": "Hotmart Club - Module 2",
    "sequence": 2,
    "is_extra": false,
    "is_extra_paid": false,
    "is_public": true,
    "classes": [
      "qV7y1Jm7Jn"
    ],
    "total_pages": 4
  },
  {
    "module_id": "DPeA5MoeWE",
    "name": "Hotmart Club - Module Dripping",
    "sequence": 5,
    "is_extra": false,
    "is_extra_paid": false,
    "is_public": true,
    "classes": [
      "qV7y1Jm7Jn"
    ],
    "total_pages": 3
  }
]
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subdomain` | `my_subdomain` |
| Sucesso (somente módulos extras) | `200` | `is_extra` | `true` |
| `subdomain` é obrigatório | `422` | sem parâmetros ou só `is_extra` | — |
