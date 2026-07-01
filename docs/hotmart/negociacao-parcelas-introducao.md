# Negociação de parcelas — Introdução

> Referência: documentação Hotmart Developers — seção "Negociação de parcelas" > "Introdução".

O endpoint de **Negociação de Parcelas** permite oferecer acordos para pagamento de parcelas em atraso via **boleto bancário** e **pix**, ajudando a reduzir a inadimplência.

## Para que serve

A inadimplência é um risco para negócios com produtos de **Assinatura** ou estratégias de recuperação com **Recuperador Automático**. Com este endpoint você:

- Recebe o **link do boleto ou do pix** para compradores com recorrência em atraso.
- Pode criar uma estratégia de recuperação, **automatizando o envio dos links** para compradores com pendências.

## Regras de elegibilidade da parcela

As regras variam conforme o tipo de assinatura:

- **Assinaturas com conteúdo no Club:** é possível negociar **somente a última parcela** — assim a assinatura volta ao status **ativa**.
- **Assinaturas com conteúdo externo, Smart Installment e parcelamento de boleto ou PIX:** é possível negociar **até 5 parcelas** elegíveis.

## Endpoints da seção

- **Gerar uma negociação** — gera a negociação e retorna a forma de pagamento (boleto/pix).
