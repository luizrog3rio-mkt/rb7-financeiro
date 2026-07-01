# Acompanhar vendas e assinaturas em tempo real com planilhas Google

> Referência: documentação Hotmart Developers — "Acompanhar vendas e assinaturas em tempo real com planilhas Google".

Crie um dashboard em ~5 minutos usando uma planilha Google para acompanhar vendas de assinatura, cancelamentos e trocas de plano, tomando decisões com base em dados em tempo real.

## O que você vai aprender

- Habilitar uma planilha Google para receber dados de assinaturas
- Configurar o Webhook para obter dados em tempo real
- Como usar o dashboard no seu negócio (exemplos de uso)

## Sobre

Com uma única planilha Google, você pode:

- Conhecer o público e maximizar vendas com dados em tempo real (produto mais vendido/cancelado, plano e forma de pagamento preferidos, dias de maior/menor volume).
- Usar **link automático do WhatsApp** para iniciar conversa com o cliente em um clique (já incluso na planilha).
- Tomar decisões por dados, identificando tendências de vendas, cancelamentos e trocas de plano vs. o mês anterior.
- Monitorar com gráficos (diário, semanal ou mensal).

## Pré-requisitos

- Ser cliente Hotmart com produto de assinatura cadastrado.
- Ter uma conta Google.

---

## 1. Habilitando a planilha para receber dados

A configuração usa dois recursos: o **Webhook** (informações em tempo real das ações dos clientes) e o **Google Apps Script API + Webhook for Sheets** (códigos personalizados na planilha).

### Instalando o complemento Webhook for Sheets

1. Ative o **Google Apps Script API**: faça login na sua conta Google, acesse o link da API, clique em **Google Apps Script API** e mude o status para **ativado**.
2. Faça uma **cópia da planilha modelo** (link da Hotmart).
3. Renomeie a planilha, trocando "Minha Empresa" pelo nome da sua empresa.
4. Abra a página do complemento **Webhook for Sheets** e clique em **Instalar**.
5. Clique em **Continuar**, selecione sua conta Google, leia as permissões e clique em **Permitir**.
6. Após instalar, clique em **Próxima** e depois **Concluído**.
7. **Atualize a página** para o ícone do complemento aparecer na barra lateral direita.
8. Clique no ícone do complemento para abrir as configurações.
9. Na aba **purchase-event**, marque as **duas opções** e clique em **Create**.
10. Atualize a página — a opção **Webhooks** aparecerá no menu superior.
11. Em **Webhooks**, clique em **Authorize**, conceda as permissões (Continuar → selecionar a conta → Permitir).
12. **Atualize a página.**
13. Em **Webhooks**, clique novamente em **Authorize** e conceda as permissões de novo.
14. Abra o complemento pelo ícone na barra lateral direita.
15. Clique em **Next**. *(Se der erro, repita a partir do passo 12.)*
16. Na tela final, **copie e guarde a URL exibida** — será usada na configuração do Webhook.

---

## 2. Configurando o Webhook para receber dados em tempo real

Acesse a Hotmart com a conta associada aos produtos de assinatura que deseja monitorar.

### 2.1 Primeiro Webhook: evento de pedido

1. Na página do Webhook, aba **Minhas configurações**, clique em **+Cadastrar Webhook**.
2. Preencha:
   - **Nome:** ex. `Planilha Google - Evento de Pedido`.
   - **Selecione um produto:** o produto desejado.
   - **URL para envio de dados:** cole a URL obtida no passo 16.
   - **Versão:** mantenha a recomendada **`2.0.0`**.
   - **Eventos:** selecione **todos os 9 eventos de compra** — aprovada, cancelada, completa, expirada, reembolsada, atrasada, aguardando pagamento, chargeback e pedido de reembolso.
