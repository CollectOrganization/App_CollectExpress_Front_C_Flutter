# Relatório de PLN: análise do CNPJ de fornecedores com IA no Collect Express

**Projeto:** Collect Express, app de locação de caçambas de entulho (TCC, Fatec Mauá, DSM)

**Integrantes:**

- Gabriel Andrade Ferreira
- Leonardo Dias dos Santos
- Pedro Henrique Batista dos Santos

**Repositórios:**

- API (Node.js): https://github.com/CollectOrganization/CollectExpressAPI
- App (Flutter): https://github.com/CollectOrganization/App_CollectExpress_Front_C_Flutter

Branch das duas: `feature/analise-cnpj-pln`.

---

## 1. Objetivo: que problema o PLN resolve

No Collect Express, quem aluga caçambas (o "caçambeiro") se cadastra com o CNPJ da empresa. A conta fica **pendente** até um administrador aprovar. Antes desta funcionalidade, o administrador só via o que o próprio fornecedor tinha digitado. Para saber se a empresa existia, se estava ativa e se trabalhava mesmo com caçambas, ele precisava consultar o CNPJ por fora e ler as atividades registradas na Receita.

A parte difícil dessa conferência é **texto**:

- **As atividades da empresa (CNAE) são descrições em linguagem natural**, e as compatíveis com locação de caçambas quase nunca têm a palavra "caçamba". Exemplos: "Coleta de resíduos não-perigosos" (3811-4/00) e "Aluguel de máquinas e equipamentos para construção sem operador, exceto andaimes" (7732-2/01). A tabela CNAE tem mais de 1.300 subclasses, e uma busca por palavra-chave erra esses casos.
- **O nome digitado no cadastro raramente é igual à razão social.** "JR Caçambas" pode ser o nome fantasia da "JR LOCACAO DE CACAMBAS LTDA". A razão social de um MEI costuma ser o nome do dono seguido de números. Comparar os dois exige entender abreviação, sigla e contexto, e não só igualdade de texto.
- **O administrador precisa de uma explicação curta**, e não de um JSON da Receita.

O PLN resolve esses três pontos. A análise roda sozinha logo depois do cadastro. Quando o administrador abre o cadastro pendente, já encontra uma **nota de 0 a 10**, uma **recomendação** (aprovar, revisar ou recusar), as checagens que formaram a nota e um **parecer em texto**. A decisão continua sendo do administrador: a IA recomenda, não aprova.

## 2. Técnica usada

A solução é um **pipeline híbrido de regras e LLM**. Cada parte faz o que faz melhor:

```mermaid
flowchart LR
    A[CNPJ do cadastro] --> B{Dígitos verificadores}
    B -- inválido --> R[Reprovar, nota 0]
    B -- ok --> C[BrasilAPI / Minha Receita]
    C -- não encontrado --> R
    C -- encontrado --> D{Situação ATIVA?}
    D -- não --> R
    D -- sim --> E[Regras: tempo de abertura]
    E --> F[LLM: atividade, nome e parecer]
    F --> G[Pesos fixos: nota 0 a 10]
    G --> H[Recomendação + parecer para o admin]
```

| Etapa | Técnica | Por que essa técnica |
|---|---|---|
| CNPJ válido, encontrado e ativo; tempo de abertura | Regras determinísticas | São fatos objetivos. Regra é exata, grátis e explicável. Quando reprova, o LLM nem é chamado. |
| Atividade compatível com o perfil | **Classificação de texto zero-shot com LLM** (3 classes: `PRINCIPAL_COMPATIVEL`, `SECUNDARIA_COMPATIVEL`, `INCOMPATIVEL`) | O critério é semântico ("serve para quem aluga caçamba?"). Não há base rotulada para treinar um classificador, e o LLM entende a descrição do CNAE sem treino. |
| Nome do cadastro x Receita | **Correspondência de entidades (entity matching) com LLM** (3 classes: `CONSISTENTE`, `PARCIAL`, `INCONSISTENTE`) | Trata sigla, abreviação, acento, sufixo (LTDA, ME) e razão social de MEI, que uma comparação de strings não trata. |
| Parecer para o administrador | **Geração de linguagem natural (NLG)** | Resume os dados e as checagens em 2 a 4 frases em português. |
| Formato da resposta | **Saída estruturada com JSON Schema** | O LLM só pode devolver os rótulos permitidos (enum) e os campos esperados, então o código lê a resposta sem adivinhar. |

