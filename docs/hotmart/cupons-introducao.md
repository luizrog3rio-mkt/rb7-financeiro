# Cupons de desconto — Introdução

> Referência: documentação Hotmart Developers — seção "Cupons de desconto" > "Introdução Cupons".

Os cupons de desconto permitem criar ofertas promocionais e descontos para um mesmo produto. É possível:

- Enviar o cupom para **todos os clientes** ou escolher **qual base de clientes** poderá usar o desconto.
- Compartilhar o cupom com **todos os Afiliados** ou criar um cupom para um **Afiliado específico**.

## Endpoints disponíveis

- **Criar Cupom** — cria um cupom de desconto.
- **Obter Cupom** — lista cupons.
- **Excluir Cupom** — remove um cupom.

## Autenticação

As requisições devem ser autenticadas. Veja como gerar o token de acesso em [Autenticação](./autenticacao.md) (https://developers.hotmart.com/docs/pt-BR/start/app-auth/).

## Paginação

Os endpoints usam **paginação por cursor** via query param `page_token`.

- Use o valor de `next_page_token` no `page_token` para avançar para a próxima página.
- Use o valor de `prev_page_token` no `page_token` para voltar à página anterior.
- Ambos os tokens vêm no corpo de retorno das requisições.

> Detalhes em [Paginação](./paginacao.md) (https://developers.hotmart.com/docs/pt-BR/start/pagination/).
