# Códigos de Resposta HTTP

> Referência: documentação Hotmart Developers — "Códigos de Resposta HTTP".

A API da Hotmart usa o padrão de códigos de resposta HTTP para indicar sucesso ou falha de cada requisição. Em caso de erro, além do código HTTP, é enviado um objeto JSON com mensagem descritiva e o tipo do erro.

- **2xx** — sucesso.
- **4xx** — erro do lado do **cliente** (ex.: token inválido). A requisição está inválida de alguma forma; consulte o glossário de erros.
- **5xx** — problema nos serviços da API da Hotmart.

> Se não conseguir resolver, contate o suporte enviando a requisição completa e o erro recebido.

## Objeto de erro retornado

| Campo | Tipo | Descrição |
|---|---|---|
| `error` | string | Tipo do erro. Valores possíveis abaixo. |
| `error_description` | string | Mensagem de fácil entendimento com mais detalhes. |
| `error_uri` | string | Link para a documentação sobre o código de erro recebido. |

Valores possíveis de `error`: `invalid_token`, `token_expired`, `unauthorized`, `unauthorized_client`, `invalid_parameter`, `invalid_value_parameter`, `invalid_value_headers`, `not_found`, `too_many_requests`, `internal_server_error`.

### Exemplo de resposta

```json
{
  "error": "unauthorized",
  "error_description": "Full authentication is required to access this resource.",
  "error_uri": "https://developers.hotmart.com/docs/pt-BR/start/http-response-codes/"
}
```

## Sumário de status HTTP

| Status | Tipo de erro | Definição |
|---|---|---|
| **200** OK | — | Sucesso. Tudo ocorreu como planejado. |
| **201** Created | — | Similar ao 200, mas referente à criação de um novo recurso. |
| **400** Bad Request | `invalid_parameter` | A requisição enviada está inválida de alguma forma. |
| **400** Bad Request | `invalid_value_parameter` | Valor da queryString inválido. |
| **400** Bad Request | `invalid_value_headers` | Valor do header inválido. |
| **400** Bad Request | `invalid_token` | Valor do parâmetro `page_token` inválido. |
| **401** Unauthorized | `unauthorized` | É necessário estar autenticado. Normalmente o token de acesso não foi passado, ou há problema no nome do parâmetro no Header. |
| **401** Unauthorized | `token_expired` | O token de acesso passado expirou. |
| **401** Unauthorized | `invalid_token` | O token de acesso passado está inválido. |
| **403** Forbidden | `unauthorized_client` | O usuário não possui permissões para a requisição. |
| **404** Not Found | `not_found` | A URL requisitada não foi encontrada / está inválida. |
| **429** Too Many Requests | `too_many_requests` | Muitas requisições em pouco tempo. Veja a seção de [Rate Limit](https://developers.hotmart.com/docs/pt-BR/start/rate-limit). |
| **500** Server Error | `internal_server_error` | Erro interno inesperado; não foi possível completar a requisição. |
| **502** Bad Gateway | `internal_server_error` | A requisição demorou mais de 30 segundos. Revise as datas consultadas e/ou use outros filtros disponíveis. |
| **503** Service Unavailable | `internal_server_error` | Erro interno e API indisponível para todos. Tente novamente mais tarde. |
