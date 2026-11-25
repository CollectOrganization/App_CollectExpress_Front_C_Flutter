import '../../../../core/models/json_parsing.dart';

/// Recomendação da análise de CNPJ. Quem decide é o administrador.
enum RecomendacaoCnpj {
  aprovar('APROVAR', 'Recomendo aprovar'),
  revisar('REVISAR', 'Conferir antes de aprovar'),
  reprovar('REPROVAR', 'Recomendo recusar');

  const RecomendacaoCnpj(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static RecomendacaoCnpj fromApi(dynamic value) {
    return values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => RecomendacaoCnpj.revisar,
    );
  }
}

/// `GET/POST /usuarios/:id/analise-cnpj`: dados da Receita, regras fixas
/// e a parte em linguagem natural feita pelo LLM.
class AnaliseCnpj {
  /// De 0 a 10. `null` quando a IA não rodou e as regras sozinhas não
  /// bastam para dar nota.
  final double? nota;
  final RecomendacaoCnpj recomendacao;
  final String resumo;
  final String cnpj;
  final List<ChecagemCnpj> checagens;
  final ClassificacaoIa? atividade;
  final List<String> cnaesCompativeis;
  final ClassificacaoIa? nome;
  final List<String> pontosDeAtencao;
  final String parecer;
  final DadosReceita? dadosReceita;

  /// BrasilAPI ou Minha Receita.
  final String? fonte;
  final bool iaUsada;
  final String? modelo;

  /// Por que a IA não rodou, quando não rodou.
  final String? motivoSemIa;
  final DateTime? geradoEm;

  const AnaliseCnpj({
    required this.nota,
    required this.recomendacao,
    required this.resumo,
    required this.cnpj,
    this.checagens = const [],
    this.atividade,
    this.cnaesCompativeis = const [],
    this.nome,
    this.pontosDeAtencao = const [],
    this.parecer = '',
    this.dadosReceita,
    this.fonte,
    this.iaUsada = false,
    this.modelo,
    this.motivoSemIa,
    this.geradoEm,
  });

  factory AnaliseCnpj.fromJson(Map<String, dynamic> json) {
    final atividade = parseMap(json['atividade']);
    final nome = parseMap(json['nome']);
    final dados = parseMap(json['dados_receita']);
    final ia = parseMap(json['ia']) ?? const {};

    return AnaliseCnpj(
      nota: parseDoubleOrNull(json['nota']),
      recomendacao: RecomendacaoCnpj.fromApi(json['recomendacao']),
      resumo: parseString(json['resumo']),
      cnpj: parseString(json['cnpj']),
      checagens: parseList(json['checagens'], ChecagemCnpj.fromJson),
      atividade: atividade == null ? null : ClassificacaoIa.fromJson(atividade),
      cnaesCompativeis: _textos(atividade?['cnaes_compativeis']),
      nome: nome == null ? null : ClassificacaoIa.fromJson(nome),
      pontosDeAtencao: _textos(json['pontos_de_atencao']),
      parecer: parseString(json['parecer']),
      dadosReceita: dados == null ? null : DadosReceita.fromJson(dados),
      fonte: parseStringOrNull(json['fonte']),
      iaUsada: parseBool(ia['usada']),
      modelo: parseStringOrNull(ia['modelo']),
      motivoSemIa: parseStringOrNull(ia['motivo']),
      geradoEm: parseDate(json['gerado_em']),
    );
  }

  static List<String> _textos(dynamic value) {
    return value is List ? value.map((item) => item.toString()).toList() : [];
  }
}

/// Uma regra ou classificação que soma pontos na nota.
class ChecagemCnpj {
  final String item;
  final String resultado;

  /// `null` quando não se aplica.
  final bool? ok;
  final int pontos;
  final int maximo;

  const ChecagemCnpj({
    required this.item,
    required this.resultado,
    this.ok,
    this.pontos = 0,
    this.maximo = 0,
  });

  factory ChecagemCnpj.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'];

    return ChecagemCnpj(
      item: parseString(json['item']),
      resultado: parseString(json['resultado']),
      ok: ok is bool ? ok : null,
      pontos: parseInt(json['pontos']),
      maximo: parseInt(json['maximo']),
    );
  }
}

/// Rótulo escolhido pelo LLM e a justificativa em texto.
class ClassificacaoIa {
  final String classificacao;
  final String justificativa;

  const ClassificacaoIa({
    required this.classificacao,
    required this.justificativa,
  });

  factory ClassificacaoIa.fromJson(Map<String, dynamic> json) {
    return ClassificacaoIa(
      classificacao: parseString(json['classificacao']),
      justificativa: parseString(json['justificativa']),
    );
  }
}

/// Resumo dos dados públicos do CNPJ (sem sócios, e-mail ou telefone).
class DadosReceita {
  final String razaoSocial;
  final String nomeFantasia;
  final String situacaoCadastral;
  final DateTime? dataInicioAtividade;
  final Cnae? cnaePrincipal;
  final List<Cnae> cnaesSecundarios;
  final String municipio;
  final String uf;
  final bool mei;

  const DadosReceita({
    required this.razaoSocial,
    this.nomeFantasia = '',
    this.situacaoCadastral = '',
    this.dataInicioAtividade,
    this.cnaePrincipal,
    this.cnaesSecundarios = const [],
    this.municipio = '',
    this.uf = '',
    this.mei = false,
  });

  factory DadosReceita.fromJson(Map<String, dynamic> json) {
    final principal = parseMap(json['cnae_principal']);

    return DadosReceita(
      razaoSocial: parseString(json['razao_social']),
      nomeFantasia: parseString(json['nome_fantasia']),
      situacaoCadastral: parseString(json['situacao_cadastral']),
      dataInicioAtividade: parseDateOnly(json['data_inicio_atividade']),
      cnaePrincipal: principal == null ? null : Cnae.fromJson(principal),
      cnaesSecundarios: parseList(json['cnaes_secundarios'], Cnae.fromJson),
      municipio: parseString(json['municipio']),
      uf: parseString(json['uf']),
      mei: parseBool(json['opcao_pelo_mei']),
    );
  }
}

class Cnae {
  /// `3811-4/00`.
  final String codigo;
  final String descricao;

  const Cnae({required this.codigo, required this.descricao});

  factory Cnae.fromJson(Map<String, dynamic> json) {
    return Cnae(
      codigo: parseString(json['codigo']),
      descricao: parseString(json['descricao']),
    );
  }
}
