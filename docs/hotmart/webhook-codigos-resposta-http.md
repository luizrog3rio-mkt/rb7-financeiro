# Webhooks — Códigos de Resposta HTTP

> Referência: documentação Hotmart Developers — seção "Webhook" > "Códigos de Resposta HTTP".
>
> Distinto dos [Códigos de Resposta HTTP gerais da API](./codigos-resposta-http.md) — esta página trata das respostas que **o seu serviço** retorna ao receber um webhook.

O Webhook usa o padrão de códigos HTTP para indicar sucesso ou falha de cada requisição, **exceto** quando o motivo do erro com um serviço não pôde ser determinado — nesse caso retorna o status **`-1`**.

## Classes de status (pelo primeiro dígito)

| Classe | Significado |
|---|---|
| `1xx` | Informativo |
| `2xx` | Sucesso |
| `3xx` | Redirecionamento |
| `4xx` | Erro do cliente |
| `5xx` | Erro de servidor |

- Erros **`4xx`** indicam que a requisição está inválida (ex.: token de acesso inválido). Consulte o glossário de erros.
- Erros **`5xx`** sugerem problema no serviço cadastrado no momento da configuração do webhook.

## Códigos de resposta

| Status | Descrição |
|---|---|
| `2XX` | Tudo certo. |
| `400` | A requisição enviada está de alguma forma inválida. |
| `500` | Ocorreu um erro interno não esperado e não foi possível completar a requisição. |

## Sugestões de solução

| Status | O que verificar |
|---|---|
| `400` | Seu serviço identificou que algum parâmetro obrigatório não foi enviado ou é inválido. |
| `401` | Seu serviço está exigindo autenticação. Verifique se está validando o **`hottok`** ou exigindo outro tipo de chave. |
| `404` | A URL configurada no seu serviço não existe. |
| `408` | A conexão foi estabelecida e o evento disparado, mas sua aplicação não retornou resposta no tempo esperado. |
| `5XX` | A conexão foi feita e o evento enviado, mas a aplicação não retornou resposta no tempo esperado. |
| `-1` | A conexão foi feita e o evento enviado, mas a aplicação **encerrou a conexão antes do tempo esperado**, sem informar o motivo do erro. |

> **`hottok`:** chave de autenticação que a Hotmart envia no webhook. Se o seu endpoint exige autenticação, valide o `hottok` em vez de retornar `401`.

## Links úteis

- Códigos HTTP (Webhook): https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/http-response-codes-webhook/
