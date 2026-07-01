# Endpoint: Informações do Evento

> Referência: documentação Hotmart Developers — seção "Ingressos para eventos" > "Informações do Evento".

Exibe as informações de um evento e seus atributos (nome, datas e lotes).

`GET /events/api/v1/:event_id/info`

## Parâmetros da requisição (path)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `event_id` | sim | ID do produto **no formato Ingresso para Eventos**. |

### Requisição

```bash
curl --location 'https://developers.hotmart.com/events/api/v1/:event_id/info' \
--header 'Authorization: Bearer :access_token'
```

## Retorno

| Campo | Tipo | Descrição |
|---|---|---|
| `product` | object | Produto: `name` e `id`. |
| `start_event_date` | long | Data de início do evento (ms desde 1970-01-01 UTC). |
| `end_event_date` | long | Data de fim do evento (ms desde 1970-01-01 UTC). |
| `lots` | array | Lotes do evento (abaixo). **Usados também para definir categorias de ingressos.** |

### `lots[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | long | ID do lote. |
| `name` | string | Nome do lote. |

## Exemplo de resposta (200)

```json
{
    "product": {
        "name": "Product Name",
        "id": 4744896
    },
    "start_event_date": 1656007620000,
    "end_event_date": 1677607680000,
    "lots": [
        {
            "id": 234900,
            "name": "Lote 1 - Teste"
        },
        {
            "id": 234901,
            "name": "Lote gratuito - Teste"
        }
    ]
}
```

> O `id` dos lotes é usado como filtro `lote` nas demais consultas de [ingressos e participantes](./ingressos-eventos-introducao.md).
