// Evidências dos casos de teste da API (Quadros 3 e 4 do relatório).
//
// Executa os cenários contra uma CollectExpressAPI rodando e grava o resultado,
// com o tempo de cada requisição, em test-results/api-evidence.json.
//
// Uso (Node 18 ou superior):
//   node tool/api_evidence.mjs
//
// Variáveis opcionais:
//   API_BASE_URL       padrão http://localhost:3001/api
//   FORNECEDOR_EMAIL   fornecedor ativo usado nos CT-12 e CT-14 (padrão: seed silva@cacambas.com)
//   FORNECEDOR_SENHA   padrão 123456 (senha do seed)
//
// Atenção: o roteiro grava no banco ligado à API um consumidor "Evidência TCC",
// um endereço e um pedido para uma caçamba do fornecedor acima.
import { mkdirSync, writeFileSync } from 'node:fs';

const BASE = (process.env.API_BASE_URL ?? 'http://localhost:3001/api').replace(/\/$/, '');
const FORNECEDOR = {
  email: process.env.FORNECEDOR_EMAIL ?? 'silva@cacambas.com',
  senha: process.env.FORNECEDOR_SENHA ?? '123456',
};

const execucao = Date.now();
const resultados = [];
const tempos = [];

async function chamar(metodo, rota, { token, corpo } = {}) {
  const inicio = performance.now();
  const resposta = await fetch(BASE + rota, {
    method: metodo,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: corpo === undefined ? undefined : JSON.stringify(corpo),
  });
  const ms = Math.round(performance.now() - inicio);
  let json = null;
  try {
    json = await resposta.json();
  } catch {
    // corpo vazio ou não JSON
  }
  tempos.push({ metodo, rota: rota.replace(/[0-9a-f-]{36}/g, ':id'), status: resposta.status, ms });
  return { status: resposta.status, json, ms, dados: json?.data ?? json };
}

function registrar(id, cenario, esperado, obtido, aprovado, detalhe) {
  resultados.push({ id, cenario, esperado, obtido, resultado: aprovado ? 'Aprovado' : 'Reprovado', detalhe });
  console.log(`${id} ${aprovado ? 'Aprovado ' : 'Reprovado'} ${cenario} -> ${obtido}${detalhe ? ` (${detalhe})` : ''}`);
}

function itensDaPagina(dados) {
  if (Array.isArray(dados)) return dados;
  return dados?.items ?? dados?.data ?? [];
}

function dataDaqui(dias) {
  const d = new Date();
  d.setDate(d.getDate() + dias);
  return d.toLocaleDateString('sv-SE'); // YYYY-MM-DD no fuso local
}

const sufixo = String(execucao).slice(-8);
const consumidor = {
  nome_completo: `Evidência TCC ${sufixo}`,
  email: `evidencia.tcc.${sufixo}@collectexpress.test`,
  senha: 'EvidTcc2026',
  tipo_perfil: 'CONSUMIDOR',
  documento: `9${sufixo}00`.slice(0, 11),
  telefone: '11999990000',
};

