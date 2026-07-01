# Webhook — Eventos de pedidos

> Referência: documentação Hotmart Developers — seção "Webhook" > "Eventos de pedidos".
> **Versão:** `2.0.0` · **Formato:** JSON

Disparado a cada compra do seu produto. Traz dados do comprador, produto, pagamento, comissões, assinatura e mais. É o payload mais completo dos webhooks.

> A documentação tem abas **Produtor(a)**, **Coprodutor(a)** e **Afiliado(a)**; o payload abaixo é o da visão **Produtor(a)**.

## Valores de `event`

`PURCHASE_CANCELED`, `PURCHASE_COMPLETE`, `PURCHASE_BILLET_PRINTED`, `PURCHASE_APPROVED`, `PURCHASE_PROTEST`, `PURCHASE_REFUNDED`, `PURCHASE_CHARGEBACK`, `PURCHASE_EXPIRED`, `PURCHASE_DELAYED`.

## Autenticação (header)

| Campo | Descrição |
|---|---|
| `hottok` | Token único da conta, enviado no cabeçalho HTTP como **`X-HOTMART-HOTTOK`**. **Valide-o antes de tratar os dados.** |

## Envelope do evento

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | string | Código único de identificação do evento. |
| `creation_date` | long | Data de criação do evento (ms desde 1970-01-01 UTC). |
| `event` | string | Nome do evento (ver valores acima). |
| `version` | string | Versão do evento — sempre `2.0.0`. |
| `data` | object | Dados da venda (abaixo). |

---

## `data.product`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | integer | Identificador do produto adquirido. |
| `ucode` | string | Identificador único (UUID) — **use este para identificar o produto no seu sistema**. |
| `name` | string | Nome do produto. No Hotmart Club pode equivaler ao nome da área de membros e divergir do nome cadastrado na conta. |
| `has_co_production` | boolean | Se o produto possui coprodutor. |
| `warranty_date` | string | Vencimento da garantia (`YYYY-MM-DDThh:mm:ssTZD`). |
| `support_email` | string | E-mail de suporte (ou o padrão da conta, se não personalizado). |
| `is_physical_product` | boolean | Se é produto físico. |
| `content` | object | Dados do combo (abaixo). |

### `data.product.content`

| Campo | Tipo | Descrição |
|---|---|---|
| `has_physical_products` | boolean | Se há produto físico entre os itens do combo. |
| `products` | array | Itens do combo: `id`, `ucode`, `name`, `is_physical_product`. |

## `data.affiliates[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `affiliate_code` | string | Identificador do afiliado que indicou a venda. |
| `name` | string | Nome do afiliado. |

## `data.buyer`

> As informações só vêm se o comprador as disponibilizou; os campos solicitados são definidos pelo Produtor no Checkout.

| Campo | Tipo | Descrição |
|---|---|---|
| `email` | string | E-mail do comprador. |
| `name` | string | Nome completo. |
| `first_name` | string | Primeiro nome. |
| `last_name` | string | Último nome. |
| `checkout_phone` | string | Telefone (preenchido no checkout). Em venda internacional, o **DDI vem junto ao telefone**. |
| `checkout_phone_code` | string | DDD — enviado apenas para compradores brasileiros. |
| `document` | string | Documento do comprador. |
| `document_type` | string | Tipo do documento: `CPF`/`CNPJ` (BR), `DNI`/`CIF` (ES), `DOCUMENT` (demais países). |
| `address` | object | Endereço (abaixo). |

### `data.buyer.address`

`country_iso` (ISO 3166 Alpha-2), `country`, `zipcode`, `state`, `city`, `neighborhood`, `street`/`address`, `complement`, `number`.

> O endereço vem do checkout (se solicitado) ou do cadastro do comprador. Se não houver cadastro, os campos não são enviados.

## `data.producer`

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Nome do produtor. |
| `document` | string | Documento do produtor. |
| `legal_nature` | string | Natureza jurídica (só produtores brasileiros): `Pessoa Física` ou `Pessoa Jurídica`. |

## `data.commissions[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `value` | double | Valor da comissão. |
| `currency_value` | string | Moeda da comissão (ISO 4217, ex.: `BRL`, `USD`). |
| `source` | string | Fonte da comissão (ver valores abaixo). |
| `currency_conversion` | object | Conversão de moeda: `converted_value`, `converted_to_currency`, `conversion_rate`. |

### Valores de `commissions.source`

`PRODUCER`, `COPRODUCER`, `AFFILIATE`, `ADDON`.

> **Nota:** o exemplo de payload da documentação também traz `MARKETPLACE` (comissão da Hotmart) em `source`, embora não esteja na lista descritiva. Trate-o ao mapear comissões.

---

## `data.purchase`

