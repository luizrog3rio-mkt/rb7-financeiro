# Endpoint: Obter o Progresso do Aluno

> Referência: documentação Hotmart Developers — seção "Área de membros" > "Obter o progresso do aluno".

Retorna o progresso de um aluno no curso — quais páginas foram concluídas (e quando) e quais ainda não foram.

`GET /club/api/v1/users/{user_id}/lessons`

## Parâmetros da requisição

| Local | Parâmetro | Obrigatório | Descrição |
|---|---|---|---|
| Query | `subdomain` | sim | Subdomínio da Área de Membros (definido na administração do Club). |
| Path | `user_id` | sim | Identificador do aluno (obtido via endpoint [Obter Alunos](./endpoint-obter-alunos.md)). |

### Requisição

```bash
curl --location --request GET 'https://developers.hotmart.com/club/api/v1/users/{user_id}/lessons?subdomain=my-subdomain' \
	--header 'Content-Type: application/json' \
	--header 'Authorization: Bearer :access_token'
```

## Retorno — `lessons[]`

| Campo | Tipo | Descrição |
|---|---|---|
| `page_id` | string | Identificador único da página. |
| `page_name` | string | Nome da página (definido pelo produtor). |
| `module_name` | string | Nome do módulo. |
| `is_module_extra` | boolean | `true` se é um módulo extra. |
| `is_completed` | boolean | `true` se a página já foi concluída pelo aluno. |
| `completed_date` | long | Data de conclusão. **Só retornado quando `is_completed = true`.** |

### Exemplo de resposta (200 - Success)

```json
{
  "lessons": [
    {
      "page_id": "RMe1YEyeYx",
      "page_name": "Page 1 Module 1",
      "module_name": "Module 1",
      "is_module_extra": false,
      "is_completed": true,
      "completed_date": 1609984800000
    },
    {
      "page_id": "PBeZln8Ow5",
      "page_name": "Page 2 Module 2",
      "module_name": "Module 2",
      "is_module_extra": false,
      "is_completed": false
    },
    {
      "page_id": "EM7qz2NOxw",
      "page_name": "Module driping - BY_DATE",
      "module_name": "Module Dripping",
      "is_module_extra": false,
      "is_completed": false
    }
  ]
}
```

## Sandbox

Troque a URL base para `https://sandbox.hotmart.com` e use a credencial do ambiente Sandbox.

| Cenário de teste | HTTP | Parâmetro | Valor |
|---|---|---|---|
| Sucesso | `200` | `subdomain` | `my_subdomain` |
| | | `user_id` | `N2OM623N46`, `WX7WPWRQO2`, `ZYOMWXLDED` |
| `subdomain` é obrigatório | `422` | sem parâmetros | — |
