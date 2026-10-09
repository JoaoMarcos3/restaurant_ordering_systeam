# API de pedidos para restaurante

API REST em TypeScript, Express e Supabase. O projeto foi dividido em etapas de aula por branches:

| Branch | Conteúdo |
| --- | --- |
| `aula-1` | Estrutura inicial da API e endpoints básicos. |
| `aula-2` | Refatoração da API e primeira evolução do catálogo. |
| `aula-3` | Persistência no Supabase, validações, pedidos transacionais e esquema SQL. |
| `aula-4` | Consulta detalhada do pedido e fluxo controlado de status. |
| `aula-5` | Paginação e filtros para consultas de produtos e pedidos. |
| `aula-6` | Verificação de saúde, índice do catálogo e dados iniciais repetíveis. |

## Executar

1. Instale Node.js e npm.
2. Instale as dependências com `npm install`.
3. Copie `.env.example` para `.env` e preencha `SUPABASE_URL` e `SUPABASE_SECRET_KEY`.
4. No painel do Supabase, abra o SQL Editor e execute em ordem `202610090001_schema_inicial.sql`, `202610090002_order_status.sql` e `202610090003_catalogo_unico.sql`.
5. Execute `supabase/seed.sql` para inserir categorias e produtos iniciais; o script pode ser executado novamente sem duplicar dados.
6. Inicie a API com `npm run dev`.

A API fica em `http://localhost:3000`. A chave secreta é usada apenas pelo servidor e o arquivo `.env` não deve ser versionado.

## Rotas

- `GET /` — informações da API.
- `GET /health` — verifica a conexão com o Supabase.
- `GET /categorias`, `GET /categorias/:id`, `POST /categorias`, `PUT /categorias/:id`, `DELETE /categorias/:id`.
- `GET /produtos`, `GET /produtos/:id`, `POST /produtos`, `PUT /produtos/:id`, `DELETE /produtos/:id`.
- `GET /pedidos`, `GET /pedidos/:id`, `POST /pedidos` e `PATCH /pedidos/:id/status`.

Os status seguem o fluxo `recebido` → `preparando` → `saiu_para_entrega` → `concluido`. O pedido também pode ser cancelado enquanto estiver recebido ou em preparação.

Para criar um produto, envie `categoryId`, `name`, `description` e `price`. As listas são paginadas (padrão: 20 itens): use `page` e `limit` (máximo 100). Produtos aceitam filtro `categoryId` e busca `q`; pedidos aceitam filtro `status`. Exemplos: `GET /produtos?categoryId=<uuid>&q=calabresa&page=1&limit=10` e `GET /pedidos?status=preparando&page=1&limit=20`.

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