Outros pontos de projeto:

- **Grounding em dados recuperados.** O LLM não "pesquisa" nem usa memória sobre a empresa. Ele recebe os dados oficiais consultados na hora e responde com base neles. É o mesmo princípio do RAG (recuperar um documento e gerar condicionado a ele), mas com uma consulta direta por chave (o CNPJ), sem base vetorial nem embeddings.
- **A nota não é escolhida pelo LLM.** O LLM devolve rótulos, e o código converte esses rótulos em pontos fixos:

  | Critério | Pontos |
  |---|---|
  | Situação cadastral ATIVA | 35 |
  | Tempo de abertura (2 anos ou mais: 15; de 6 meses a 2 anos: 8; menos de 6 meses: 0) | 15 |
  | Atividade (principal compatível: 40; só secundária: 25; incompatível: 0) | 40 |
  | Nome (confere: 10; em parte: 5; não confere: 0) | 10 |

  Nota = pontos ÷ 10. A recomendação é **recusar** se a atividade for incompatível ou a nota for menor que 5, e **aprovar** se a nota for 7 ou mais e o nome não for inconsistente. Nos outros casos, é **revisar**. Um nome que não confere segura a recomendação em "revisar" mesmo com nota alta, porque é o sinal típico de alguém usando o CNPJ de outra empresa.

  Com isso, a mesma classificação sempre gera a mesma nota, e o administrador vê de onde saiu cada ponto.
- **Engenharia de prompt.** O prompt de sistema descreve o app, define cada rótulo com critérios e exemplos de casos difíceis (MEI, nome fantasia) e proíbe o modelo de dar nota ou dizer que aprovou. Os dados da empresa vão delimitados em `<dados_cnpj>`, e o modelo é instruído a tratá-los como dados e nunca como instruções (defesa contra *prompt injection* por uma razão social maliciosa).
- **Minimização de dados (LGPD).** O quadro de sócios, o e-mail e o telefone que a Receita devolve são descartados antes de ir para o LLM e para o banco.
- **Humano no circuito.** O sistema recomenda e explica; aprovar ou recusar é sempre um clique do administrador.

## 3. Ferramentas, bibliotecas, modelos e APIs

| Item | Uso |
|---|---|
| **gpt-oss-120b** (`openai/gpt-oss-120b`), modelo de pesos abertos da OpenAI (licença Apache 2.0) | LLM das classificações e do parecer. Temperatura 0, raciocínio `low` (é classificação de texto curto) e saída estruturada com JSON Schema em modo estrito (`strict: true`), que limita a resposta aos campos e rótulos do schema. O modelo pode ser trocado pela variável `ANALISE_CNPJ_MODELO`. |
| **Groq**, rota `POST /openai/v1/chat/completions` (plano gratuito) | Hospeda o modelo. A API segue o formato de chat da OpenAI e é chamada com o `fetch` do próprio Node, sem SDK. Escolhemos a Groq pelo plano gratuito e pela velocidade (de 1,4 s a 1,8 s por análise nos testes reais). |
| **BrasilAPI**, rota `GET /api/cnpj/v1/{cnpj}` | Dados abertos do CNPJ na Receita Federal: razão social, nome fantasia, situação cadastral, data de abertura e CNAE principal e secundários. Gratuita e sem chave. |
| **Minha Receita** (`minhareceita.org`) | Reserva com o mesmo formato, usada quando a BrasilAPI falha. |
| Node.js 24, Express 5, PostgreSQL (Neon) | API REST. A análise fica salva em `analises_cnpj`, numa coluna JSONB. |
| Flutter / Dart, Riverpod e Dio | Tela do administrador. |
| Jest e `flutter_test` | Testes automatizados (o LLM é simulado nos testes). |

## 4. Onde está no código

### API (repositório CollectExpressAPI)