| Campo | Tipo | Descrição |
|---|---|---|
| `approved_date` | long | Data de liberação da compra (ms). |
| `full_price` | object | Valor total pago (com taxas/juros): `value`, `currency_value`. |
| `original_offer_price` | object | Valor da oferta principal: `value`, `currency_value`. |
| `price` | object | Valor da oferta no momento da compra: `value`, `currency_value`. |
| `offer` | object | Dados da oferta (abaixo). |
| `recurrence_number` | integer | Número da recorrência em que a assinatura está. |
| `subscription_anticipation_purchase` | boolean | Se é compra de renovação antecipada. |
| `origin` | object | UTMs: `src` (página de vendas), `sck` (checkout), `xcod` (personalizado). |
| `checkout_country` | object | País do checkout: `name`, `iso` (ISO 3166 Alpha-2). |
| `order_bump` | object | Order Bump (abaixo). |
| `order_date` | string | Data do pedido (para recorrentes, refere-se a cada renovação). |
| `date_next_charge` | long | Data da próxima cobrança (ms). |
| `status` | string | Status da compra (ver enum abaixo). |
| `transaction` | string | Código de referência da transação (ex.: `HP17715690036014`). |
| `payment` | object | Dados do pagamento (abaixo). |
| `invoice_by` | string | Responsável pela nota fiscal: `HOTMART` ou `SELLER`. |
| `is_funnel` | boolean | Se a compra fez parte de um Funil de Vendas Hotmart. |
| `event_tickets` | object | Ingressos de evento: `amount` (quantidade adquirida). |
| `business_model` | string | Modelo fiscal: `R`, `A` ou `I` (abaixo). |
| `variants` | object | Variação do produto selecionada (abaixo). Só quando há variação configurada. |

### `purchase.offer`

`code` (oferta adquirida), `coupon_code` (cupom usado, se houver), `name`, `description`. Para pagamento recorrente, o nome do plano vem em `subscription.plan.name`. Campos sem valor cadastrado não são retornados.

### `purchase.order_bump`

| Campo | Descrição |
|---|---|
| `is_order_bump` | `true` se a transação é Order Bump. |
| `parent_purchase_transaction` | Transação pai. **Se vier vazio com `is_order_bump = true`, a própria compra é a pai.** |

### Valores de `purchase.status`

`APPROVED`, `BLOCKED`, `CANCELLED`, `CHARGEBACK`, `COMPLETE`, `EXPIRED`, `NO_FUNDS`, `OVERDUE`, `PARTIALLY_REFUNDED`, `PRE_ORDER`, `PRINTED_BILLET`, `PROCESSING_TRANSACTION`, `DISPUTE`, `REFUNDED`, `STARTED`, `UNDER_ANALISYS`, `WAITING_PAYMENT`.

> `UNDER_ANALISYS` é grafado **literalmente assim** na API (com "I", não "UNDER_ANALYSIS"). Use o valor exato ao comparar.

### `purchase.payment`

| Campo | Descrição |
|---|---|
| `billet_barcode` | Código de barras do boleto (só em boleto). |
| `billet_url` | Link para reimprimir o boleto (só em boleto). |
| `installments_number` | Número de parcelas (compra parcelada em BRL, MXN ou COP). |
| `pix_code` | Pix copia e cola (só em Pix). |
| `pix_expiration_date` | Data limite do Pix (ms). |
| `pix_qrcode` | Link do QR code do Pix (só em Pix). |
| `refusal_reason` | Texto de recusa do pagamento pela operadora. |
| `type` | Tipo de pagamento (ver enum abaixo). |

#### Valores de `payment.type`

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

### `purchase.business_model`

| Valor | Significado |
|---|---|
| `R` | A Hotmart emite a nota fiscal para o comprador. |
| `A` | O produtor emite a nota pela entidade legal da Hotmart no exterior. |
| `I` | O produtor emite a nota pela entidade legal da Hotmart no Brasil. |

### `purchase.variants`

`sku` (opcional) e `attributes[]` com `name` e `value` (ex.: Tamanho/Médio, Cor/Azul, Sabor/Chocolate).

---

## `data.shipping`

> Omitido do payload quando não há frete (ex.: produto digital).

| Campo | Descrição |
|---|---|
| `cost` | `value` (0 = frete grátis) e `currency_value` (ISO 4217). |
| `estimated_delivery_days` | Prazo estimado (transportadora + manuseio). |
| `carrier` | Transportadora: `name` (ex.: `CORREIOS`), `service` (ex.: `SEDEX`, `PAC`). |
| `fulfillment` | `service`: `MANUAL` quando não é print-on-demand; nome do serviço (ex.: `UICLAP`, `MONTINK`) quando sob demanda. |

## `data.subscription`

> Só presente quando a venda é de um produto de assinatura.

| Campo | Descrição |
|---|---|
| `status` | Status da assinatura (ver enum abaixo). |
| `plan` | `id`, `name` (nome do plano, só em venda de assinatura). |
| `subscriber.code` | Código exclusivo do assinante. Um mesmo comprador terá `code` diferentes por produto. |

### Valores de `subscription.status`

`ACTIVE`, `INACTIVE`, `DELAYED`, `CANCELLED_BY_CUSTOMER`, `CANCELLED_BY_SELLER`, `CANCELLED_BY_ADMIN`, `STARTED`, `OVERDUE`.

