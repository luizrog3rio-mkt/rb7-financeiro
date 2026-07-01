# Endpoint: Lista de ingressos e participantes

> Referência: documentação Hotmart Developers — seção "Ingressos para eventos" > "Lista de ingressos e participantes".

Lista os ingressos de um evento com seus respectivos compradores e participantes (quem de fato usa o ingresso para acessar o evento).

> **Apenas ingressos com pagamento confirmado e convites gratuitos são listados.**

`GET /events/api/v1/:event_id/participants`

## Parâmetros da requisição

### Path

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `event_id` | sim | ID do produto **no formato Ingresso para Eventos**. |

### Query

| Parâmetro | Descrição |
|---|---|
| `max_results` | Número máximo de itens por página. |
| `page_token` | Cursor de paginação. |
| `buyer_email` | E-mail do comprador. |
| `participant_email` | E-mail do participante. |
| `last_update` | Data da última atualização do ingresso (ms desde 1970-01-01 UTC). |
| `id_lot` | ID do lote de origem (também representa a categoria do ingresso). |
| `ticket_status` | Status do ingresso (valores abaixo). |
| `ticket_type` | Tipo do ingresso: `PAID`, `FREE`, `ALL`. |
| `checkin_status` | Status de preenchimento dos dados de inscrição: `PENDING`, `PARTIAL`, `CONCLUDED`, `ALL`. |
| `id_eticket` | ID sequencial do ingresso (controle interno). |
| `ticket_qr_code` | Código único do ingresso (QR Code), para controle de entrada. |

### Valores de `ticket_status`

| Valor | Definição |
|---|---|
| `SOLD` | Ingresso com pagamento confirmado. |
| `INVITE` | Convite enviado. |
| `INVITE_CANCELED` | Convite removido. |
| `REFUNDED` | Ingresso reembolsado (perdeu a validade). |
| `CHARGEBACK` | Ingresso com chargeback. |
| `EXCLUDED` | Ingresso excluído. |
| `AVAILABLE` | Disponível e ainda não atribuído a um participante. |
| `RESERVED` | Pagamento pendente ou convite gratuito atribuído a alguém. |

### Requisição

```bash
curl --location 'https://developers.hotmart.com/events/api/v1/:event_id/participants' \
--header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

### `buyer`

| Campo | Descrição |
|---|---|
| `ucode` | ID/ucode do comprador (UUID). |
| `name` | Nome completo do comprador. |
| `email` | E-mail do comprador. |

### `participant`

| Campo | Descrição |
|---|---|
| `id` | ID do participante. |
| `name` | Nome completo do participante. |
| `email` | E-mail do participante. |
| `document` | Documento (CPF, RG ou outro) do participante. |
| `phone` | Telefone do participante. |

### `eticket`

| Campo | Descrição |
|---|---|
| `ticket_qr_code` | Código do ingresso (QR Code). |
| `current_update` | Data da última atualização. |
| `checkin_status` | Status do check-in (pendente ou concluído). |
| `is_blocked` | Status de bloqueio do ingresso (`true`/`false`). |
| `ticket_status` | Status do ticket. |
| `ticket_type` | Tipo do ingresso (pago ou gratuito). |
| `id` | ID do eticket. |
| `checkin_url` | URL de check-in (link que o comprador recebe por e-mail). |

### `lot`

| Campo | Descrição |
|---|---|
| `id` | ID do lote (também define a categoria do ingresso). |
| `name` | Nome do lote (também define a categoria do ingresso). |

### `product`

| Campo | Descrição |
|---|---|
| `id` | ID do produto. |
| `name` | Nome do produto. |

### `page_info`

| Campo | Descrição |
|---|---|
| `results_per_page` | Itens da página atual. |
| `next_page_token` | Referência da próxima página (ausente na última). |
| `total_results` | Total de itens da lista (desconsiderando paginação). |

## Exemplo de resposta (200)

```json
{
    "items": [
        {
            "participant": {
                "email": "teste+1@teste.com",
                "document": "68658197646",
                "id": 2190,
                "name": "Teste teste +1",
                "phone": 31999999999
            },
            "buyer": {
                "ucode": "ae9c122f-e7e1-4fc3-8ef7-d32ddb2bfa3a",
                "email": "teste+1@teste.com",
                "name": "Meu Teste"
            },
            "eticket": {
                "ticket_qr_code": "132591264870940362",
                "current_update": 1655906699333,
                "checkin_status": "CONCLUDED",
                "is_blocked": false,
                "ticket_status": "SOLD",
                "ticket_type": "PAID",
                "id": 6892768,
                "checkin_url": "https://sandbox-local.com/eticket/2e9c43a9-0aeb-48ed-9464-630f845c23af?invite=false"
            },
            "lot": {
                "id": 234900,
                "name": "Lote 1"
            },
            "product": {
                "id": 4744896,
                "name": "Product Name"
            }
        }
    ],
    "page_info": {
        "results_per_page": 1,
        "next_page_token": "eyJwYWdlIjoyLCJyb3dzIjoxfQ==",
        "total_results": 5
    }
}
```

> O `lot.id` corresponde ao `id` dos lotes retornados em [Informações do Evento](./endpoint-informacoes-evento.md). Os identificadores diferem por entidade: comprador usa `ucode` (UUID); participante usa `id` (numérico).
