# Documentação da API Hotmart Developers (referência em pt-BR)

Referência completa da API Hotmart Developers convertida em Markdown, organizada por seção. Cada arquivo é autocontido e usa links relativos entre os relacionados — referencie qualquer um no Claude Code com `@nome-do-arquivo.md`.

> 🔑 **Comece por aqui se for integrar status/enums:** [referencia-status-consolidada.md](./referencia-status-consolidada.md) — reconcilia as grafias divergentes de status, payment_mode, periodicidade etc. entre os vários endpoints e webhooks.

## Começando

| Arquivo | Conteúdo |
|---|---|
| [sobre-hotmart-developers.md](./sobre-hotmart-developers.md) | Visão geral da plataforma de desenvolvedores. |
| [autenticacao.md](./autenticacao.md) | Geração do token de acesso (OAuth). |
| [codigos-resposta-http.md](./codigos-resposta-http.md) | Códigos HTTP gerais da API. |
| [rate-limit.md](./rate-limit.md) | Limites de requisição. |
| [paginacao.md](./paginacao.md) | Paginação por cursor (page_token). |
| [custom-response.md](./custom-response.md) | Personalização de campos na resposta. |
| [sandbox.md](./sandbox.md) | Ambiente de testes. |

## Tutoriais

| Arquivo | Conteúdo |
|---|---|
| [hotmart-webhooks-apis-boas-praticas.md](./hotmart-webhooks-apis-boas-praticas.md) | Boas práticas de uso de webhooks e APIs. |
| [webhook-dados-assinaturas.md](./webhook-dados-assinaturas.md) | Receber dados de assinaturas (atrasadas/inativas/expiradas) via webhook. |
| [api-engajamento-alunos-club.md](./api-engajamento-alunos-club.md) | Identificar engajamento dos alunos no Hotmart Club. |
| [checkout-elements-pagina-vendas.md](./checkout-elements-pagina-vendas.md) | Checkout Elements na página de vendas. |
| [api-assinaturas-canceladas.md](./api-assinaturas-canceladas.md) | Listar assinaturas canceladas. |
| [api-assinaturas-atraso.md](./api-assinaturas-atraso.md) | Listar assinaturas em atraso. |
| [dashboard-planilha-google-tempo-real.md](./dashboard-planilha-google-tempo-real.md) | Dashboard em planilha Google em tempo real. |

## Assinaturas

| Arquivo | Conteúdo |
|---|---|
| [assinaturas-introducao.md](./assinaturas-introducao.md) | Introdução e status de assinatura (nomes PT). |
| [endpoint-obter-assinaturas.md](./endpoint-obter-assinaturas.md) | Listar assinaturas. |
| [endpoint-sumario-assinaturas.md](./endpoint-sumario-assinaturas.md) | Sumário de assinaturas. |
| [endpoint-transacoes-assinatura.md](./endpoint-transacoes-assinatura.md) | Transações de uma assinatura. |
| [endpoint-obter-compras-assinantes.md](./endpoint-obter-compras-assinantes.md) | Compras de assinantes. |
| [endpoint-cancelar-assinatura.md](./endpoint-cancelar-assinatura.md) | Cancelar uma assinatura. |
| [endpoint-cancelar-lista-assinaturas.md](./endpoint-cancelar-lista-assinaturas.md) | Cancelar lista de assinaturas. |
| [endpoint-reativar-cobrar-assinatura.md](./endpoint-reativar-cobrar-assinatura.md) | Reativar/cobrar uma assinatura. |
| [endpoint-reativar-cobrar-lista-assinaturas.md](./endpoint-reativar-cobrar-lista-assinaturas.md) | Reativar/cobrar lista de assinaturas. |
| [endpoint-alterar-dia-cobranca.md](./endpoint-alterar-dia-cobranca.md) | Alterar dia de cobrança. |

## Vendas

| Arquivo | Conteúdo |
|---|---|
| [vendas-introducao.md](./vendas-introducao.md) | Introdução à seção de vendas. |
| [endpoint-historico-vendas.md](./endpoint-historico-vendas.md) | Histórico de vendas. |
| [endpoint-sumario-vendas.md](./endpoint-sumario-vendas.md) | Sumário de vendas. |
| [endpoint-participantes-vendas.md](./endpoint-participantes-vendas.md) | Participantes de vendas. |
| [endpoint-comissoes-vendas.md](./endpoint-comissoes-vendas.md) | Comissões de vendas. |
| [endpoint-detalhamento-precos-vendas.md](./endpoint-detalhamento-precos-vendas.md) | Detalhamento de preços de vendas. |
| [endpoint-reembolso-vendas.md](./endpoint-reembolso-vendas.md) | Reembolso de vendas. |

## Área de membros

