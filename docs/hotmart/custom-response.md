# Custom Response

> Referência: documentação Hotmart Developers — "Custom Response".

## O que é Custom Response?

Custom Response permite **customizar o retorno** das APIs, escolhendo quais dados receber — tornando a integração mais ágil e fácil de entender.

Isso é feito com o query param **`select`**, que define quais atributos estarão no body da resposta. Funciona em **qualquer verbo HTTP** (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`).

> Você recebe apenas os atributos informados; os demais são desconsiderados. Se nenhum atributo for encontrado, o retorno é um **JSON vazio**.

## Parâmetro da requisição

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `select` | string | Lista de atributos desejados, separados por vírgula. |

Regras de uso do `select`:

- **Atributo dentro de um Objeto:** use notação com ponto (ex.: `address.country` para o país do endereço).
- **Atributo dentro de um Array:** use notação com ponto (ex.: `products.name` para o nome dos produtos).
- **Endpoints de Paginação:** atribua ao `select` os atributos contidos em `items` — apenas esses podem ser customizados.

### Requisição

```bash
curl --location --request POST 'https://developers.hotmart.com/payments/api/v1/subscriptions/:subscriber_code/cancel?select=subscriber_code,date_last_recurrence,status' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer :access_token'
```

## Seleção de dados

Considerando a resposta de exemplo abaixo, que tem `id` e `name` (tipos simples), `address` (objeto) e `products` (array de objetos):

### Selecionando o tipo

| Tipo | Query param | Retorno |
|---|---|---|
| simples | `select=id,name` | Dados de `id` e `name`. |
| objetos | `select=address` | Dados do objeto `address`. |
| arrays | `select=products` | Dados do array `products`. |

### Selecionando atributos dentro de objetos/arrays

| Atributos | Query param | Retorno |
|---|---|---|
| objetos | `select=address.country` | Dados de `country` dentro de `address`. |
| arrays | `select=products.name` | Dados de `name` dentro de `products`. |

### Exemplo de resposta (completa)

```json
{
  "id": 123,
  "name": "Producer 01",
  "address": {
    "country": "Brazil",
    "city": "Belo Horizonte"
  },
  "products": [
    {
      "id": 1,
      "name": "Product Name 01"
    },
    {
      "id": 2,
      "name": "Product Name 02"
    },
    {
      "id": 3,
      "name": "Product Name 03"
    }
  ]
}
```
