# Webhook — Evento de dado logístico

> Referência: documentação Hotmart Developers — seção "Webhook" > "Evento de dado logístico".
> **Versão:** `2.0.0` · **event:** `ORDER_FULFILLMENT` · **Formato:** JSON

Disparado quando uma **compra aprovada de produto físico** gera um dado logístico. Traz informações de compra, itens, entrega, frete, serviço de fulfillment e cobrança.

> A aba da documentação é **Creator**.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`**. **Valide-o antes de tratar os dados.** |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único do evento (**UUID v4**). |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento — sempre `ORDER_FULFILLMENT`. |
| `version` | string | Versão do evento — sempre `2.0.0`. |
| `data` | object | Dados logísticos (abaixo). |

> **Objeto de endereço (reutilizado):** `address` (logradouro), `number`, `complement`, `neighborhood`, `city`, `state`, `zip_code`, `country`.

---

## `data.purchase`

| Campo | Tipo | Descrição |
|---|---|---|
| `full_price` | object | Valor total pago (com taxas/juros): `value`, `currency_value` (ISO 4217). |
| `price` | object | Valor da oferta no momento da compra: `value`, `currency_value`. |
| `approved_date` | long | Data de aprovação (ms). |
| `order_date` | long | Data do pedido (ms). |
| `id` | long | Identificador da compra. |
| `transaction` | string | Código de referência da transação (ex.: `HP17163000001234`). |
| `status` | string | Status da compra — neste evento sempre `APPROVED`. |
| `shopper` | object | Quem realizou a compra (abaixo). |

### `data.purchase.shopper`

`country`, `phone`, `document`, `name`, `time_zone` (ex.: `America/Sao_Paulo`), `locale` (ex.: `pt_BR`), `ucode` (identificador na Hotmart), `email`, `address` (objeto de endereço).

## `data.line_items[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `offer` | object | `price` (`value`, `currency_value`) e `code` da oferta. |
| `product` | object | Produto físico (abaixo). |
| `quantity` | integer | Quantidade do item no pedido. |
| `variant` | object | Variação selecionada (abaixo). |
| `dimension` | object | Dimensões físicas para cálculo de frete (abaixo). |

### `line_items.product`

`id`, `name`, `format` (= `PHYSICAL`), `support_email`, `ucode`, e `seller` (`name`, `email`, `ucode`, `locale`).

### `line_items.variant`

`name` (ex.: `Tamanho M - Azul`), `id`, `sku`, e `attributes[]` com `name` e `value` (ex.: Tamanho/M, Cor/Azul).

### `line_items.dimension`

| Campo | Unidade | Descrição |
|---|---|---|
| `depth` | cm | Profundidade/comprimento. |
| `width` | cm | Largura. |
| `height` | cm | Altura. |
| `weight` | kg | Peso. |

## `data.delivery`

| Campo | Descrição |
|---|---|
| `shipping_processing_time` | Tempo adicional de manuseio/preparação (dias), configurado pelo produtor. |
| `method_type` | Tipo do método de entrega (ex.: `SHIPPING`). |
| `delivery_time` | Prazo estimado de entrega (dias úteis). |
| `destination` | Endereço de destino (objeto de endereço). |

## `data.shipping`

| Campo | Descrição |
|---|---|
| `shipping_total_value` | Valor total do frete cobrado do comprador (`value`, `currency_value`). `0` = grátis. |
| `carrier` | Transportadora: `name` (ex.: `CORREIOS`), `code`. |
| `shipping_logistics_time` | Tempo estimado de transporte (dias). |
| `carrier_options` | Serviço: `service` (ex.: `SEDEX`, `PAC`), `code` (ex.: `04014`). |
| `type` | Tipo de envio: `FLAT_RATE`, `FREE_SHIPPING`, `FIXED_PRICE`. |
| `estimate_shipping_cost` | Custo estimado calculado pela transportadora (`value`, `currency_value`). |
| `shipping_markup_price` | Valor adicional de frete configurado pelo produtor — markup (`value`, `currency_value`). |

## `data.fulfillment_service`

| Campo | Descrição |
|---|---|
| `service_type` | `MANUAL` quando o produtor gerencia o envio; `PARTNER` quando um parceiro gerencia. |
| `service_name` | Nome do serviço (ex.: `UICLAP`, `MONTINK`). **Preenchido apenas quando `service_type` = `PARTNER`.** |

## `data.billing`

> Pessoa responsável pelo **pagamento** (pode diferir do `shopper`).

`country`, `phone`, `document`, `name`, `time_zone`, `locale`, `ucode`, `email`, `address` (objeto de endereço).

## Exemplo de payload

```json
{
  "id": "27b52d28-acf4-448a-bc5f-4ab4bc8dcb35",
  "creation_date": 1716400000000,
  "event": "ORDER_FULFILLMENT",
  "version": "2.0.0",
  "data": {
    "purchase": {
      "full_price": {
        "value": 99.90,
        "currency_value": "BRL"
      },
      "price": {
        "value": 89.90,
        "currency_value": "BRL"
      },
      "approved_date": 1716300000000,
      "order_date": 1716200000000,
      "id": 12345678,
      "transaction": "HP17163000001234",
      "status": "APPROVED",
      "shopper": {
        "country": "Brasil",
        "phone": "31999999999",
        "document": "12345678900",
        "name": "João Silva",
        "time_zone": "America/Sao_Paulo",
        "locale": "pt_BR",
        "ucode": "USER_UCODE_123",
        "email": "joao@email.com",
        "address": {
          "address": "Rua Exemplo",
          "number": "100",
          "complement": "Apto 1",
          "neighborhood": "Centro",
          "city": "Belo Horizonte",
          "state": "MG",
          "zip_code": "30130000",
          "country": "Brasil"
        }
      }
    },
    "line_items": [
      {
        "offer": {
          "price": {
            "value": 89.90,
            "currency_value": "BRL"
          },
          "code": "offer_abc123"
        },
        "product": {
          "id": 9876543,
          "name": "Camiseta Premium",
          "seller": {
            "name": "Maria Produtora",
            "email": "maria@email.com",
            "ucode": "SELLER_UCODE_456",
            "locale": "pt_BR"
          },
          "format": "PHYSICAL",
          "support_email": "suporte@produto.com",
          "ucode": "PROD_UCODE_789"
        },
        "quantity": 2,
        "variant": {
          "name": "Tamanho M - Azul",
          "id": "var_001",
          "attributes": [
            {
              "name": "Tamanho",
              "value": "M"
            },
            {
              "name": "Cor",
              "value": "Azul"
            }
          ],
          "sku": "SKU-CAM-M-AZ"
        },
        "dimension": {
          "depth": 5.0,
          "width": 30.0,
          "weight": 0.3,
          "height": 2.0
        }
      }
    ],
    "delivery": {
      "shipping_processing_time": 2,
      "method_type": "SHIPPING",
      "delivery_time": 5,
      "destination": {
        "address": "Rua Destino",
        "number": "200",
        "complement": "",
        "neighborhood": "Savassi",
        "city": "Belo Horizonte",
        "state": "MG",
        "zip_code": "30140000",
        "country": "Brasil"
      }
    },
    "shipping": {
      "shipping_total_value": {
        "value": 15.90,
        "currency_value": "BRL"
      },
      "carrier": {
        "name": "CORREIOS",
        "code": "COR"
      },
      "shipping_logistics_time": 5,
      "carrier_options": {
        "service": "SEDEX",
        "code": "04014"
      },
      "type": "FLAT_RATE",
      "estimate_shipping_cost": {
        "value": 12.50,
        "currency_value": "BRL"
      },
      "shipping_markup_price": {
        "value": 3.40,
        "currency_value": "BRL"
      }
    },
    "fulfillment_service": {
      "service_type": "MANUAL"
    },
    "billing": {
      "country": "Brasil",
      "phone": "31999999999",
      "document": "12345678900",
      "name": "João Silva",
      "time_zone": "America/Sao_Paulo",
      "locale": "pt_BR",
      "ucode": "USER_UCODE_123",
      "email": "joao@email.com",
      "address": {
        "address": "Rua Cobrança",
        "number": "300",
        "complement": "",
        "neighborhood": "Funcionários",
        "city": "Belo Horizonte",
        "state": "MG",
        "zip_code": "30130001",
        "country": "Brasil"
      }
    }
  }
}
```
