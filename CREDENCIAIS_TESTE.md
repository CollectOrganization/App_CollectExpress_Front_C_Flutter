# Credenciais de teste

Contas criadas pelo seed da API (`src/scripts/seed.js`). Valem para o app rodando localmente e para o site publicado, porque os dois usam o mesmo banco.

**Senha de todas as contas: `123456`**, exceto onde indicado.

Conferido no banco em 27/10/2026.

## Contas que entram no app

| Perfil | E-mail | Onde entrar | O que dá para testar |
| :- | :- | :- | :- |
| Administrador | `admin@collectexpress.com` | Login do administrador (`/admin/login`) ou login comum | Painel do admin |
| Cliente | `maria@reformas.com` | Login comum (`/login`) | Catálogo, carrinho, pedidos, pagamento por Pix, perfil e endereços |
| Cliente | `joao@construtor.com` | Login comum (`/login`) | Mesmo que a Maria. **A senha foi trocada e não é mais `123456`.** Para voltar a usar, peça a senha nova a quem trocou ou rode o seed de novo. |
| Fornecedor | `silva@cacambas.com` | Login comum (`/login`) | Painel do fornecedor, minhas caçambas e pedidos recebidos. Tem as 3 caçambas do catálogo. |

## Contas bloqueadas de propósito

Servem para testar as mensagens de cadastro pendente e de conta suspensa. Todas usam a senha `123456`, mas o login é recusado.

| Perfil | Status | E-mail |
| :- | :- | :- |
| Administrador | Pendente | `admin.pendente@collectexpress.com` |
| Administrador | Suspenso | `admin.suspenso@collectexpress.com` |
| Cliente | Pendente | `consumidor.pendente@collectexpress.com` |
| Cliente | Suspenso | `consumidor.suspenso@collectexpress.com` |
| Fornecedor | Pendente | `contato@entulhorapido.com` |
| Fornecedor | Suspenso | `cacambeiro.suspenso@collectexpress.com` |

As caçambas dos fornecedores pendente e suspenso ("Caçamba Pendente 5m³" e "Caçamba Suspensa 5m³") não aparecem no catálogo. A API só lista caçambas de fornecedor ativo.

## Pagamento por Pix

A API usa a chave do modo de teste da AbacatePay: nada é cobrado de verdade. Em um pedido com pagamento pendente, toque em "Pagar com Pix" e depois em "Simular pagamento". Não leia o QR Code com o app do banco.

## Cuidados

- O banco é o mesmo do site publicado. Pedidos, endereços e alterações feitos nos testes aparecem lá também.
- Rodar o seed (`npm run seed` na API) **apaga todos os dados** e recria estas contas com a senha `123456`.
- Estas senhas são públicas: estão neste arquivo e no seed da API, e os dois repositórios são públicos. Não use estas contas para dados reais.