| Arquivo | Função ou trecho | O que faz |
|---|---|---|
| `src/services/analiseCnpjService.js` | `cnpjValido` | Confere os dígitos verificadores. |
| | `consultarCnpj` | Consulta a BrasilAPI e, se ela falhar, a Minha Receita. |
| | `resumirDadosReceita` | Fica só com os campos úteis e descarta sócios, e-mail e telefone. |
| | `avaliarRegras` | Regras de situação cadastral e tempo de abertura. |
| | `INSTRUCOES` | **Prompt de sistema** com as tarefas e a definição dos rótulos. |
| | `ESQUEMA_RESPOSTA` | **JSON Schema** da resposta do LLM. |
| | `montarMensagem` | Monta a mensagem com o perfil, o nome digitado e os dados delimitados. |
| | `analisarTextoComIa` | **A chamada ao LLM**: parâmetros (modelo, temperatura, schema), tratamento de resposta cortada e de recusa, leitura e validação do JSON. |
| | `chamarGroqPorHttp` | Envia o pedido à Groq com a chave e traduz os erros (sem chave, chave inválida, limite do plano gratuito, resposta fora do schema) em motivos que aparecem na tela. |
| | `analisarCnpj` | Orquestra o pipeline, aplica os pesos (`PESOS`), calcula a nota e monta a resposta. |
| | `recomendar` | Regra que transforma nota e rótulos em aprovar, revisar ou recusar. |
| | `gerarESalvarAnalise` / `agendarAnaliseDoCadastro` | Salva no banco. Dispara a análise em segundo plano logo depois do cadastro. |
| `src/controllers/analiseCnpjController.js` | `obter`, `gerar` | `GET` e `POST /api/usuarios/:id/analise-cnpj` (só ADMIN). |
| `src/routes/usuariosRoutes.js` | rotas `/:id/analise-cnpj` | Registro das rotas com autenticação e perfil ADMIN. |
| `src/controllers/authController.js` | `register` | Chama `agendarAnaliseDoCadastro` quando o cadastro fica pendente. |
| `src/scripts/analiseCnpjMigration.js` | | Cria a tabela `analises_cnpj` (`npm run migrate:analise-cnpj`). |
| `test/analiseCnpjService.test.js`, `test/analiseCnpjController.test.js` | | 29 testes: caçambeira ativa, padaria, nome que não confere, CNPJ inválido, inexistente e baixado, fonte reserva, falta de chave, erros da Groq (chave inválida, limite, fora do schema, fora do ar), resposta cortada e fora do formato. |

### App (repositório App_CollectExpress_Front_C_Flutter)

| Arquivo | O que faz |
|---|---|
| `lib/features/admin/domain/models/analise_cnpj.dart` | Modelo da análise (nota, recomendação, checagens, classificações, parecer, dados da Receita). |
| `lib/features/admin/data/admin_repository.dart` | `analiseCnpjSalva` (GET) e `gerarAnaliseCnpj` (POST, com espera de até 90 s por causa do LLM). |
| `lib/features/admin/presentation/widgets/analise_cnpj_sheet.dart` | Tela da análise: nota, recomendação, dados da Receita, "como a nota foi calculada", justificativas da IA, pontos de atenção, parecer e os botões Aprovar, Recusar e Refazer análise. |
| `lib/features/admin/presentation/pages/gestao_usuarios_page.dart` | Opção "Análise do CNPJ com IA" no menu do fornecedor (`_abrirAnaliseCnpj`). |
| `test/features/analise_cnpj_test.dart` | 5 testes do repositório e da tela. |

## 5. Exemplos de entrada e saída

### 5.1 Empresa de caçambas ativa (execução real)

Execução real em 25/11/2026, com dados públicos da Receita Federal: consulta à BrasilAPI e chamada à Groq com o modelo `openai/gpt-oss-120b`. A análise inteira levou 1,8 s, e a chamada ao LLM usou 1.130 tokens de entrada e 563 de saída. Os textos abaixo foram copiados da execução, sem edição.

**1. Entrada do administrador:** cadastro pendente de "CM Caçambas", CNPJ 17.223.825/0001-78 (CM Locações de Caçambas Ltda, de Sinop, MT).

**2. Mensagem enviada ao LLM** (saída de `montarMensagem`), junto com o prompt de sistema `INSTRUCOES`:

