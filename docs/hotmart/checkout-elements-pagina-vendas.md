# Integrar checkout Hotmart na sua página de vendas

> Referência: documentação Hotmart Developers — "Integrar checkout Hotmart na sua página de vendas".

Adicione o checkout Hotmart à sua página de venda integrando a jornada de compra, para criar uma experiência personalizada e otimizar vendas.

## O que você vai aprender

- Obter o código da oferta do seu produto
- Integrar sua página de vendas no checkout

## Sobre

Criando um checkout integrado à jornada de compra do seu próprio site, você ganha:

- Mais controle sobre a experiência do usuário.
- Uma compra mais fluida e integrada.
- Maior proximidade e confiança dos clientes.

## Pré-requisitos

- Possuir uma página externa com controle sobre o código-fonte.
- Conhecimento técnico básico em HTML e JavaScript.
- Adicionar o **código de oferta** do produto no processo de integração da biblioteca.

---

## 1. Obtendo o código de oferta do seu produto

Para integrar a página de vendas com o **Checkout Elements**, obtenha o **código de oferta**:

1. Na plataforma, menu lateral → **Produtos**. *(Versão antiga: Produtos > Sou Produtor.)*
2. Clique no curso que deseja integrar.
3. No menu à esquerda, clique na quarta opção: **Precificação e ofertas**.
4. Na lista, localize o valor e a forma de pagamento desejados e copie o **`código`** da oferta.

---

## 2. Integrando sua página de vendas com Checkout Elements

Existem dois tipos de checkout: **de sobreposição (overlay)** e **incorporado (inline)**. Escolha o que faz mais sentido e adicione o script antes do fechamento da tag da sua página de vendas.

> **Atenção:** ao trazer o checkout para a sua página, você precisa estar tecnologicamente preparado para todo o fluxo de usuários. **Se a sua página de venda ficar indisponível, o checkout também ficará.**

### Checkout de sobreposição (Overlay / Widget)

Você cria um botão na página; ao ser clicado, abre um overlay (modal) com o checkout completo.

```html
<!--- Required script --->
<script src="https://checkout.hotmart.com/lib/hotmart-checkout-elements.js"></script>
<!--- Your button --->
<button id="payment_button">Proceed to checkout</button>
<!--- Configuration --->
<script>
const elements = checkoutElements.init('overlayCheckout', {
    offer: 'kjl7fk5t'
})
elements.attach('#payment_button')
</script>
```

### Checkout incorporado (Inline / transparente)

O checkout fica inserido diretamente dentro da sua própria página.

```html
<!--- Required script --->
<script src="https://checkout.hotmart.com/lib/hotmart-checkout-elements.js"></script>
<!--- The div that the checkout should be loaded --->
<div id="inline_checkout"></div>
<!--- Configuration --->
<script>
const elements = checkoutElements.init('inlineCheckout', {
    offer: 'kjl7fk5t'
})
elements.mount('#inline_checkout')
</script>
```

Com o checkout integrado, o cliente conclui a compra dentro da sua página, sem redirecionamento — experiência mais fluida e maior controle do fluxo.

---

## Dados pré-preenchidos

É possível pré-preencher os dados do usuário no checkout. O parâmetro `sck` deve ficar dentro de `prefilledInfo`.

```js
const elements = checkoutElements.init('inline', {
    offer: 'YOUR_OFFER',
    countryIsoCode: 'ES',
    locale: 'es',
    prefilledInfo: {
        name: 'Yoshio Mack',
        email: 'support.test.goe1oxfc@hotmart.com',
        doc: '1234567909',
        zip: '30110056',
        phoneac: '31',
        phonenumber: '988887777',
        sck: 'your sck param'
    }
})
```

## Opções de visualização

É possível alterar a visibilidade de certos elementos do checkout. A propriedade `xcod` (código de campanha) fica dentro de `visibilityOptions`.

```js
visibilityOptions: {
    hideBillet: '1',
    hideTransf: '1',
    hidePayPal: '1',
    split: '12',
    hideMultipleCards: '1',
    showOnlyTrial: '1',
    hideTrial: '1',
    showTrialBillet: '1',
    hidePix: '1',
    hidewallet: '1',
    hideCouponOption: '1',
    xcod: 'your campaign code',
    src: 'xxx'
}
```
