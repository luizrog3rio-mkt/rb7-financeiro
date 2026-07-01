# Endpoint: Participantes de Vendas

> Referência: documentação Hotmart Developers — seção "Vendas" > "Participantes de vendas".

Exibe informações sobre os **participantes** das vendas — comprador, produtor, afiliado ou co-produtor — com nome, endereço, telefone, documentos e outros dados.

`GET /payments/api/v1/sales/users`

> **Atenção ao filtro de status.** Se você **não** informar `transaction` nem `transaction_status`, a API retorna **apenas os status `APPROVED` e `COMPLETE`**.

## Parâmetros da requisição (query)

> Datas em **milissegundos**, a partir de `1970-01-01 00:00:00 UTC`.

| Parâmetro | Descrição |
|---|---|
| `max_results` | Número máximo de itens por página. |
| `page_token` | Cursor de paginação. |
| `product_id` | ID do produto vendido (7 dígitos). |
| `start_date` | Data inicial do período (filtro). |
| `end_date` | Data final do período (filtro). |
| `buyer_email` | E-mail do comprador (útil para buscar compras específicas). |
| `sales_source` | Código SRC do link de pagamento (origem). |
| `transaction` | Código único da transação (ex.: `HP17715690036014`). |
| `buyer_name` | Nome do comprador. |
| `affiliate_name` | Nome do Afiliado responsável pela venda (quando aplicável). |
| `commission_as` | Como o usuário foi comissionado: `PRODUCER`, `COPRODUCER`, `AFFILIATE`. |
| `transaction_status` | Status da compra (valores abaixo). |

### Valores de `transaction_status`

`APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, `PROTESTED`, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT`.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/sales/users?product_id=123' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer :access_token'
```

## Retorno — `items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `transaction` | string | Código único da transação. |
| `product` | object | Dados do produto (`name`, `id`). |
| `users` | array | Lista de participantes da venda (abaixo). |

### `users[]`

| Campo | Descrição |
|---|---|
| `role` | Tipo do participante: `PRODUCER`, `BUYER`, `COPRODUCER`, `AFFILIATE`. |
| `user` | Dados do participante (abaixo). |

> Para recuperar o comprador, filtre por `role == "BUYER"`.

#### `users[].user`

| Campo | Descrição |
|---|---|
| `ucode` | Identificador único do participante. |
| `locale` | País + idioma do participante (obtido via IP do dispositivo). |
| `name` | Nome do participante. |
| `trade_name` | Nome fantasia do participante. |
| `cellphone` | Celular. Em venda internacional, o DDI vem junto — **apenas para o participante `BUYER`**. |
| `phone` | Telefone. Mesma regra de DDI (apenas `BUYER`). |
| `email` | E-mail do participante. |
| `documents` | Documentos identificadores (abaixo). |
| `address` | Endereço completo (abaixo). |

##### `documents[]`

| Campo | Descrição |
|---|---|
| `value` | Registro identificador do documento. |
| `type` | Tipo: `CPF`, `CNPJ`, `RG`, `DNI`, `CIF` ou `DOCUMENT`. |

##### `address`

| Campo | Descrição |
|---|---|
| `city` | Cidade. |
| `state` | Estado. |
| `country` | País. |
| `zip_code` | Código postal. |
| `address` | Nome da rua. |
| `complement` | Complemento. |
| `neighborhood` | Bairro. |
| `number` | Número da residência. |

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
      "transaction": "HP10014546320130",
      "product": {
        "name": "Product 1",
        "id": 178598
      },
      "users": [
        {
          "role": "PRODUCER",
          "user": {
            "ucode": "c9e5e3f4-097e-11e4-be45-22000b409f8a",
            "locale": "FR",
            "name": "Producer Name",
            "trade_name": "Producer Trade Name",
            "cellphone": "1199999999",
            "phone": "6825565681",
            "email": "producerEmail@email.com",
            "documents": [
              {
                "value": "564654",
                "type": "DOCUMENT"
              },
              {
                "value": "68658197646",
                "type": "CPF"
              }
            ],
            "address": {
              "city": "Campo Grande",
              "state": "Campo Grande",
              "country": "Brasil",
              "zip_code": "1213454",
              "address": "Rua Carlos Fortunato Paiva",
              "complement": "",
              "neighborhood": "",
              "number": "123"
            }
          }
        }
      ]
    }
  ],
  "page_info": {
    "total_results": 55,
    "next_page_token": "eyJwYWdlIjoyLCJyb3dzIjozfQ==",
    "results_per_page": 1
  }
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `buyer_email` | `buyeremail2@dominio.com` |
| | | `sales_source` | `campaignNameanha3` |
| | | `buyer_name` | `buyername2` |
| | | `affiliate_name` | `affilatename1` |
| | | `start_date` | `1622689200000` |
| | | `end_date` | `1622948400000` |