```text
Perfil do cadastro: fornecedor de caçambas, que aluga caçambas estacionárias para entulho e resíduos de construção, entrega e retira as caçambas com caminhão e leva os resíduos para a destinação.
Nome digitado no cadastro: "CM Caçambas"

<dados_cnpj>
{
  "razao_social": "CM LOCACOES DE CACAMBAS LTDA",
  "nome_fantasia": "ALO ENTULHO",
  "situacao_cadastral": "ATIVA",
  "motivo_situacao": "SEM MOTIVO",
  "data_inicio_atividade": "2012-11-28",
  "cnae_principal": {
    "codigo": "3811-4/00",
    "descricao": "Coleta de resíduos não-perigosos"
  },
  "cnaes_secundarios": [
    {
      "codigo": "4930-2/01",
      "descricao": "Transporte rodoviário de carga, exceto produtos perigosos e mudanças, municipal."
    },
    {
      "codigo": "7739-0/99",
      "descricao": "Aluguel de outras máquinas e equipamentos comerciais e industriais não especificados anteriormente, sem operador"
    }
  ],
  "natureza_juridica": "Sociedade Empresária Limitada",
  "porte": "EMPRESA DE PEQUENO PORTE",
  "municipio": "SINOP",
  "uf": "MT",
  "opcao_pelo_mei": false
}
</dados_cnpj>

Checagens automáticas já feitas:
- Situação cadastral: ATIVA
- Tempo de abertura: Aberta há 13 anos
```

O quadro de sócios, o e-mail e o telefone que a BrasilAPI devolveu não aparecem: foram descartados antes.

**3. Saída do LLM** (JSON no formato do schema):

```json
{
  "atividade": {
    "classificacao": "PRINCIPAL_COMPATIVEL",
    "cnaes_compativeis": ["3811-4/00"],
    "justificativa": "O CNAE principal 3811-4/00 (Coleta de resíduos não-perigosos) está alinhado ao serviço de locação e transporte de caçambas para entulho."
  },
  "nome": {
    "classificacao": "CONSISTENTE",
    "justificativa": "O nome digitado \"CM Caçambas\" corresponde à razão social \"CM LOCACOES DE CACAMBAS LTDA\", mantendo a sigla \"CM\" e a referência a caçambas; a diferença está apenas na presença da palavra \"LOCACOES\"."
  },
  "pontos_de_atencao": [
    "Verificar se a empresa possui frota de caçambas estacionárias para atender ao perfil de fornecedor.",
    "Confirmar se o nome fantasia \"ALO ENTULHO\" está relacionado ao mesmo negócio ou se indica outra atividade.",
    "Checar se o CNAE secundário 7739-0/99 (Aluguel de máquinas e equipamentos) cobre especificamente caçambas sem operador.",
    "Validar a regularidade fiscal e tributária além da situação cadastral ativa."
  ],
  "parecer": "A atividade principal da empresa é compatível com o fornecimento de caçambas, e o nome cadastrado apresenta correspondência clara com a razão social. Apesar do nome fantasia diferente, não há indícios de divergência grave. Recomenda-se confirmar a existência da frota e a relação do nome fantasia antes de concluir o cadastro."
}
```

O modelo entendeu que "Coleta de resíduos não-perigosos" serve para quem aluga caçamba, embora a descrição não tenha essa palavra. Também ligou "CM Caçambas" a "CM LOCACOES DE CACAMBAS LTDA" sem que os textos fossem iguais.

**4. Saída da API para o app** (resumida; a nota e a recomendação são calculadas pelo código a partir dos rótulos acima):

```json
{
  "cnpj": "**.***.825/0001-78",
  "nota": 10,
  "recomendacao": "APROVAR",
  "resumo": "Dados conferem com o perfil.",
  "checagens": [
    { "item": "Situação cadastral", "resultado": "ATIVA", "pontos": 35, "maximo": 35 },
    { "item": "Tempo de abertura", "resultado": "Aberta há 13 anos", "pontos": 15, "maximo": 15 },
    { "item": "Atividade compatível (IA)", "resultado": "Atividade principal compatível", "pontos": 40, "maximo": 40 },
    { "item": "Nome confere com a Receita (IA)", "resultado": "Nome confere", "pontos": 10, "maximo": 10 }
  ],
  "parecer": "A atividade principal da empresa é compatível com o fornecimento de caçambas, ...",
  "fonte": "BrasilAPI",
  "ia": { "usada": true, "modelo": "openai/gpt-oss-120b" }
}
```

