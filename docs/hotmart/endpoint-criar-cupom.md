# Endpoint: Criar Cupom

> Referência: documentação Hotmart Developers — seção "Cupons de desconto" > "Criar Cupom".

Cria cupons de desconto de forma dinâmica. É necessário informar para qual produto é o cupom, o código que ativa o desconto e o percentual. Opcionalmente, datas de início/fim, ofertas aplicáveis e se é exclusivo de um afiliado.

`POST /products/api/v1/product/:product_id/coupon`

## Parâmetros da requisição

### Path

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `product_id` | sim | ID do produto (7 dígitos). Obtido via [Obter Produtos](./endpoint-obter-produtos.md). |

### Body

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `code` | string | sim | Código do cupom (**max length = 25**). |
| `discount` | double | sim | Percentual de desconto como **fração**: `0 < discount < 0.99` (ex.: `0.5` = 50%). |
| `start_date` | long | não | Data de ativação do cupom (ms desde 1970-01-01 UTC). A API usa o fuso horário do usuário. |
| `end_date` | long | não | Data de desativação do cupom (ms desde 1970-01-01 UTC). A API usa o fuso horário do usuário. |
| `affiliate` | long | não | ID do afiliado específico com quem compartilhar o cupom. |
| `offer_ids` | array&lt;long&gt; | não | Códigos das ofertas em que o cupom será aplicado. |

### Requisição

```bash
curl --location --request POST 'https://developers.hotmart.com/products/api/v1/product/:product_id/coupon' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer :access_token'
```

## Retorno

Resposta vazia (`{}`) com HTTP `200`. Considere o código HTTP para confirmar o sucesso.

```json
{
}
```
