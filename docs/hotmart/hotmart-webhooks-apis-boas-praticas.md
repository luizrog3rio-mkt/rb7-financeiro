# Boas práticas de uso de Webhooks e APIs (Hotmart)

> Referência: documentação Hotmart Developers — "Aprender boas práticas de uso de Webhooks e APIs para otimizar seus processos".

Aproveite ao máximo os serviços de **Webhook** e **API** da Hotmart economizando no processamento, tratamento e recuperação dos dados, otimizando a estrutura de integração.

## O que você vai aprender

1. Entender o objetivo do Webhook
2. Conhecer as APIs Hotmart Developers
3. Saber o porquê de combinar Webhooks e APIs
4. Como combinar as duas soluções
5. Criar sua estrutura de dados para as integrações
6. Recomendações Hotmart para Webhooks e APIs

## Sobre

Maximizando a eficiência das integrações com Webhook e API, você consegue:

- Obter os dados em **tempo real** para decisões estratégicas e automações.
- **Enriquecer seus dados** e ter maior conhecimento de como estão seus produtos e clientes.
- Ter maior **coesão dos dados** e validação de informações.
- Criar uma **estrutura robusta** para o tratamento dos dados de clientes e vendas.

## Pré-requisitos

- Credenciais de autenticação para se conectar às APIs.
- Estrutura própria para armazenamento das informações (ex.: um banco de dados).
- Conhecimento em desenvolvimento.

---

## 1. Entendendo o objetivo do Webhook

O Webhook é um serviço voltado para a **notificação de acontecimentos** em um determinado ambiente. É essencial para acompanhar em tempo real os eventos do negócio e ajudar na tomada de decisão. Na Hotmart, você pode receber notificações como: compra realizada, assinatura cancelada, carrinho abandonado, troca de plano e troca do dia de cobrança da assinatura.

**Ponto-chave:** o objetivo do Webhook é avisar quando algo significativo acontece. Um sistema de Webhook **não serve como base de dados, consulta ou alteração de dados**.

Sendo uma ferramenta de integração, o Webhook exige desenvolvimento para integrar. Mas existem sistemas de terceiros que já entregam a integração pronta — basta configurar, sem precisar de desenvolvedor ou conhecimento técnico. Exemplos: **Conta Azul, Pluga e Reportei**.

### Eventos principais disponíveis

- Pedido
- Abandono de carrinho
- Cancelamento de assinatura
- Troca de plano
- Troca do dia de cobrança da assinatura

Quanto mais eventos você ativar, mais informações estratégicas terá. Sempre que ocorrer uma dessas situações, os dados são enviados para a sua aplicação.

### Configuração e validação

Após ler a documentação e ter a solução desenvolvida, a configuração na plataforma é simples: escolha quais eventos quer receber. Se usar uma ferramenta de terceiro, há tutoriais prontos de conexão.

> **Validação:** todo payload disparado inclui o campo `hottok` para validar que os dados realmente vieram da Hotmart. O seu `hottok` fica na aba de **autenticação** do Webhook, na plataforma. **Compartilhe esse código apenas com pessoas de confiança** envolvidas no projeto.

Acompanhe o changelog para novidades: novos eventos, campos, otimizações, correções e tutoriais.

---

## 2. Conhecendo as APIs Hotmart Developers

As APIs permitem que usuários façam ações na Hotmart, como **consulta, solicitação e atualização**. Cada ação é um **endpoint**, divididos em contextos:

- Venda
- Assinatura
- Club (Área de Membros da Hotmart)

Assim como o Webhook, a API exige desenvolvimento — mas há sistemas de terceiros (Conta Azul, Pluga, Reportei) que criam integrações sem codificar.

A documentação Developers detalha os recursos, parâmetros e retorno (payload) de cada endpoint. Páginas de apoio: **códigos de resposta HTTP, rate limit, paginação, respostas (payload) customizadas e sandbox**.

Depois de entender as soluções, basta criar a credencial para realizar as chamadas dos endpoints.

> **Importante:** crie uma estrutura para armazenamento dos dados (ex.: banco de dados), para que o processamento possa ser feito a qualquer momento. Existem políticas de **paginação** e **rate limit**, então as APIs **não devem ser usadas para consultas recorrentes ou de grandes períodos**.

---

## 3. Por que combinar Webhooks e APIs