### 5.2 Outros casos

Os dois primeiros são execuções reais; os demais são cobertos pelos testes automatizados.

| Entrada | O que acontece | Nota | Recomendação |
|---|---|---|---|
| Empresa de caçambas ativa há 13 anos, nome confere (real) | Fluxo completo do item 5.1 | 10 | Aprovar |
| Banco do Brasil se cadastrando como caçambeiro (real) | LLM classifica "Bancos múltiplos, com carteira comercial" como `INCOMPATIVEL` e o nome como `CONSISTENTE` (item 5.3) | 6 | Recusar |
| Padaria ativa se cadastrando como caçambeiro | LLM classifica a atividade como `INCOMPATIVEL` ("Fabricação de produtos de padaria...") | 5 | Recusar |
| Caçambeira ativa, mas nome digitado de outra empresa | LLM classifica o nome como `INCONSISTENTE` | 9 | Revisar |
| Caçambeira aberta há 2 meses | Perde os pontos de tempo e ganha o alerta "ainda não tem histórico" | 8,5 | Aprovar |
| CNPJ com situação BAIXADA | Reprovado pela regra, **sem chamar o LLM** | 0 | Recusar |
| CNPJ com dígito verificador errado | Reprovado sem consultar a Receita nem o LLM | 0 | Recusar |
| CNPJ que não existe na Receita | Reprovado pela regra | 0 | Recusar |
| API sem `GROQ_API_KEY` configurada | Só as regras rodam. Sem nota, a tela pede conferência manual da atividade e mostra o motivo. | – | Revisar |
| Limite do plano gratuito da Groq atingido | Igual ao caso sem chave, com o motivo "Limite do plano gratuito da Groq atingido". | – | Revisar |

### 5.3 O mesmo CNPJ com e sem o LLM (execução real)

Banco do Brasil (CNPJ público 00.000.000/0001-91) cadastrado como fornecedor de caçambas.

**Só com as regras** (sem `GROQ_API_KEY`):

```json
{
  "nota": null,
  "recomendacao": "REVISAR",
  "resumo": "Empresa ativa. Falta conferir a atividade.",
  "checagens": [
    { "item": "Situação cadastral", "resultado": "ATIVA", "pontos": 35, "maximo": 35 },
    { "item": "Tempo de abertura", "resultado": "Aberta há 60 anos", "pontos": 15, "maximo": 15 }
  ],
  "ia": { "usada": false, "motivo": "IA não configurada: defina GROQ_API_KEY no .env da API." }
}
```

**Com o LLM** (1,4 s; 1.076 tokens de entrada e 439 de saída):

```json
{
  "nota": 6,
  "recomendacao": "REPROVAR",
  "resumo": "A atividade da empresa não combina com o perfil.",
  "atividade": {
    "classificacao": "INCOMPATIVEL",
    "cnaes_compativeis": [],
    "justificativa": "Nenhum dos códigos CNAE (6422-1/00 – bancos múltiplos e 6499-9/99 – outros serviços financeiros) está relacionado a locação ou transporte de caçambas ou à destinação de resíduos."
  },
  "nome": {
    "classificacao": "CONSISTENTE",
    "justificativa": "O nome digitado corresponde exatamente à razão social \"BANCO DO BRASIL SA\", apenas omitindo a sigla societária."
  },
  "parecer": "A atividade econômica declarada pelo CNPJ não é compatível com o perfil de fornecedor de caçambas. O nome está consistente com a razão social. Recomenda-se confirmar a real prestação de serviços de locação de caçambas antes de prosseguir."
}
```

Esse caso mostra por que o LLM é necessário. As regras confirmam que o CNPJ existe e está ativo, mas não conseguem dizer que um banco não aluga caçambas. A nota 6 vem dos pontos de situação, tempo e nome; a recomendação é recusar porque a atividade é incompatível, independentemente da nota.

