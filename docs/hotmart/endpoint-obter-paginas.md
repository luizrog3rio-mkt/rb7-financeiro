# Endpoint: Obter Páginas (v2)

> Referência: documentação Hotmart Developers — seção "Área de membros" > "Obter Páginas".

Lista todas as páginas criadas dentro de um módulo da Área de Membros.

`GET /club/api/v2/modules/{module_id}/pages`

## Tipos e estratégias

### Tipo da página (`type`)

| Tipo | Definição |
|---|---|
| `CONTENT` | Página de conteúdo. |
| `ADVERTISEMENT` | Página de anúncio. |
| `QUIZ` | Página de perguntas e respostas. |
| `WEBINAR` | Página de webinário. |

### Tipo de liberação (`dripping_configs.liberation.type`)

| Tipo | Definição |
|---|---|
| `BY_DATE` | Liberada em data fixa definida pelo produtor. |
| `BY_DAYS` | Liberada X dias após a compra. |
| `BY_QUIZ` | Liberada ao concluir um quiz escolhido pelo produtor. |

### Tipo de expiração (`dripping_configs.expiration.type`)

| Tipo | Definição |
|---|---|
| `BY_DAYS` | Expira X dias após a compra. **(Único tipo de expiração suportado atualmente.)** |

## Parâmetros da requisição

| Local | Parâmetro | Obrigatório | Descrição |
|---|---|---|---|
| Query | `product_id` | sim | Identificador único do produto. |
| Path | `module_id` | sim | Identificador do módulo (obtido via endpoint [Obter Módulos](./endpoint-obter-modulos.md)). |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/club/api/v2/modules/{module_id}/pages?product_id={product_id}' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer :access_token'
```

## Retorno

> O retorno é um **array direto** de páginas (sem paginação).

| Campo | Tipo | Descrição |
|---|---|---|
| `page_id` | string | Identificador único da página. |
| `name` | string | Nome da página (definido pelo produtor). |
| `page_order` | integer | Ordem sequencial da página no módulo. |
| `type` | string | Tipo da página: `CONTENT`, `ADVERTISEMENT`, `QUIZ`, `WEBINAR`. |
| `published` | boolean | Se a página está publicada para os usuários. |
| `total_comments` | long | Total de comentários na página. |
| `rates_average` | double | Média de avaliações dos usuários. |
| `rates` | array | Avaliações detalhadas (abaixo). |
| `has_media` | boolean | `true` se a página possui mídia relacionada. |
| `dripping_configs` | array | Agendamentos de liberação/expiração (abaixo). |

### `rates[]`

| Campo | Descrição |
|---|---|
| `rate` | Indicador da avaliação: `1` Ruim, `2` Razoável, `3` Bom, `4` Muito bom, `5` Excelente. |
| `total` | Quantidade total de avaliações para esse `rate`. |

### `dripping_configs[]`

| Campo | Descrição |
|---|---|
| `liberation` | Configuração de liberação (abaixo). |
| `expiration` | Configuração de expiração (abaixo). |
| `classes` | Turmas às quais os agendamentos se aplicam. **Lista vazia = todas as turmas.** |

#### `liberation`

| Campo | Descrição |
|---|---|
| `type` | `BY_DAYS`, `BY_DATE` ou `BY_QUIZ`. |
| `liberation_date` | Data de liberação (quando `type = BY_DATE`). |
| `liberation_days` | Dias após a compra (quando `type = BY_DAYS`). |
| `page_id` | Quiz a concluir para liberar (quando `type = BY_QUIZ`). |

#### `expiration`

| Campo | Descrição |
|---|---|
| `type` | Atualmente apenas `BY_DAYS`. |
| `duration_days` | Dias após a compra em que a página expira. |

#### `classes[]`

| Campo | Descrição |
|---|---|
| `id` | Identificador único da turma. |
| `name` | Nome da turma. |
| `default_class` | Se é uma turma padrão. |

## Exemplo de resposta (200 - Success)

```json
[
    {
        "page_id": "RE4zW6m6el",
        "name": "Dripping 100 days",
        "type": "CONTENT",
        "page_order": 1,
        "total_comments": 0,
        "rates": [],
        "rates_average": 0.0,
        "published": true,
        "has_media": false,
        "dripping_configs": [
            {
                "liberation": {
                    "type": "BY_DAYS",
                    "liberation_days": 200
                },
                "expiration": {
                    "type": "BY_DAYS",
                    "duration_days": 120
                },
                "classes": []
            }
        ]
    },
    {
        "page_id": "B146nbrx4d",
        "name": "Dripping BY_DATE",
        "type": "CONTENT",
        "page_order": 2,
        "total_comments": 5,
        "rates": [
            {
                "rate": 3,
                "total": 1
            },
            {
                "rate": 5,
                "total": 1
            }
        ],
        "rates_average": 4.0,
        "published": true,
        "has_media": false,
        "dripping_configs": [
            {
                "liberation": {
                    "type": "BY_DATE",
                    "liberation_date": "2020-03-27T03:00:00Z"
                },
                "classes": [
                    {
                        "id": "0Z725jyeNm",
                        "name": "DEFAULT_CLASS",
                        "default_class": true
                    },
                    {
                        "id": "QLO0gbB7GM",
                        "name": "Advanced Class",
                        "default_class": false
                    }
                ]
            },
            {
                "liberation": {
                    "type": "BY_QUIZ",
                    "page_id": "Xm7YgJWD46"
                },
                "classes": [
                    {
                        "id": "Pk45vnqPel",
                        "name": "Bonus Class",
                        "default_class": false
                    }
                ]
            }
        ]
    },
    {
        "page_id": "B146nbG34d",
        "name": "Offer product",
        "type": "ADVERTISEMENT",
        "page_order": 3,
        "total_comments": 0,
        "rates": [],
        "rates_average": 0.0,
        "published": true,
        "has_media": false,
        "dripping_configs": []
    }
]
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `product_id` | `123456789` |
| | | `module_id` | `2Z7RAMXEJW`, `D64L09Q4JW`, `DPEA5MOEWE`, `J14OKVB4PL`, `V94JMXYOGZ` |
| `product_id` é obrigatório | `422` | sem parâmetros | — |
