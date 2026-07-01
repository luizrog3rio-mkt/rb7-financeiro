# Autenticação de Aplicativo

> Referência: documentação Hotmart Developers — "Autenticação de Aplicativo".

A API da Hotmart usa **OAuth 2.0** como forma de autenticação e o **access token** para tráfego da autorização de acesso aos recursos. Funciona tanto para **produção** quanto para o **[sandbox](https://developers.hotmart.com/docs/pt-BR/start/sandbox)** (ambiente de teste).

> **Segurança:** guarde credenciais e token com cuidado. A exposição permite que terceiros acessem suas informações. Em caso de dúvida, apague e gere novas credenciais.

## Gerar credenciais

1. Na plataforma, acesse **Ferramentas > [Credenciais Developers](https://app-vlc.hotmart.com/tools/credentials)**.
2. Clique em **Criar Credencial** e dê um nome (apenas para organização).
3. Escolha o **Tipo**:
   - **Sandbox:** marque a opção sandbox.
   - **Produção:** deixe a caixa em branco.
   - Clique em **Confirmar**. *O tipo **não pode ser alterado** depois — para mudar, crie uma nova credencial.*
4. Serão geradas três informações: **`client_id`**, **`client_secret`** e o **`token`** (do tipo Basic).

## Obter o access token

Com as credenciais em mãos, faça a requisição REST abaixo para obter o `access_token`.

### Parâmetros da requisição

| Parâmetro | Descrição |
|---|---|
| `client_id` | ID do cliente gerado na ferramenta de credenciais. |
| `client_secret` | Chave gerada na ferramenta de credenciais. |

### Requisição (Authorization Basic)

```bash
curl --location --request POST 'https://api-sec-vlc.hotmart.com/security/oauth/token?grant_type=client_credentials&client_id=:client_id&client_secret=:client_secret' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Basic :basic'
```

`POST https://api-sec-vlc.hotmart.com/security/oauth/token`

### Retorno

Em caso de sucesso, você recebe o `access_token`:

```json
{
  "access_token": "wxyz",
  "token_type": "bearer",
  "expires_in": 172799,
  "scope": "read write",
  "jti": "da2eff63-754d-4v76-9b3a-19bdb5cc8f36"
}
```

| Campo | Descrição |
|---|---|
| `expires_in` | Tempo (em segundos) até o token expirar. Após esse período, requisições com o mesmo token retornam erro **[401](https://developers.hotmart.com/docs/pt-BR/start/http-response-codes)**. |

> **Recomendação:** trate o erro 401 na sua aplicação e **refaça a geração do access token**. Apenas o **access token expira** — as credenciais (`client_id`, `client_secret` e Basic) permanecem as mesmas.
