# Usar webhook para obter dados de assinaturas

> Referência: documentação Hotmart Developers — "Usar webhook para obter dados de assinaturas".

Use o webhook para melhorar resultados em produtos de assinatura, criando estratégias **real time** de comunicação e recuperação de assinantes.

## O que você vai aprender

- Estruturar seu ambiente para receber os eventos
- Receber eventos de assinaturas **atrasadas, inativas ou expiradas**

## Sobre

Usando os eventos do **Webhook de Eventos de pedidos** da Hotmart, você recebe dados gerais sobre assinaturas (compras, mudança de status, dados do comprador, dados de pagamento). Com isso, você pode:

- Integrar com ferramentas de e-mail e apps de mensagens para comunicação mais eficiente.
- Receber notificações do produto de assinatura (ex.: nova compra, atraso de recorrência, não renovação).
- Notificar o cliente sobre atraso (tratativa de inadimplência).
- Incentivar a conclusão de uma compra.
- Integrar com ferramentas No-Code/Low-Code (Zapier, Bubble, Make).
- Bloquear ou liberar acesso de aluno em plataformas externas (fora do Hotmart Club).
- Montar estratégia para aumentar conversão e renovação de assinaturas.

## Pré-requisitos

- Ter um produto de assinatura cadastrado e **ativo** na Hotmart.
- Ter um endpoint/local para receber as informações (ou uma solução No-Code/Low-Code como Zapier, Bubble, Make).
- Possuir as credenciais de autenticação do webhook (**hottok**).

---

## Estruturando seu ambiente para receber os eventos

Para receber os eventos, monte um ambiente: um endpoint, um banco de dados, ou uma plataforma Low-Code/No-Code (Zapier, Bubble, Make).

> **A Hotmart não possui vínculos com as plataformas low-code.** A contratação e o suporte devem ser feitos diretamente com cada empresa, sob sua responsabilidade.

### Autenticação (hottok)

Por segurança (contra fraudes e ataques), o evento de Webhook traz uma credencial de autenticação (**hottok**):

- O `hottok` é **único por conta**.
- Sempre enviado no **Header** do evento, no campo **`X-HOTMART-HOTTOK`**, para validar que o evento é seguro e veio da Hotmart.
- Para copiar: aba de **autenticação** dentro da ferramenta Webhook (menu Ferramentas).

> **Guarde o hottok com segurança.** A exposição permite que terceiros enviem dados indevidos se passando pela Hotmart. Compartilhe somente com pessoas de confiança.

---

## Recebendo eventos de assinaturas atrasadas, inativas ou expiradas

Com o ambiente já pronto, configure o evento de webhook:

1. Na plataforma, acesse **Ferramentas > Webhook** (API e notificações).
2. Clique em **Cadastrar Webhook** e preencha:
   - **Nome da configuração:** crie um nome para organizar. Sugestões:
     - `Assinaturas atrasadas - Nome do Produto`
     - `Assinaturas inativas - Nome do Produto`
     - `Assinaturas expiradas - Nome do Produto`
   - **Selecione um produto:** o produto que você quer monitorar.
   - **URL para envio de dados:** o endereço do ambiente que vai receber os dados. **Obrigatório.**
   - **Selecione a versão:** mantenha a recomendada **`2.0.0`**. *(Este tutorial não atende a versão 1.0.0.)*
   - **Eventos para enviar:** selecione **Compra Aprovada**, **Compra Cancelada** e **Compra Atrasada**.
3. Clique em **Salvar**. Use o **Teste** para validar se os dados estão chegando corretamente.

Após a configuração, sua estrutura recebe todos os dados do **Evento de Pedidos**. Os campos relevantes para este caso de uso estão abaixo.

---

## Referência de campos do payload

### `event`

Retorna o nome do evento — usado para diferenciar o tipo:

| Valor | Significado |
|---|---|
| `PURCHASE_CANCELED` | Compra cancelada |
| `PURCHASE_DELAYED` | Compra atrasada |
| `PURCHASE_APPROVED` | Compra aprovada |

### `subscription`

Dados da assinatura, no momento da adesão ou na cobrança de uma recorrência.

#### `subscription.status`

Status da assinatura. Três status úteis para recuperação de inadimplentes e receita:

| Status | Descrição | Evento vinculado |
|---|---|---|
| `PAST_DUE` | Assinatura **atrasada**. Use para estratégias de comunicação e recuperação de inadimplentes (incentivo ao pagamento, oferta, desconto). | `PURCHASE_DELAYED` |
| `INACTIVE` | Assinatura que **não teve a compra aprovada na adesão** (ex.: saldo insuficiente no cartão, boleto não pago). Use para incentivar a conclusão da compra. | `PURCHASE_CANCELED` |
| `EXPIRED` | Assinatura **não renovada** após a última recorrência. Use para estratégias de renovação (lembretes). | `PURCHASE_APPROVED` |

### `plan`

Dados do plano adquirido.

| Campo | Tipo | Descrição |
|---|---|---|
| `name` | string | Nome do plano adquirido. Enviado apenas em venda de assinaturas. |

### `subscriber`

Dados do assinante.

| Campo | Tipo | Descrição |
|---|---|---|
| `code` | string | Código exclusivo do assinante. Usado pelo sistema externo para identificar um assinante. *Um mesmo comprador terá 2 `subscriber.code` diferentes se assinar dois produtos diferentes.* |

### `buyer`

Dados do comprador preenchidos na página de pagamento (definidos pelo Produtor no checkout).

| Campo | Tipo | Descrição |
|---|---|---|
| `email` | string | E-mail do comprador. |
| `name` | string | Nome completo do comprador. |
| `checkout_phone` | string | Telefone preenchido na página de pagamento. Em venda internacional (comprador fora do Brasil), o DDI é enviado junto ao telefone. |

### `purchase.payment`

Dados do pagamento (links de boleto/PIX, motivos de recusa, tipo de pagamento).

| Campo | Tipo | Descrição |
|---|---|---|
| `billet_barcode` | string | Código de barras do boleto. *(Só em compra do tipo boleto.)* |
| `billet_url` | string | Link para reimprimir o boleto. *(Só em compra do tipo boleto.)* |
| `installments_number` | integer | Número total de parcelas em compra parcelada (moedas BRL, MXN ou COP). |
| `pix_code` | string | Código do Pix (copia e cola). *(Só em compra por Pix.)* |
| `pix_qrcode` | string | Link para visualizar o QR code do Pix. *(Só em compra por Pix.)* |
| `refusal_reason` | string | Texto de recusa do pagamento pela operadora (cartão de crédito). |
| `type` | string | Tipo de pagamento escolhido pelo cliente. Valores abaixo. |

#### Valores possíveis de `purchase.payment.type`

`BILLET`, `CASH_PAYMENT`, `CREDIT_CARD`, `DIRECT_BANK_TRANSFER`, `DIRECT_DEBIT`, `FINANCED_BILLET`, `FINANCED_INSTALLMENT`, `GOOGLE_PAY`, `HOTCARD`, `HYBRID`, `MANUAL_TRANSFER`, `PAYPAL`, `PAYPAL_INTERNACIONAL`, `PICPAY`, `PIX`, `SAMSUNG_PAY`, `WALLET`.

---

Com esses dados de assinaturas (compras aprovadas, canceladas e atrasadas), dá pra montar estratégias real time de comunicação e recuperação de assinantes.

## Links úteis

- [Sobre o Webhooks](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/about-webhook/)
- [Usando Webhooks](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/using-webhook/)
- [Códigos de Resposta HTTP](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/http-response-codes-webhook/)
