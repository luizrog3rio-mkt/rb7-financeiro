# Rate Limit

> Referência: documentação Hotmart Developers — "Rate Limit".

## O que é Rate Limit?

Rate limit é o número de chamadas à API que um usuário ou aplicação pode realizar dentro de um período de tempo, para evitar sobrecarga e manter estabilidade e segurança.

- **Limite padrão:** **500 chamadas por minuto** (considerando leitura e escrita).
- Ao ultrapassar o limite, a requisição retorna o status **[429](https://developers.hotmart.com/docs/pt-BR/start/http-response-codes/)** (Too Many Requests).

## HTTP Headers

No Header da resposta são enviados campos informando os limites, a cota disponível e o tempo até a restauração:

| Header | Descrição |
|---|---|
| `RateLimit-Limit` | Quantas chamadas a aplicação pode fazer por janela de tempo (a janela é de **1 minuto**). |
| `RateLimit-Remaining` | Total de requisições ainda disponíveis na janela de tempo. |
| `RateLimit-Reset` | Tempo restante até o limite ser redefinido. |

Também são enviados, no Header, os limites por período e as solicitações restantes:

| Header | Descrição |
|---|---|
| `X-RateLimit-Limit-Minute` | Quantas chamadas a aplicação pode fazer por minuto. |
| `X-RateLimit-Remaining-Minute` | Total de requisições disponíveis no minuto corrente. |