O Webhook avisa em **tempo real** quando algo acontece e atua como **gatilho** para as APIs realizarem ações na Hotmart, como: enriquecimento dos dados após notificação, armazenamento em banco de dados, disparo de comunicações e outras estratégias.

A combinação das duas soluções traz **maior desempenho, agilidade e segurança**, além de mais quantidade de dados — tornando a estrutura robusta, segura e completa.

Por segurança e proteção de dados, **o Webhook envia somente dados básicos**, sem trafegar dados sensíveis de compras e clientes. Como os eventos só disparam quando algo ocorre, dificilmente haverá gargalos ou estouro de rate limit. Caso ocorra, resolve-se com uma **"fila"** no seu sistema para gerenciar as requisições às APIs.

> Em resumo: use o **Webhook** como gatilho e as **APIs** para enriquecer os dados que o Webhook eventualmente não envia.

---

## 4. Combinando Webhooks e APIs

**Ideia principal:** o Webhook envia informações básicas → o evento é recebido → o sistema pode fazer notificações, iniciar processos ou chamar as APIs.

### Exemplo 1 — Compra aprovada

1. O cliente realiza uma compra.
2. O evento *compra aprovada* dispara e a Hotmart envia os dados no Webhook.
3. No payload vem o `transaction` (ex.: `HP123456789`).
4. Com ele, chame o endpoint **Participantes das vendas**, passando o `transaction` como filtro, para obter os dados do comprador: **endereço, telefone, documento**.

### Exemplo 2 — Compra cancelada

1. Uma compra é cancelada e o evento dispara.
2. Você quer agir com o cliente (ex.: enviar um e-mail).
3. Chame o endpoint **Obter Assinaturas**, passando o `transaction` como parâmetro.
4. Obtenha os dados da assinatura: **situação, plano, data da próxima cobrança / fim de acesso** etc.

---

## 5. Estruturando seus dados para as integrações

Toda integração com a Hotmart precisa de uma **estrutura própria de armazenamento** (ex.: banco de dados) para processamento futuro. O modelo depende da necessidade do negócio e de quais serviços (Webhook e API) serão usados. **Havendo necessidade futura de uso dos dados, o armazenamento é obrigatório.**

### Cenário: dashboard de vendas

| Modelo | O que acontece |
|---|---|
| **Recebimento via Webhook** | Se os dados não forem armazenados, são perdidos — inviabilizando qualquer visualização. *(Obs.: não é recomendado montar relatórios só com dados de Webhook.)* |
| **Consulta via APIs** | Quando o Webhook não basta, consulte as APIs (nomes, e-mails, endereços, planos). Se não armazenar, as consultas viram recorrentes — encarecendo a estrutura e atingindo limites das APIs. |

---

## 6. Recomendações Hotmart

- **Não compartilhe** suas credenciais de API nem o `hottok` do Webhook.
- Use **filtros** (principalmente de data) nas chamadas das APIs, para não atingir limites e obter respostas rápidas.
- **Evite chamadas recorrentes** sem necessidade. Avalie a qualidade do código e siga boas práticas de desenvolvimento.
- **Salve** as informações recebidas pelo Webhook ou recuperadas nas APIs em uma base de dados própria.
- **Valide sua aplicação.** Use os testes do Webhook e o sandbox das APIs.
- **Use os tutoriais** para aprender quais informações obter e combinar os serviços corretamente.
- **Acompanhe o changelog** para novos serviços, atualizações, correções, otimizações e tutoriais.
- Sem equipe de desenvolvimento? Considere **ferramentas já existentes no mercado**.

---

## Links úteis

- [Página de Autenticação — sobre como usar as APIs](https://developers.hotmart.com/docs/pt-BR/start/app-auth/)
- [Padrões de Código de Respostas HTTP](https://developers.hotmart.com/docs/pt-BR/start/http-response-codes/)
- [Documentação sobre Rate Limit](https://developers.hotmart.com/docs/pt-BR/start/rate-limit/)
- [Regras de Paginação](https://developers.hotmart.com/docs/pt-BR/start/pagination/)
- [Ambiente de teste (Sandbox)](https://developers.hotmart.com/docs/pt-BR/start/sandbox/)
- [Página de Respostas Customizadas](https://developers.hotmart.com/docs/pt-BR/start/custom-response/)
- [Padrões de Código de Respostas HTTP do Webhook](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/http-response-codes-webhook/)
- [Como usar o Webhook](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/using-webhook/)