## 6. Limitações e possíveis melhorias

### Limitações

- **Não medimos a acurácia.** Não montamos um conjunto de CNPJs rotulados à mão, então não temos precisão e revocação das classificações do LLM. Os testes automatizados conferem o pipeline com respostas simuladas, e não a qualidade do modelo. As execuções reais do item 5 são exemplos, não uma medição.
- **O LLM erra em casos de fronteira e não é totalmente determinístico.** Mesmo com temperatura 0, duas execuções iguais podem trazer textos diferentes. No caso real do item 5.1, o modelo não marcou como compatíveis o 7739-0/99 ("Aluguel de outras máquinas e equipamentos... sem operador"), onde muitas empresas registram a locação de caçambas, nem o 4930-2/01 (transporte rodoviário de carga municipal); só levantou a dúvida nos pontos de atenção. A nota não mudou porque o CNAE principal já era compatível, mas numa empresa em que só esses CNAEs servissem, a atividade sairia como incompatível. Os pesos fixos e a decisão humana limitam o impacto, mas não eliminam o erro.
- **O CNAE é autodeclarado.** Uma empresa pode ter o CNAE certo sem operar caçambas, ou operar com o CNAE errado. A análise não confere licença ambiental, alvará, controle de transporte de resíduos (CTR), frota nem reclamações de clientes.
- **Dependência de serviços externos.** A BrasilAPI, a Minha Receita e o plano gratuito da Groq não têm garantia de disponibilidade. A base da Receita tem defasagem de atualização. O plano gratuito da Groq tem limite de requisições e de tokens por minuto e por dia. Sem a chave, com a Groq fora do ar ou acima do limite, o sistema funciona só com as regras.
- **Tempo e limite de uso.** Nas execuções reais, cada análise levou de 1,4 s a 1,8 s e usou cerca de 1.100 tokens de entrada e de 450 a 560 de saída. No plano gratuito não há custo em dinheiro: o limite é o número de chamadas. Como a análise roda em todo cadastro de fornecedor, cadastros falsos em massa gastam esse limite (há limite de requisições no cadastro).
- **Prompt injection.** Uma razão social ou nome digitado pode tentar dar ordens ao modelo. As defesas (dados delimitados, saída restrita a rótulos por schema, nota calculada pelo código, decisão humana) reduzem o risco, mas não o zeram.
- **Privacidade.** Os dados públicos da empresa e o nome digitado são enviados a um provedor externo (Groq). Sócios, e-mail e telefone não são enviados.
- **CNPJ alfanumérico.** A Receita Federal adotou o CNPJ com letras para novas inscrições a partir de julho de 2026. O cadastro do app e a validação de dígitos aceitam só números.
- **Escopo da tela.** A API analisa caçambeiros e parceiros de reciclagem, mas o app só mostra a análise para caçambeiros.
- **Análise em segundo plano sem fila.** Se o servidor reiniciar no meio da análise do cadastro, ela se perde. O administrador gera de novo com "Refazer análise".

### Possíveis melhorias

1. **Avaliação com dados rotulados.** Montar de 50 a 100 CNPJs reais (caçambeiras, recicladoras e empresas de outros ramos), rotular à mão e medir precisão, revocação e F1 das duas classificações. Comparar com uma linha de base por lista fixa de CNAEs e por palavras-chave.
2. **Exemplos no prompt (few-shot)** com os casos em que o modelo errar na avaliação, começando pelos CNAEs de aluguel de equipamentos e de transporte de carga do item 5.1.
3. **Comparar modelos e níveis de raciocínio** na mesma avaliação (por exemplo, o `openai/gpt-oss-20b`, menor e mais rápido), para achar o mais leve que mantém a qualidade.
4. **Reanálise periódica** dos fornecedores já aprovados, para pegar empresas que foram baixadas depois da aprovação.
5. **Mais fontes de dados:** licença ambiental estadual, cadastro de transportadores de resíduos da prefeitura e avaliações dos próprios clientes no app (análise de sentimentos dos comentários).
6. **Fila de tarefas** para a análise do cadastro, com nova tentativa automática.
7. **Mostrar a análise também para parceiros de reciclagem** no app e aceitar o CNPJ alfanumérico.
