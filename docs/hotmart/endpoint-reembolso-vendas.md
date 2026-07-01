# Endpoint: Reembolso de vendas

> Referência: documentação Hotmart Developers — seção "Vendas" > "Reembolso de vendas".

Solicita o **reembolso** de uma venda.

`PUT /payments/api/v1/sales/:transaction_code/refund`

## Critérios de elegibilidade

A venda precisa cumprir **todos** os critérios abaixo:

- Ter status **Aprovada** (`APPROVED`) ou **Completa** (`COMPLETE`).
- **Não** ser venda em modo **trial** (período de teste).
- **Não** ter sido paga via **BACS** ou **SEPA** — nesses casos, o reembolso deve ser solicitado pelo comprador junto ao banco.

### Prazos importantes

- O comprador deve poder reembolsar entre **no mínimo 7 e até 30 dias**; o prazo pode ser estendido até **60 dias**. Essa informação deve ser exibida ao cliente **antes da venda**.
- Se a venda tiver **afiliação** envolvida, o reembolso pode ser solicitado em até **30 dias** após a compra.

## Parâmetros da requisição (path)

| Parâmetro | Obrigatório | Descrição |
|---|---|---|
| `transaction` | sim | Código único da transação (ex.: `HP17715690036014`). *No path da URL aparece como `:transaction_code`.* |

### Requisição

```bash
curl --location --request PUT 'https://developers.hotmart.com/payments/api/v1/sales/:transaction_code/refund' \
    --header 'Authorization: Bearer :access_token' \
    --header 'Content-Type: application/json'
```

## Retorno

O retorno é **vazio** (`{}`). Considere apenas os **códigos HTTP** para verificar o resultado.

```json
{}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.