> **Atenção (inconsistência entre eventos):** aqui os cancelamentos são `CANCELLED_BY_CUSTOMER` / `CANCELLED_BY_SELLER` / `CANCELLED_BY_ADMIN` (dois "L", `SELLER`). No [Evento de troca de plano](./webhook-evento-troca-plano.md) são `CANCELED_BY_*` (um "L", `VENDOR`). Mais um motivo para normalizar os status ao integrar.

## Exemplo de payload

```json
{
  "id": "1234567890123456789",
  "creation_date": 12345678,
  "event": "PURCHASE_APPROVED",
  "version": "2.0.0",
  "data": {
    "product": {
      "id": 213344,
      "ucode": "2e9c43a9-0aeb-48ed-9464-630f845c23af",
      "name": "Product Name",
      "has_co_production": false,
      "warranty_date": "2017-12-27T00:00:00Z",
      "support_email": "support@email.com",
      "is_physical_product": false,
      "content": {
        "has_physical_products": true,
        "products": [
          {
            "id": 4774438,
            "ucode": "559fef42-3406-4d82-b775-d09bd33936b1",
            "name": "Product Name 1",
            "is_physical_product": false
          },
          {
            "id": 4999597,
            "ucode": "099e7644-b7d1-43d6-82a9-ec6be0118a4b",
            "name": "Physical product",
            "is_physical_product": true
          }
        ]
      }
    },
    "affiliates": [
      {
        "affiliate_code": "Q58388177J",
        "name": "Affiliate name"
      }
    ],
    "buyer": {
      "email": "buyer@email.com",
      "name": "Buyer Name",
      "first_name": "Buyer",
      "last_name": "Name",
      "checkout_phone": "999999999",
      "checkout_phone_code": "31",
      "document": "123456789",
      "document_type": "CPF",
      "address": {
        "zipcode": "30150101",
        "country": "Brasil",
        "number": "499",
        "address": "Avenida Assis Chateaubriand",
        "city": "Belo Horizonte",
        "state": "MG",
        "neighborhood": "Floresta",
        "complement": "a complement",
        "country_iso": "BR"
      }
    },
    "producer": {
      "name": "Producer Name",
      "legal_nature": "Pessoa Física",
      "document": "12345678965"
    },
    "commissions": [
      {
        "value": 0.65,
        "currency_value": "BRL",
        "source": "MARKETPLACE"
      },
      {
        "value": 3.10,
        "currency_value": "USD",
        "source": "PRODUCER",
        "currency_conversion": {
          "converted_value": 16.34,
          "converted_to_currency": "BRL",
          "conversion_rate": 5.271103
        }
      }
    ],
    "purchase": {
      "approved_date": 1231241434453,
      "full_price": {
        "value": 134.0,
        "currency_value": "BRL"
      },
      "original_offer_price": {
        "currency_value": "EUR",
        "value": 150.6
      },
      "price": {
        "value": 150.6,
        "currency_value": "BRL"
      },
      "offer": {
        "code": "n82b9jqz",
        "coupon_code": "ABCDE",
        "name": "Offer name",
        "description": "Offer description"
      },
      "recurrence_number": 1,
      "subscription_anticipation_purchase": false,
      "checkout_country": {
        "name": "Brasil",
        "iso": "BR"
      },
      "origin": {
        "xcod": "xcod_example"
      },
      "order_bump": {
        "is_order_bump": true,
        "parent_purchase_transaction": "HP02316330308193"
      },
      "order_date": "123243546",
      "date_next_charge": 1736337600000,
      "status": "STARTED",
      "transaction": "HP02316330308193",
      "payment": {
        "billet_barcode": "03399.33335 33823.303087 19802.801027 2 87630000015000",
        "billet_url": "https://billet-link.com/bHP02316330308193",
        "installments_number": 2,
        "pix_code": "00020101021226780014br.gov.bcb.pix2556pix-h.juno.com.br/qr/v2/A0ACBEDA916F322FAB94E7DA5B29D0185204000053039865802BR5910EBANX Ltda6008CURITIBA62070503***6304E794",
        "pix_expiration_date": 1645271012000,
        "pix_qrcode": "https://sandbox-local-latam.ebanx.com/pix/checkout?hash=620e34e301fcbdead10d9187a699c4de9e50db35b92da0cd",
        "refusal_reason": "fail",
        "type": "PICPAY"
      },
      "is_funnel": false,
      "event_tickets": {
        "amount": 2
      },
      "business_model": "I",
      "variants": {
        "sku": "HTM_OTAROM-14",
        "attributes": [
          { "name": "Tamanho", "value": "Médio" },
          { "name": "Sabor", "value": "Chocolate" }
        ]
      }
    },
    "shipping": {
      "cost": {
        "value": 25.90,
        "currency_value": "BRL"
      },
      "estimated_delivery_days": 10,
      "carrier": {
        "name": "CORREIOS",
        "service": "SEDEX"
      },
      "fulfillment": {
        "service": "MANUAL"
      }
    },
    "subscription": {
      "status": "ACTIVE",
      "plan": {
        "id": 711459,
        "name": "plan name"
      },
      "subscriber": {
        "code": "12133421"
      }
    }
  }
}
```
