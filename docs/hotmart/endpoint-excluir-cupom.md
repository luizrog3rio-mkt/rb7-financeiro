# Endpoint: Excluir Cupom

> Referência: documentação Hotmart Developers — seção "Cupons de desconto" > "Excluir Cupom".

Exclui um cupom específico do produto — útil para remover cupons não mais válidos ou criados por engano.

`DELETE /products/api/v1/coupon/:coupon_id`

## Parâmetros da requisição (path)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `coupon_id` | sim | Identificador único do cupom. Corresponde ao campo `id` retornado em [Obter Cupom](./endpoint-obter-cupom.md) (não ao `coupon_code`). |

### Requisição

```bash
curl --location --request DELETE 'https://developers.hotmart.com/products/api/v1/coupon/:coupon_id' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer :access_token'
```

## Retorno

Resposta vazia (`{}`) com HTTP `200`. Considere o código HTTP para confirmar o sucesso.

```json
{
}
```
