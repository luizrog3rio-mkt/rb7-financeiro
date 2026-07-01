# Identificar o engajamento dos alunos no Hotmart Club

> Referência: documentação Hotmart Developers — "Identificar o engajamento dos alunos no Hotmart Club".

Acesse os dados de consumo dos alunos em cada conteúdo para construir relatórios de engajamento e estruturar estratégias mais eficientes.

## O que você vai aprender

- Identificar o engajamento do aluno no Hotmart Club
- Associar dados de consumo do aluno a outras informações retornadas no Hotmart Developers

## Sobre

Identificando os dados de engajamento dos alunos nos produtos do Hotmart Club, você pode:

- Incentivar clientes de **maior engajamento** a comprar novos produtos, ativar planos ou virar afiliados.
- Incentivar a **conclusão e o consumo** dos conteúdos para alunos de baixo engajamento.
- Construir estratégias personalizadas conforme o momento de consumo de cada aluno.
- Criar uma estrutura de **gamificação** de acordo com o nível de engajamento.

## Pré-requisitos

- Entregar o conteúdo pelo **Hotmart Club**. *(Produtores que usam área de membros externa não conseguem essas informações via API.)*
- Possuir credenciais de autenticação para conectar às APIs.
- Ter uma estrutura própria de armazenamento (ex.: banco de dados).
- Ter conhecimento em desenvolvimento.

---

## 1. Identificando o engajamento do aluno no Hotmart Club

Faça uma chamada no endpoint **Obter Alunos**, que retorna todos os alunos de uma Área de Membros. O parâmetro **`subdomain`** é **obrigatório** — cada curso tem o seu.

### Como encontrar o `subdomain`

1. Acesse a página de **Produtos** na plataforma. *(Versão antiga: Produtos > Sou Produtor(a).)*
2. Clique no nome do curso para abrir a página de edição.
   - **Dica — ID do produto:** copie também o **número de ID do produto** (fica abaixo do título). Será útil para associar engajamento a outros endpoints (ver tópico 2).
3. Na navegação interna, vá em **Gestão do Curso** → **Acessar a gestão do curso pela Hotmart**.
4. Na Área de Membros, menu lateral → **Configurações** (aba **Dados**) → seção **Mapeamento de Host**. Copie o **Subdomínio (`subdomain`)**.

> Cole o `subdomain` junto ao **ID do produto** copiado no passo 2 — eles serão correlacionados no tópico 2.

### Chamada do endpoint

```bash
curl --location --request GET 'https://developers.hotmart.com/club/api/v1/users?subdomain=my-subdomain' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

`GET /club/api/v1/users`

### Campos relevantes para decisão estratégica

| Campo | Descrição |
|---|---|
| `first_access_date` | Data do primeiro acesso do aluno à área de membros. |
| `last_access_date` | Data do último acesso do aluno à área de membros. |
| `locale` | Idioma da compra (ou usado para importar o usuário). |
| `progress` | Progresso do aluno no curso: percentual total de conclusão, total de páginas do curso e total de páginas concluídas. |
| `engagement` | Índice de engajamento do aluno no curso. |
| `status` | Status atual do aluno. |
| `access_count` | Número de acessos realizados na Área de Membros. |
| `purchase_date` | Data da realização da compra. |

> Para todos os campos retornados (descrições e tipos), consulte a página do endpoint **Obter Alunos**.

---

## 2. Associar dados de consumo a outras informações do Hotmart Developers

Para enriquecer outros relatórios com o engajamento do aluno, associe esses dados aos retornados em outros endpoints (ex.: **Vendas**, **Obter Assinaturas**), que devolvem o campo **`product_id`**.

### Montando o de-para (`product_id` → `subdomain`)

Essa correlação é feita **na sua estrutura**, sem consumir APIs:

1. Obtenha o **`id` do produto** no momento da consulta do `subdomain` (passo 2 do tópico 1 — abaixo do nome do produto na plataforma).
2. Armazene o `product_id` junto ao `subdomain`, correlacionados:

| product_id | subdomain |
|---|---|
| `999999` | `subdomain_do_meu_produto` |

Com o de-para pronto, use o `product_id` retornado nos endpoints do Developers para descobrir o `subdomain` vinculado na sua base.

### Parâmetros da chamada

| Parâmetro | Descrição |
|---|---|
| `subdomain` | Recuperado da sua base via o de-para (a partir do `product_id` enviado nos outros endpoints). |
| `email` | Também enviado nos demais endpoints. Indica qual cliente/aluno associar às informações de engajamento. |

### Exemplo de chamada

```bash
curl --location --request GET 'https://developers.hotmart.com/club/api/v1/users?subdomain=my-subdomain&email=assinante@gmail.com' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

Com esses dados, dá pra montar estratégias direcionadas conforme o engajamento de cada aluno.

---

## Armazenamento dos dados e acompanhamento em tempo real

Após obter os dados, **armazene-os em estrutura própria**. Isso evita consultas constantes, reduz o número de requisições e o tempo de resposta, e diminui o risco de atingir o **limite de requisições (rate limit)** das APIs.

Para acompanhar atualizações em **tempo real**, use o **Webhook**. Quando os dados do Webhook não bastarem, **enriqueça com chamadas às APIs assim que o evento chegar** — como os eventos ocorrem espaçados no tempo, isso reduz bastante a necessidade de chamadas.

> **Modelo ideal:** Webhook (tempo real) + chamadas pontuais às APIs (enriquecimento) + tudo armazenado em estrutura própria. É o melhor para acompanhar um grande volume com atualização em tempo real.

## Links úteis

- [Página de Autenticação — sobre como usar as APIs](https://developers.hotmart.com/docs/pt-BR/start/app-auth/)
- [Padrões de Código de Respostas HTTP](https://developers.hotmart.com/docs/pt-BR/start/http-response-codes/)
- [Documentação sobre Rate Limit](https://developers.hotmart.com/docs/pt-BR/start/rate-limit/)
- [Regras de Paginação](https://developers.hotmart.com/docs/pt-BR/start/pagination/)
- [Ambiente de teste (Sandbox)](https://developers.hotmart.com/docs/pt-BR/start/sandbox/)
- [Página de Respostas Customizadas](https://developers.hotmart.com/docs/pt-BR/start/custom-response/)
- [Padrões de Código de Respostas HTTP do Webhook](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/http-response-codes-webhook/)
- [Como usar o Webhook](https://developers.hotmart.com/docs/pt-BR/1.0.0/webhook/using-webhook/)
