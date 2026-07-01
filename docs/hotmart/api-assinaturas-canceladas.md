# Conhecer quantos e quais clientes cancelaram sua assinatura

> Referência: documentação Hotmart Developers — "Conhecer quantos e quais clientes cancelaram sua assinatura".

Tenha visão de quais e quantos clientes cancelaram uma assinatura em um período e melhore sua estratégia de recuperação.

## O que você vai aprender

- Identificar as assinaturas canceladas do seu produto
- Enriquecer os dados da assinatura com dados de pagamento e telefone

## Sobre

Acessando os dados das assinaturas e clientes que solicitaram cancelamento, você pode:

- Desenvolver estratégias de comunicação e recuperação das assinaturas canceladas.
- Construir um relatório do valor perdido com cancelamentos.
- Identificar o número de assinaturas com pedido de cancelamento.
- Com mais de um produto, identificar qual tem maior taxa de cancelamento.

## Pré-requisitos

- Ter um produto de assinatura cadastrado **com vendas feitas**.
- Possuir credenciais de autenticação para conectar às APIs.
- Ter uma estrutura própria de armazenamento (ex.: banco de dados).
- Ter conhecimento em desenvolvimento.

---

## 1. Identificar as assinaturas canceladas

Faça uma chamada no endpoint **Obter Assinaturas**, que exibe informações detalhadas de assinaturas e assinantes.

1. Passe `CANCELLED_BY_CUSTOMER`, `CANCELLED_BY_SELLER` e `CANCELLED_BY_ADMIN` no parâmetro `status` (filtra apenas canceladas).
2. Informe o período de cancelamento com `cancelation_date` (início) e `end_cancelation_date` (fim).

> **Formato da data:** em **milissegundos**, a partir de `1970-01-01 00:00:00 UTC`.

> **Paginação:** dependendo do volume retornado, o resultado pode vir paginado — consulte a documentação de paginação.

### Chamada do endpoint

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/subscriptions?status=CANCELLED_BY_CUSTOMER&status=CANCELLED_BY_SELLER&status=CANCELLED_BY_ADMIN&cancelation_date=1656633600&end_cancelation_date=1664582399' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

`GET /payments/api/v1/subscriptions`

### Campos recomendados

| Campo | Descrição |
|---|---|
| `subscriber_code` | Código único de uma assinatura. |
| `subscriber.name` | Nome do assinante. |
| `subscriber.email` | E-mail do assinante. |
| `plan.name` | Nome do plano escolhido. |
| `plan.recurrency_period` | Período de recorrência do plano. |
| `plan.max_charge_cycles` | Máximo de cobranças (recorrências) do plano. |
| `product.id` | Identificador único do produto de assinatura. |
| `product.name` | Nome do produto de assinatura. |
| `status` | Situação atual da assinatura. |
| `request_date` | Data em que a assinatura foi criada. |
| `recurrency_period` | Período de recorrência (mensal, anual etc.). |
| `max_charge_cycles` | Quantidade máxima de cobranças do plano. |
| `date_next_charge` | Data da próxima cobrança (ou da última, para clientes em atraso). |
| `price.value` | Valor cobrado da assinatura. |
| `trial` | Indica se a assinatura possui período trial. |

---

## 2. Enriquecer com dados de pagamento e telefone

A primeira chamada **não retorna telefone nem forma de pagamento**. Para completar o relatório, use dois endpoints com os parâmetros `subscriber_code` (do passo 1) e `transaction` (obtido aqui).

### 2.1 Forma de pagamento — Obter Compras de Assinantes

Chame **Obter Compras de Assinantes** passando o `subscriber_code` no path.

| Campo | Descrição |
|---|---|
| `transaction` | Código de referência da transação (ex.: `HP12345678910111`). Usado no filtro do próximo passo. |
| `payment_type` | Tipo de pagamento escolhido na compra. |
| `payment_method` | Método de pagamento utilizado. |

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/subscriptions/:subscriber_code/purchases' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

`GET /payments/api/v1/subscriptions/:subscriber_code/purchases`

### 2.2 Telefone — Participantes de vendas

Chame **Participantes de vendas** passando a `transaction` obtida no passo 2.1.

O campo principal é `cellphone`. Esse endpoint retorna a **lista de participantes da venda** (afiliado, co-produtor, comprador).

> Para pegar o assinante, filtre pelo participante cujo atributo **`role`** (dentro de `user`) tenha o valor **`BUYER`**.

```bash
curl --location --request GET 'https://developers.hotmart.com/payments/api/v1/sales/users?transaction=HP12345678910111' \
  --header 'Content-Type: application/json' \
  --header 'Authorization: Bearer :access_token'
```

`GET /payments/api/v1/sales/users`

Com assinatura + assinante + meio de pagamento + telefone, dá pra montar uma estratégia direcionada para recuperação das assinaturas perdidas.

---

## Armazenamento dos dados e acompanhamento em tempo real

Após obter os dados, **armazene-os em estrutura própria**. Isso evita consultas constantes, reduz requisições e tempo de resposta, e diminui o risco de atingir o **rate limit** das APIs.

Para acompanhar atualizações em **tempo real**, use o **Webhook**. Quando os dados do Webhook não bastarem, **enriqueça com chamadas às APIs assim que o evento chegar** — como os eventos ocorrem espaçados, isso reduz bastante a necessidade de chamadas.

> **Modelo ideal:** Webhook (tempo real) + chamadas pontuais às APIs (enriquecimento) + tudo armazenado em estrutura própria. É o melhor para acompanhar um grande volume de assinaturas em tempo real.

## Links úteis

- [Página de Autenticação — sobre como usar as APIs](https://developers.hotmart.com/docs/pt-BR/start/app-auth/)
- [Padrões de Código de Respostas HTTP](https://developers.hotmart.com/docs/pt-BR/start/http-response-codes/)
- [Documentação sobre Rate Limit](https://developers.hotmart.com/docs/pt-BR/start/rate-limit/)
- [Regras de Paginação](https://developers.hotmart.com/docs/pt-BR/start/pagination/)
- [Ambiente de teste (Sandbox)](https://developers.hotmart.com/docs/pt-BR/start/sandbox/)
- [Página de Respostas Customizadas](https://developers.hotmart.com/docs/pt-BR/start/custom-response/)
- [Padrões de Código de Respostas HTTP do Webhook](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/http-response-codes-webhook/)
- [Como usar o Webhook](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/using-webhook/)