| Arquivo | Conteúdo |
|---|---|
| [area-membros-introducao.md](./area-membros-introducao.md) | Introdução ao Hotmart Club. |
| [endpoint-obter-modulos.md](./endpoint-obter-modulos.md) | Obter módulos. |
| [endpoint-obter-paginas.md](./endpoint-obter-paginas.md) | Obter páginas (v2). |
| [endpoint-obter-alunos.md](./endpoint-obter-alunos.md) | Obter alunos. |
| [endpoint-obter-progresso-aluno.md](./endpoint-obter-progresso-aluno.md) | Obter progresso do aluno. |

## Produto

| Arquivo | Conteúdo |
|---|---|
| [endpoint-obter-produtos.md](./endpoint-obter-produtos.md) | Obter produtos. |
| [endpoint-obter-ofertas-produto.md](./endpoint-obter-ofertas-produto.md) | Obter ofertas de produto. |
| [endpoint-obter-planos-produto.md](./endpoint-obter-planos-produto.md) | Obter planos de produto. |

## Cupons de desconto

| Arquivo | Conteúdo |
|---|---|
| [cupons-introducao.md](./cupons-introducao.md) | Introdução aos cupons. |
| [endpoint-criar-cupom.md](./endpoint-criar-cupom.md) | Criar cupom. |
| [endpoint-obter-cupom.md](./endpoint-obter-cupom.md) | Obter cupom. |
| [endpoint-excluir-cupom.md](./endpoint-excluir-cupom.md) | Excluir cupom. |

## Ingressos para eventos

| Arquivo | Conteúdo |
|---|---|
| [ingressos-eventos-introducao.md](./ingressos-eventos-introducao.md) | Introdução, filtros e pré-requisitos. |
| [endpoint-informacoes-evento.md](./endpoint-informacoes-evento.md) | Informações do evento. |
| [endpoint-lista-ingressos-participantes.md](./endpoint-lista-ingressos-participantes.md) | Lista de ingressos e participantes. |

## Negociação de parcelas

| Arquivo | Conteúdo |
|---|---|
| [negociacao-parcelas-introducao.md](./negociacao-parcelas-introducao.md) | Introdução e regras de elegibilidade. |
| [endpoint-gerar-negociacao.md](./endpoint-gerar-negociacao.md) | Gerar uma negociação (boleto/Pix). |

## Webhook (referência técnica)

| Arquivo | Conteúdo |
|---|---|
| [webhook-sobre.md](./webhook-sobre.md) | Sobre webhooks. |
| [webhook-usando.md](./webhook-usando.md) | Usando webhooks (3 passos). |
| [webhook-codigos-resposta-http.md](./webhook-codigos-resposta-http.md) | Códigos HTTP do webhook (inclui `-1` e `hottok`). |
| [webhook-evento-cancelamento-assinatura.md](./webhook-evento-cancelamento-assinatura.md) | Evento `SUBSCRIPTION_CANCELLATION`. |
| [webhook-evento-troca-plano.md](./webhook-evento-troca-plano.md) | Evento `SWITCH_PLAN`. |
| [webhook-evento-abandono-carrinho.md](./webhook-evento-abandono-carrinho.md) | Evento `PURCHASE_OUT_OF_SHOPPING_CART`. |
| [webhook-eventos-pedido.md](./webhook-eventos-pedido.md) | Eventos de pedidos (payload mais completo). |
| [webhook-evento-troca-dia-cobranca.md](./webhook-evento-troca-dia-cobranca.md) | Evento `UPDATE_SUBSCRIPTION_CHARGE_DATE`. |
| [webhook-evento-primeiro-acesso.md](./webhook-evento-primeiro-acesso.md) | Evento `CLUB_FIRST_ACCESS`. |
| [webhook-evento-modulo-completo.md](./webhook-evento-modulo-completo.md) | Evento `CLUB_MODULE_COMPLETED`. |
| [webhook-evento-dado-logistico.md](./webhook-evento-dado-logistico.md) | Evento `ORDER_FULFILLMENT` (produto físico). |

## Referência cruzada

| Arquivo | Conteúdo |
|---|---|
| [referencia-status-consolidada.md](./referencia-status-consolidada.md) | Reconciliação de todos os status/enums divergentes entre fontes. |

---

## Notas gerais

- **Autenticação:** todas as chamadas REST usam `Authorization: Bearer :access_token`. Webhooks chegam com o token no header `X-HOTMART-HOTTOK` — valide-o antes de processar.
- **Datas:** em geral em **milissegundos** desde 1970-01-01 UTC. Exceções pontuais estão marcadas nos arquivos (ex.: webhook de troca do dia de cobrança usa string ISO).
- **Paginação:** por cursor (`page_token` + `next_page_token`/`prev_page_token`).
- **Sandbox:** troque a URL base para `https://sandbox.hotmart.com` e use a credencial de Sandbox.
- **Pendente:** a página **Changelog** do menu lateral ainda não foi incluída.