3. Clique em **Salvar**.
4. Clique em **Enviar teste de Configuração** → **Acompanhar resultados do teste** (aba **Histórico**) e aguarde os eventos ficarem com status **processado**.
5. Na planilha, confirme que novas linhas surgiram nas abas **purchase-event** e **Pedidos**.
6. Na aba **purchase-event**, **apague os dados** (confirme o alerta com **OK**).

### 2.2 Segundo evento: cancelamento de assinatura

1. Aba **Minhas configurações** → **+Cadastrar Webhook**.
2. Preencha:
   - **Nome:** ex. `Planilha Google - Evento de Cancelamento de assinatura`.
   - **Selecione um produto.**
   - **URL para envio de dados:** cole a URL anterior e **substitua o final `gid=0` pelo GID da aba `cancel-subscription-event`** (pegue o gid na barra de endereços ao abrir essa aba).
   - **Versão:** `2.0.0`.
   - **Eventos:** selecione **Cancelamento de Assinatura**.
3. Clique em **Salvar**.
4. Envie o teste e acompanhe no **Histórico**.
5. Confirme novas linhas nas abas **cancel-subscription-event** e **Cancelamento de Assinaturas**.
6. Apague os dados da aba **cancel-subscription-event** (OK no alerta).

### 2.3 Terceiro evento: troca de plano

1. Aba **Minhas configurações** → **+Cadastrar Webhook**.
2. Preencha:
   - **Nome:** ex. `Planilha Google - Evento de Troca de Plano`.
   - **Selecione um produto.**
   - **URL para envio de dados:** cole a URL anterior e **substitua o final `gid=0` pelo GID da aba `switch-plan-event`**.
   - **Versão:** `2.0.0`.
   - **Eventos:** selecione **Troca de Plano**.
3. Clique em **Salvar**.
4. Envie o teste e aguarde status **processado** no **Histórico**.
5. Confirme novas linhas nas abas **switch-plan-event** e **Trocas de Plano**.
6. Apague os dados da aba **switch-plan-event** (OK no alerta).

> A planilha exibe dados **a partir da data de criação** — não traz dados passados.

### Formatação final

1. Exclua a **primeira linha em amarelo** (linha 2, eventos de teste) das abas **purchase-event**, **cancel-subscription-event** e **switch-plan-event** (botão direito no número da linha → **Excluir linha**). *Se ainda não recebeu dados novos, aguarde antes de excluir.*
2. **Oculte as três abas em vermelho** (imprescindível): botão direito nas abas **purchase-event**, **cancel-subscription-event** e **switch-plan-event** → **Ocultar páginas**.

### Dicas de uso

- O dashboard é uma **sugestão de análise** da Hotmart; os números podem diferir da plataforma por filtros especiais aplicados.
- A planilha é **personalizável**: nas abas **Pedidos**, **Cancelamento de Assinaturas** e **Troca de Plano** dá pra filtrar, formatar e criar gráficos. A planilha é protegida — alterações pedem confirmação.

---

## 3. Como usar o dashboard (exemplos de uso)

Há duas abas de dashboard: **Conceitos Dashboard** (definições dos dados/gráficos) e **Dashboard - Minhas vendas** (análises). Com elas você pode:

- Visualizar vendas de assinatura em tempo real (produto mais vendido/cancelado), com filtros.
- Conhecer o público por produto: assinaturas vendidas, dia de maior volume, plano mais popular, método de pagamento e parcelas preferidas.
- Tomar decisões com **indicadores comparativos vs. o mês anterior** (tendência de vendas, cancelamentos, trocas).
- Ver gráficos por forma de pagamento, parcelas e plano; escolher frequência de atualização e moeda.
- **Recuperar vendas perdidas:** ao analisar cancelamentos e trocas, use o **link do WhatsApp** para oferecer descontos ou sugerir planos mais adequados.
- **Estratégias sazonais:** aproveite os dias de maior volume para campanhas promocionais.
- **Impulsionar vendas:** identifique produtos mais populares e ajuste preços/parcelamento.

## Links úteis

- Usar webhook para obter dados de assinaturas
- Como recuperar dados das APIs na planilha Google
