# Webhook — Evento de abandono de carrinho

> Referência: documentação Hotmart Developers — seção "Webhook" > "Evento de abandono de carrinho".
> **Versão:** `2.0.0` · **event:** `PURCHASE_OUT_OF_SHOPPING_CART` · **Formato:** JSON

Disparado quando uma pessoa desiste de comprar na sua página de pagamento. Traz dados do possível comprador (lead), do produto que seria adquirido e mais.

## Como o disparo funciona

- O processo começa quando a pessoa **preenche dados na página de pagamento** (nome e/ou e-mail).
- Abrange tanto possíveis compradores quanto quem deixou a página aberta por muito tempo.
- A verificação é feita **a cada 30 minutos**.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`**. **Valide-o antes de tratar os dados.** |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único de identificação do evento. |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento — sempre `PURCHASE_OUT_OF_SHOPPING_CART`. |
| `version` | string | Versão do evento — sempre `2.0.0`. |
| `data` | object | Dados do abandono (abaixo). |

## `data`

| Campo | Tipo | Descrição |
|---|---|---|
| `affiliate` | boolean | `true` se a origem do lead é de um afiliado; `false` caso contrário. |
| `product` | object | Produto que seria adquirido (`id`, `name`). |
| `buyer` | object | Dados do comprador (abaixo). **Só retornado se o lead disponibilizou os dados;** os campos solicitados são definidos pelo Produtor nas configurações do Checkout. |
| `offer` | object | Oferta da página de pagamento (`code` — identificador da oferta principal). |
| `checkout_country` | object | País selecionado pelo lead no checkout (abaixo). |

### `data.buyer`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Nome completo do lead. |
| `email` | string | E-mail do lead. |
| `phone` | string | Telefone do lead. **Em vendas internacionais (comprador fora do Brasil), o DDI vem junto ao telefone.** |

> O comprador (lead) pode ser apenas quem pagaria pelo produto, não necessariamente quem o usaria.

### `data.checkout_country`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | País selecionado no checkout. |
| `iso` | string | País no formato **ISO 3166 Alpha-2** (ex.: `BR`). |

## Exemplo de payload

```json
{
  "id": "0d7aa966-b887-4617-8c56-9e865bfc8ce4",
  "creation_date": 1632411406874,
  "event": "PURCHASE_OUT_OF_SHOPPING_CART",
  "version": "2.0.0",
  "data": {
    "affiliate": true,
    "product": {
      "id": 3526906,
      "name": "Product Name"
    },
    "buyer": {
      "name": "Buyer name",
      "email": "buyer@email.com.br",
      "phone": "31999999999"
    },
    "offer": {
      "code": "n82b9jqz"
    },
    "checkout_country": {
      "name": "Brasil",
      "iso": "BR"
    }
  }
}
```
