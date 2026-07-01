# Endpoint: Obter Alunos

> Referência: documentação Hotmart Developers — seção "Área de membros" > "Obter alunos".

Retorna todos os alunos de uma Área de Membros — sejam compradores, importados ou cadastrados gratuitamente.

`GET /club/api/v1/users`

> Tutorial relacionado: [Identificar o engajamento dos alunos no Hotmart Club](./api-engajamento-alunos-club.md).

## Enums

### Papel (`role`)

| Papel | Definição |
|---|---|
| `STUDENT` | Estudante. |
| `FREE_STUDENT` | Estudante gratuito. |
| `OWNER` | Proprietário da Área de Membros. |
| `ADMIN` | Administrador. |
| `CONTENT_EDITOR` | Editor de conteúdo. |
| `MODERATOR` | Moderador. |

### Acesso Plus (`plus_access`)

| Status | Definição |
|---|---|
| `WITHOUT_PLUS_ACCESS` | Sem Acesso Plus. |
| `HOLDER` | Titular do Acesso Plus. |
| `HOLDER_WITH_DEPENDENTS` | Titular com dependentes. |
| `HOLDER_WITHOUT_DEPENDENTS` | Titular sem dependentes. |
| `DEPENDENT` | Dependente do titular. |

### Status do aluno (`status`)

| Status | Definição |
|---|---|
| `ACTIVE` | Aluno ativo. |
| `BLOCKED` | Aluno bloqueado. |
| `BLOCKED_BY_OWNER` | Bloqueado pelo produtor/administrador. |
| `OVERDUE` | Aluno com assinatura vencida. |

### Tipo do aluno (`type`)

| Tipo | Definição |
|---|---|
| `BUYER` | Comprou a Área de Membros. |
| `IMPORTED` | Importado para a Área de Membros. |
| `FREE` | Aluno gratuito. |
| `OWNER` | Proprietário. |
| `GUEST` | Convidado. |

### Engajamento (`engagement`)

Índice que mede o quanto o usuário interage com o produto: `NONE`, `LOW`, `MEDIUM`, `HIGH`, `VERY_HIGH`.

## Parâmetros da requisição (query)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `subdomain` | sim | Subdomínio da Área de Membros (definido na administração do Club). |
| `email` | não | E-mail do aluno (completo ou parcial) para buscar um aluno específico. |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/club/api/v1/users?subdomain=my-subdomain' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `user_id` | string | Identificador único do aluno no Club. |
| `name` | string | Nome do aluno. |
| `email` | string | E-mail do aluno. |
| `role` | string | Papel do aluno (ver enum). |
| `last_access_date` | long | Data do último acesso. |
| `first_access_date` | long | Data do primeiro acesso. |
| `locale` | string | Idioma da compra (ou usado na importação). |
| `plus_access` | string | Status de Acesso Plus (ver enum). |
| `progress` | object | Resumo do progresso (abaixo). |
| `status` | string | Status do aluno (ver enum). |
| `purchase_date` | long | Data da compra. |
| `access_count` | integer | Número de acessos à Área de Membros. |
| `is_deletable` | boolean | `true` se o aluno pode ser bloqueado. |
| `class_id` | string | Identificador da turma do aluno. |
| `type` | string | Tipo do aluno (ver enum). |
| `engagement` | string | Engajamento (ver enum). |

### `progress`

| Campo | Tipo | Descrição |
|---|---|---|
| `completed_percentage` | double | Percentual de páginas concluídas. |
| `total` | long | Total de páginas da Área de Membros. |
| `completed` | long | Total de páginas concluídas. |

### `page_info`

| Campo | Descrição |
|---|---|
| `total_results` | Total de itens da lista (pode não vir em todos os endpoints). |
| `next_page_token` | Referência da próxima página (ausente na última). |
| `prev_page_token` | Referência da página anterior (ausente na primeira). |
| `results_per_page` | Itens da página atual. |

## Exemplo de resposta (200 - Success)

```json
{
  "items": [
    {
      "user_id": "n2OM623n46",
      "engagement": "NONE",
      "name": "Hotmart Example User One",
      "email": "user.one@hotmart.com",
      "last_access_date": 1546728645,
      "role": "FREE_STUDENT",
      "first_access_date": 1607054711,
      "locale": "pt_BR",
      "plus_access": "WITHOUT_PLUS_ACCESS",
      "progress": {
        "completed_percentage": 45,
        "total": 11,
        "completed": 5
      },
      "status": "ACTIVE",
      "access_count": 1,
      "is_deletable": true,
      "class_id": "qV7y1Jm7Jn",
      "type": "FREE"
    },
    {
      "user_id": "ZYOmWXlded",
      "engagement": "LOW",
      "name": "Hotmart Example User Two",
      "email": "user.two@hotmart.com",
      "last_access_date": 1819975825,
      "role": "STUDENT",
      "first_access_date": 1532627687,
      "locale": "pt_BR",
      "plus_access": "WITHOUT_PLUS_ACCESS",
      "progress": {
        "completed_percentage": 0,
        "total": 11,
        "completed": 0
      },
      "status": "ACTIVE",
      "purchase_date": 1616501263,
      "access_count": 2,
      "is_deletable": true,
      "class_id": "qV7y1Jm7Jn",
      "type": "BUYER"
    },
    {
      "user_id": "wx7WpWrQO2",
      "engagement": "MEDIUM",
      "name": "Hotmart Example User Three",
      "email": "user.three@hotmart.com",
      "last_access_date": 1278881901,
      "role": "STUDENT",
      "first_access_date": 1607054711,
      "locale": "pt_BR",
      "plus_access": "WITHOUT_PLUS_ACCESS",
      "progress": {
        "completed_percentage": 0,
        "total": 11,
        "completed": 0
      },
      "status": "BLOCKED",
      "purchase_date": 1616501263,
      "access_count": 1,
      "is_deletable": true,
      "class_id": "qV7y1Jm7Jn",
      "type": "IMPORTED"
    }
  ],
  "page_info": {
    "total_results": 111,
    "next_page_token": "eyJwYWdlIjoyLCJyb3dzIjoxMH0=",
    "prev_page_token": "eyJwYWdlIjoyLCJyb3dzIjoxMH0=",
    "results_per_page": 3
  }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subdomain` | `my_subdomain` |
| `subdomain` é obrigatório | `422` | sem parâmetros | — |
