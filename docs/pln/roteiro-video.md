# Roteiro do vídeo de PLN (3 a 5 min)

**Antes de gravar:**

1. Na API, rodar `npm run migrate:analise-cnpj` e pôr `ANTHROPIC_API_KEY` no `.env` (local) ou nas variáveis do Render.
2. Separar três CNPJs reais e públicos:
   - uma empresa de caçambas ativa;
   - uma empresa ativa de outro ramo (padaria, mercado);
   - um CNPJ com situação BAIXADA.
3. Cadastrar os três como fornecedor no app, com nomes parecidos com os da Receita. A análise já roda no cadastro.

## 1. O problema (0:00 a 0:30)

Mostrar a lista de usuários pendentes no painel do admin.

> "Quando um caçambeiro se cadastra, o admin precisa decidir se aprova. Antes, ele só tinha o que o próprio fornecedor digitou. Usamos PLN para ler os dados públicos do CNPJ e dizer se a empresa realmente trabalha com caçambas."

## 2. Funcionando (0:30 a 2:00)

- Abrir o cadastro da **empresa de caçambas** e tocar em "Análise do CNPJ com IA". Mostrar a nota, "Recomendo aprovar", a seção "Como a nota foi calculada", a justificativa da atividade (citar que o CNAE não tem a palavra "caçamba") e o parecer.
- Abrir o da **padaria**: atividade incompatível, "Recomendo recusar".
- Abrir o **CNPJ baixado**: reprovado pela regra, sem chamar a IA.
- Tocar em "Refazer análise" em um deles para mostrar a chamada ao vivo.
- Aprovar o primeiro pelo próprio sheet.

## 3. Onde está no código (2:00 a 4:00)

Abrir `CollectExpressAPI/src/services/analiseCnpjService.js`:

1. `consultarCnpj` e `resumirDadosReceita`: busca na BrasilAPI e descarta sócios, e-mail e telefone (LGPD).
2. `avaliarRegras`: situação cadastral e tempo de abertura, feitos por regra.
3. `INSTRUCOES`: o prompt, com os rótulos de atividade e de nome e a defesa contra prompt injection.
4. `ESQUEMA_RESPOSTA`: o JSON Schema que obriga o modelo a devolver só os rótulos permitidos.
5. `analisarTextoComIa`: a chamada ao Claude (modelo, esforço baixo, saída estruturada, fallback).
6. `PESOS` e `recomendar`: a nota vem de pesos fixos, e não do LLM.

Depois, de relance:

- `src/controllers/authController.js`: `agendarAnaliseDoCadastro` no cadastro.
- No app, `lib/features/admin/presentation/widgets/analise_cnpj_sheet.dart`: a tela.

## 4. Fechamento (4:00 a 4:30)

> "Técnica: classificação zero-shot e comparação de nomes com LLM, saída estruturada e geração do parecer, com grounding nos dados da Receita. Limitações: não medimos a acurácia com dados rotulados, o CNAE é autodeclarado e dependemos de APIs externas. Próximo passo: montar um conjunto rotulado e medir."
