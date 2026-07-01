# Paginação

> Referência: documentação Hotmart Developers — "Paginação".

A Hotmart usa **cursor pagination** para lidar com coleções de recursos (listas de usuários, assinaturas, produtos etc.).

Alguns endpoints retornam listas que podem ficar muito grandes (ex.: todas as vendas do ano anterior). Para melhorar a experiência, os resultados são entregues paginados.

## Parâmetros da requisição

| Parâmetro | Tipo | Descrição |
|---|---|---|
| `max_results` | integer | Número máximo de itens por página. |
| `page_token` | string | O **cursor** da paginação — referência para a parte da lista que você quer acessar. |

**Como o cursor funciona:** se uma requisição retorna 50 de 95 itens, adicione o query param `page_token` com o valor de `next_page_token` para acessar os 45 restantes. Na requisição seguinte, troque o `page_token` pelo valor de `prev_page_token` para voltar aos 50 anteriores.

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/subscriptions?page_token=:page_token' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer :access_token'
```

## Retorno

| Campo | Tipo | Descrição |
|---|---|---|
| `items` | array | Coleção de itens do tipo da lista (ex.: lista de vendas). |
| `page_info` | object | Informações de paginação (campos abaixo). |

### `page_info`

| Campo | Tipo | Descrição |
|---|---|---|
| `total_results` | integer | Quantidade total de itens da lista (desconsiderando a paginação). **Pode não vir em todos os endpoints.** |
| `next_page_token` | string | Referência para a **próxima** página. **Não vem** quando se está na última página. |
| `prev_page_token` | string | Referência para a página **anterior**. **Não vem** quando se está na primeira página. |
| `results_per_page` | integer | Quantidade de itens na página atual. Cada endpoint tem um `results_per_page` padrão e um máximo — se você passar `max_results` acima do permitido, apenas o máximo é retornado. |

### Exemplo de resposta

```json
{
  "items": [...],
  "page_info": {
      "total_results": 30,
      "next_page_token": "eyJwYWdlIjoyLCJyb3dzIjoxMH0=",
      "prev_page_token": "eyJwYWdlIjoyLCJyb3dzIjoxMH0=",
      "results_per_page": 10
  }
}
```
