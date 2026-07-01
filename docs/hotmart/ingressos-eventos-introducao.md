# Ingressos para eventos — Introdução

> Referência: documentação Hotmart Developers — seção "Ingressos para eventos" > "Introdução".

Acesso às informações detalhadas dos ingressos vendidos e das cortesias gratuitas geradas pela plataforma, incluindo dados dos compradores e participantes.

## Opções de consulta

- Dados básicos de um evento (nome, data, lotes de ingresso etc.).
- Lista de ingressos adquiridos de um evento.
- Lista de **compradores** de um evento (quem comprou os ingressos).
- Lista de **participantes** de um evento (quem vai usar os ingressos).
- Dados do comprador e participante de um ingresso específico.

## Filtros disponíveis

Para cada consulta, é possível filtrar por:

- **Lote** do ingresso.
- **Status** do ingresso: vendidos, reservados, reembolsados, chargeback, convites e convites cancelados.
- **Tipo** do ingresso: pago ou gratuito.
- **Status de check-in**: pendente ou concluído.
- **Identificador único** do ingresso (interno).
- **Código** do ingresso (público — QR Code).

## Pré-requisitos

Para fazer as consultas é necessário:

- **Token de autenticação** (ver [Autenticação](./autenticacao.md)).
- **ID do produto** — obrigatoriamente um produto no formato **Ingresso para Eventos**.

## Endpoints da seção

- **Informações do Evento** — dados básicos do evento.
- **Lista de ingressos e participantes** — ingressos, compradores e participantes.
