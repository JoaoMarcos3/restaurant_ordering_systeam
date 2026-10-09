# API de pedidos para restaurante

API REST em TypeScript, Express e Supabase. O projeto foi dividido em etapas de aula por branches:

| Branch | Conteúdo |
| --- | --- |
| `aula-1` | Estrutura inicial da API e endpoints básicos. |
| `aula-2` | Evolução do catálogo e implementação de pedidos em memória. |
| `aula-3` | Persistência no Supabase, validações, pedidos transacionais e esquema SQL. |
| `aula-4` | Consulta detalhada do pedido e fluxo controlado de status. |

## Executar

1. Instale Node.js e npm.
2. Instale as dependências com `npm install`.
3. Copie `.env.example` para `.env` e preencha `SUPABASE_URL` e `SUPABASE_SECRET_KEY`.
4. No painel do Supabase, abra o SQL Editor e execute as migrações em ordem: `202610090001_schema_inicial.sql`, depois `202610090002_order_status.sql`.
5. Inicie a API com `npm run dev`.

A API fica em `http://localhost:3000`. A chave secreta é usada apenas pelo servidor e o arquivo `.env` não deve ser versionado.

## Rotas

- `GET /` — informações da API.
- `GET /categorias`, `GET /categorias/:id`, `POST /categorias`, `PUT /categorias/:id`, `DELETE /categorias/:id`.
- `GET /produtos`, `GET /produtos/:id`, `POST /produtos`, `PUT /produtos/:id`, `DELETE /produtos/:id`.
- `GET /pedidos`, `GET /pedidos/:id`, `POST /pedidos` e `PATCH /pedidos/:id/status`.

Os status seguem o fluxo `recebido` → `preparando` → `saiu_para_entrega` → `concluido`. O pedido também pode ser cancelado enquanto estiver recebido ou em preparação.

Para criar um produto, envie `categoryId`, `name`, `description` e `price`. Para filtrar produtos por categoria, use `GET /produtos?categoryId=<uuid>`.

Exemplo de criação de pedido:

```json
{
  "customerName": "Maria",
  "items": [
    { "productId": "UUID_DO_PRODUTO", "quantity": 2 }
  ]
}
```

O banco calcula o total usando os preços atuais dos produtos e guarda o nome e preço de cada item no pedido. A função SQL cria o pedido e seus itens na mesma transação.

## Observação sobre chaves

Uma chave secreta do Supabase foi compartilhada durante a configuração. Considere-a exposta, revogue-a e gere outra no painel antes de usar o projeto. Use a chave nova apenas em `.env` como `SUPABASE_SECRET_KEY`. Nunca a envie ao navegador nem faça commit dela. A chave publicável pode ser usada em clientes de navegador quando necessário, com políticas RLS apropriadas.