async function main() {
  const info = await chamar('GET', '/health');
  console.log(`API ${BASE} respondeu ${info.status}`);

  // CT-01 cadastro válido
  let r = await chamar('POST', '/auth/register', { corpo: consumidor });
  registrar('CT-01', 'Cadastro com campos obrigatórios preenchidos', 'HTTP 201', `HTTP ${r.status}`, r.status === 201);

  // CT-08 senha fora dos critérios
  r = await chamar('POST', '/auth/register', {
    corpo: { ...consumidor, email: `fraca.${consumidor.email}`, documento: consumidor.documento.replace(/^9/, '8'), senha: 'abc12345' },
  });
  registrar('CT-08', 'Cadastro com senha sem letra maiúscula', 'HTTP 400', `HTTP ${r.status}`, r.status === 400);

  // CT-09 perfil de parceiro de reciclagem
  r = await chamar('POST', '/auth/register', {
    corpo: { ...consumidor, email: `parceiro.${consumidor.email}`, documento: consumidor.documento.replace(/^9/, '7'), tipo_perfil: 'PARCEIRO_RECICLAGEM' },
  });
  registrar('CT-09', 'Cadastro com perfil PARCEIRO_RECICLAGEM', 'HTTP 201', `HTTP ${r.status}`, r.status === 201,
    r.status === 400 ? 'a API aceita somente CONSUMIDOR e CACAMBEIRO' : undefined);

  // CT-02 credenciais inválidas
  r = await chamar('POST', '/auth/login', { corpo: { email: consumidor.email, senha: 'SenhaErrada1' } });
  registrar('CT-02', 'Login com credenciais inválidas', 'HTTP 401', `HTTP ${r.status}`, r.status === 401);

  // CT-07 login válido
  r = await chamar('POST', '/auth/login', { corpo: { email: consumidor.email, senha: consumidor.senha } });
  const token = r.dados?.access_token ?? r.dados?.token;
  let refresh = r.dados?.refresh_token;
  registrar('CT-07', 'Login com credenciais válidas', 'HTTP 200 com token e perfil CONSUMIDOR', `HTTP ${r.status}`,
    r.status === 200 && Boolean(token) && r.dados?.usuario?.tipo_perfil === 'CONSUMIDOR',
    refresh ? 'access e refresh token retornados' : 'sem refresh token');
  if (!token) throw new Error('sem token do consumidor; os demais cenários dependem dele');

  // Renovação da sessão (RNF02)
  if (refresh) {
    r = await chamar('POST', '/auth/refresh', { corpo: { refresh_token: refresh } });
    refresh = r.dados?.refresh_token ?? refresh;
    registrar('CT-RT', 'Renovação da sessão com refresh token', 'HTTP 200 com novo access token', `HTTP ${r.status}`,
      r.status === 200 && Boolean(r.dados?.access_token));
  }

  // CT-04 consumidor em rota de ADMIN
  r = await chamar('GET', '/admin/dashboard', { token });
  registrar('CT-04', 'Acesso de CONSUMIDOR a operação ADMIN', 'HTTP 403', `HTTP ${r.status}`, r.status === 403);

  // Catálogo e escolha de caçambas de dois fornecedores
  r = await chamar('GET', '/cacambas?limit=50', {});
  const cacambas = itensDaPagina(r.dados).filter((c) => c.disponivel !== false);
  const fornecedorLogin = await chamar('POST', '/auth/login', { corpo: FORNECEDOR });
  const tokenFornecedor = fornecedorLogin.dados?.access_token ?? fornecedorLogin.dados?.token;
  const idFornecedor = fornecedorLogin.dados?.usuario?.id;
  const daFornecedora = cacambas.find((c) => c.cacambeiro_id === idFornecedor);
  const deOutro = cacambas.find((c) => c.cacambeiro_id !== idFornecedor);
  if (!tokenFornecedor || !daFornecedora || !deOutro) {
    throw new Error('é preciso um fornecedor ativo (FORNECEDOR_EMAIL) com caçamba disponível e outra caçamba de outro fornecedor');
  }

  // Endereço de entrega
  r = await chamar('POST', '/enderecos', {
    token,
    corpo: { cep: '01311200', logradouro: 'Avenida Paulista', numero: '1000', bairro: 'Bela Vista', cidade_estado: 'São Paulo/SP' },
  });
  const enderecoId = r.dados?.id ?? r.dados?.endereco?.id;

  // CT-11 checkout com carrinho vazio
  await chamar('DELETE', '/carrinho', { token });
  r = await chamar('POST', '/alugueis/checkout', { token, corpo: { endereco_id: enderecoId, data_inicio: dataDaqui(5) } });
  registrar('CT-11', 'Checkout com carrinho vazio', 'HTTP 400', `HTTP ${r.status}`, r.status === 400);

  // CT-10 carrinho com prestadores diferentes
  await chamar('POST', '/carrinho/itens', { token, corpo: { cacamba_id: daFornecedora.id, quantidade: 1, dias_aluguel: 3 } });
  r = await chamar('POST', '/carrinho/itens', { token, corpo: { cacamba_id: deOutro.id, quantidade: 1, dias_aluguel: 3 } });
  registrar('CT-10', 'Carrinho com caçambas de prestadores diferentes', 'HTTP 400', `HTTP ${r.status}`, r.status === 400);

  // CT-03 checkout válido
  r = await chamar('POST', '/alugueis/checkout', { token, corpo: { endereco_id: enderecoId, data_inicio: dataDaqui(5) } });
  const aluguel = r.dados?.aluguel ?? r.dados;
  const aluguelId = aluguel?.id ?? aluguel?.aluguel_id;
  registrar('CT-03', 'Solicitação de caçamba com dados válidos', 'HTTP 201', `HTTP ${r.status}`, r.status === 201 && Boolean(aluguelId),
    aluguel?.preco_final ? `preço final ${aluguel.preco_final}` : undefined);

  // CT-05 pedidos do consumidor
  r = await chamar('GET', '/alugueis/meus', { token });
  const meus = itensDaPagina(r.dados);
  registrar('CT-05', 'Consulta dos pedidos pelo consumidor', 'HTTP 200 com o pedido criado', `HTTP ${r.status}`,
    r.status === 200 && meus.some((a) => a.id === aluguelId));

  // CT-14 pedidos do prestador
  r = await chamar('GET', '/alugueis/gestao', { token: tokenFornecedor });
  const gestao = itensDaPagina(r.dados);
  registrar('CT-14', 'Consulta dos pedidos no painel do prestador', 'HTTP 200 com o pedido criado', `HTTP ${r.status}`,
    r.status === 200 && gestao.some((a) => (a.id ?? a.aluguel_id) === aluguelId));

  // CT-12 avanço de status pelo prestador
  r = await chamar('PATCH', `/alugueis/${aluguelId}/status`, { token: tokenFornecedor, corpo: { status_aluguel: 'EM_USO' } });
  registrar('CT-12', 'Atualização do estado do pedido pelo prestador', 'HTTP 200', `HTTP ${r.status}`, r.status === 200);

  // Tempo de resposta do catálogo público (20 requisições seguidas)
  const amostras = [];
  for (let i = 0; i < 20; i++) amostras.push((await chamar('GET', '/cacambas?limit=20')).ms);
  amostras.sort((a, b) => a - b);
  const desempenho = {
    rota: 'GET /cacambas?limit=20',
    requisicoes: amostras.length,
    media_ms: Math.round(amostras.reduce((s, v) => s + v, 0) / amostras.length),
    mediana_ms: amostras[Math.floor(amostras.length / 2)],
    p95_ms: amostras[Math.ceil(amostras.length * 0.95) - 1],
    max_ms: amostras.at(-1),
  };
  console.log('desempenho', desempenho);

  await chamar('POST', '/auth/logout', { token, corpo: { refresh_token: refresh } });
  return desempenho;
}

let desempenho = null;
let erro = null;
try {
  desempenho = await main();
} catch (e) {
  erro = e.message;
  console.error('interrompido:', e.message);
}

mkdirSync('test-results', { recursive: true });
writeFileSync('test-results/api-evidence.json', JSON.stringify({
  executado_em: new Date(execucao).toISOString(),
  api: BASE,
  resumo: {
    aprovados: resultados.filter((r) => r.resultado === 'Aprovado').length,
    reprovados: resultados.filter((r) => r.resultado === 'Reprovado').length,
  },
  resultados,
  desempenho,
  tempos,
  erro,
}, null, 2));
console.log('gravado em test-results/api-evidence.json');
process.exit(erro ? 1 : 0);
