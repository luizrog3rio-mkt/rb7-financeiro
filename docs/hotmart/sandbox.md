# Sandbox

> Referência: documentação Hotmart Developers — "Sandbox".

O **sandbox** é um ambiente para testar sua integração durante o desenvolvimento. Ele imita o ambiente de produção, então **todos os endpoints** do Hotmart Developers podem ser acessados nele.

- Recomendado para identificar problemas de implementação **antes do sistema ir ao ar**.
- A **autenticação** funciona igual à da API de produção (veja [Autenticação da API](https://developers.hotmart.com/docs/pt-BR/start/app-auth/)).
- Os dados de retorno são **fictícios** — sua conta e dados reais na Hotmart **não são afetados** pelos testes.

## URL base e mapeamento

A URL base do sandbox é **`https://sandbox.hotmart.com/`**. Todos os endpoints são acessados por ela usando o **mesmo caminho** do endpoint original.

Exemplo — endpoint de produção:

```
https://developers.hotmart.com/payments/api/v1/subscriptions
```

Equivalente no sandbox:

```
https://sandbox.hotmart.com/payments/api/v1/subscriptions
```

> Alguns endpoints têm **mais de um cenário de resposta**. Nesses casos, é preciso enviar valores específicos na requisição para obter/testar cada cenário isoladamente. Os valores possíveis e seus retornos ficam listados na seção de cada endpoint.

## Retornos de erro

O sandbox também permite testar erros, não só sucessos. Como o foco é auxiliar na integração, **nem todos os erros** da API estão disponíveis — apenas algumas validações, suficientes para testar a implementação.

Erros comuns que podem ser retornados em todos os endpoints (erros específicos ficam na seção de cada endpoint):

| Status | Tipo de erro | Definição |
|---|---|---|
| **404** Not Found | `not_found` | A URL requisitada não foi encontrada / está inválida. |
| **405** Method Not Allowed | `method_not_allowed` | O método HTTP é conhecido pelo servidor, mas não pode ser usado nesse endpoint. |
| **401** Unauthorized | `unauthorized_client` | O usuário não possui permissões para a requisição. |
| **500** Server Error | `internal_server_error` | Erro interno inesperado; não foi possível completar a requisição. |
