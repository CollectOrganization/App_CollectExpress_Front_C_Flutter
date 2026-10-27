# CollectExpress – aplicativo Flutter

Aplicativo multiplataforma (Web e Android) do CollectExpress, plataforma de locação de caçambas que reúne consumidores, fornecedores de caçambas e administradores. O app consome a [CollectExpressAPI](https://github.com/CollectOrganization/CollectExpressAPI) (Node.js, Express e PostgreSQL).

Projeto acadêmico do Curso Superior de Tecnologia em Desenvolvimento de Software Multiplataforma da Fatec Mauá.

## Tecnologias

| Uso | Pacote |
| :- | :- |
| Interface | Flutter 3 e Dart 3 |
| Estado e injeção de dependências | flutter_riverpod |
| Cliente HTTP da API | dio |
| Armazenamento dos tokens | flutter_secure_storage |
| URL da API pelo arquivo `.env` | flutter_dotenv |
| Consulta de CEP (ViaCEP) | http |
| Tipografia | google_fonts |

## Como rodar

Pré-requisitos: Flutter SDK (stable) e a API rodando, local ou publicada.

```bash
flutter pub get

# Sem --dart-define, a URL da API vem do API_URL do arquivo .env
# (versionado com http://localhost:3001/api)
flutter run -d chrome

# Android (emulador): o localhost da máquina é 10.0.2.2
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3001/api
```

Para gerar as versões de distribuição:

```bash
flutter build web --dart-define=API_URL=https://sua-api/api
flutter build apk --dart-define=API_URL=https://sua-api/api
```

O nome antigo `API_BASE_URL` também é aceito no `--dart-define`.

## Estrutura

```
lib/
  core/
    models/        modelos da API (usuário, caçamba, carrinho, aluguel...)
    network/       ApiClient (Dio), configuração, erros e interceptor de autenticação
    navigation/    rotas nomeadas
    services/      serviços externos (ViaCEP)
    theme/ widgets/ responsive/ utils/
  features/
    auth/          login, cadastro e sessão
    admin_auth/    login e cadastro do administrador
    cacambas/      catálogo e detalhe
    pedidos/       carrinho, agendamento, confirmação e acompanhamento
    perfil/        perfil e endereços do cliente
    admin/         painéis do fornecedor e do administrador
    parceiros_reciclagem/  telas demonstrativas de reciclagem
    institucional/ página "Saiba mais"
test/              testes de modelos, ApiClient, repositórios e telas
tool/              scripts que geram as evidências de teste
```

Cada funcionalidade separa a camada de dados (`data/`: repositórios e providers que chamam a API) da camada de apresentação (`presentation/`: páginas e widgets). As telas leem os dados pelos providers do Riverpod, e os repositórios usam um único `ApiClient`.

## Autenticação

O login devolve um access token (JWT) e, nas versões da API que o fornecem, um refresh token. Os dois ficam no `flutter_secure_storage`. O `AuthInterceptor` coloca o token nas requisições e, quando a API responde 401, renova a sessão em `POST /auth/refresh` e repete a requisição uma vez. Se a renovação falhar, a sessão é encerrada.

## Testes

```bash
flutter analyze
flutter test
```

A saída completa da última execução está em [test-results/flutter-test.txt](test-results/flutter-test.txt).

`dart run tool/cep_evidence.dart` consulta o ViaCEP com o mesmo serviço usado nos formulários e grava o resultado em [test-results/cep-evidence.txt](test-results/cep-evidence.txt).

## Situação das telas

| Situação | Telas |
| :- | :- |
| Integradas à API | login (cliente, fornecedor e admin), cadastro de cliente, cadastro de admin, catálogo e detalhe, carrinho, agendamento e checkout, acompanhamento e avaliação, perfil do cliente, painel, caçambas e pedidos do fornecedor, painel geral do admin |
| Pendentes | envio dos cadastros de fornecedor e de parceiro de reciclagem, cadastro de caçamba, busca por CEP na página inicial, gestão de usuários e de parceiros, relatório financeiro, configurações, perfil da loja |
| Demonstrativas | telas de reciclagem (materiais, parceiros e coletas) |

## Autores

Gabriel Andrade Ferreira, Leonardo Dias dos Santos e Pedro Henrique Batista dos Santos. Orientação: profa. Edilma Bindá Hungria Melo.
