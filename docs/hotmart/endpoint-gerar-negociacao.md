# Endpoint: Gerar uma negociação

> Referência: documentação Hotmart Developers — seção "Negociação de parcelas" > "Gerar uma negociação".

Gera boletos bancários e Pix de forma automatizada para recuperar inadimplentes de um produto.

`POST /payments/api/v1/installments/negotiate`

## Parâmetros da requisição (body)

> A documentação rotula estes campos como "Path", mas, conforme o exemplo de cURL, todos são enviados no **corpo (JSON)** da requisição. O endpoint não tem placeholders de path.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `subscription_id` | integer | sim | ID de identificação da assinatura na Hotmart. Obtido via [Obter Assinaturas](./endpoint-obter-assinaturas.md). |
| `recurrences` | array | sim | Números das recorrências a propor na negociação. Aceita de **1 a 5 valores** (ver [regras de elegibilidade](./negociacao-parcelas-introducao.md)). |
| `payment_type` | string | sim | Tipo de meio de pagamento a oferecer (ex.: `PIX`, `BILLET`). |
| `discount` | object | não | Desconto opcional (abaixo). |
| `document` | string | condicional | CPF ou CNPJ do comprador inadimplente. **Obrigatório quando a negociação é via boleto bancário.** |

### `discount`

| Campo | Tipo | Descrição |
|---|---|---|
| `type` | string | Tipo de desconto. Atualmente só `CUSTOM` (desconto em **valor absoluto**). |
| `value` | number | Valor do desconto absoluto. |

### Requisição

```bash
curl --location --request POST 'https://developers.hotmart.com/payments/api/v1/installments/negotiate' \
--header 'Authorization: Bearer :access_token' \
--header 'Content-Type: application/json' \
--data-raw '{
  "subscription_id": 123456,
  "recurrences": [
    3
  ],
  "payment_type": "PIX",
  "discount": {
    "type": "CUSTOM",
    "value": 100.11
  }
}'
```

## Retorno

| Campo | Descrição |
|---|---|
| `subscription_id` | ID da assinatura na Hotmart. |
| `transaction` | Código de referência da transação (ex.: `HP17715690036014`). |
| `payment` | Dados da forma de pagamento gerada (abaixo). |

### `payment`

| Campo | Descrição |
|---|---|
| `type` | Meio de pagamento escolhido: `BILLET`, `PIX`, `CASH_PAYMENT`. |
| `expiration_date` | Data de expiração da forma de pagamento. |
| `billet_url` | Link do boleto bancário gerado (para enviar na campanha de recuperação). |
| `billet_barcode` | Código de barras do boleto gerado. |
| `pix_code` | Código Pix (copia e cola) gerado. |
| `pix_qrcode` | QR Code do Pix gerado. |

> Os campos `billet_*` vêm quando o pagamento é boleto; os campos `pix_*` quando é Pix.

## Exemplo de resposta (200)

```json
{
    "subscription_id": 123456,
    "payment": {
        "type": "PIX",
        "expiration_date": 1645271012000,
        "pix_code": "00020101021226780014br.gov.bcb.pix2556fake-pix.com.br/qr/v2/ACA4311F88661BC0D48200487EF1BCD95204000053039865802BR5910FAKEPIX Ltda6008CURITIBA62070503***63493",
        "pix_qrcode": "https://example.com/pix/checkout?hash=6605766dd14330fc7c3fea7314149aebaff0873af5d8726f"
    },
    "transaction": "HP01234567789"
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox. Valores diferentes dos esperados retornam erro **404**.

> A tabela de Sandbox da documentação está com placeholders genéricos (`param_name` / `value`), sem valores de teste reais preenchidos.
