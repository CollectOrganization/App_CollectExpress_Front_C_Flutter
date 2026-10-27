import 'json_parsing.dart';

/// Tabela `categorias`. O `nome` é o que vai em `Cacamba.tipoResiduo`.
class Categoria {
  final String id;
  final String nome;
  final DateTime? criadoEm;

  /// Só na listagem do admin.
  final int? cacambasCount;

  const Categoria({
    required this.id,
    required this.nome,
    this.criadoEm,
    this.cacambasCount,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: parseString(json['id']),
      nome: parseString(json['nome']),
      criadoEm: parseDate(json['criado_em']),
      cacambasCount: parseIntOrNull(json['cacambas_count']),
    );
  }
}
