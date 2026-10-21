import 'json_parsing.dart';

/// Tabela `avaliacoes`.
class Avaliacao {
  final String id;
  final String? aluguelId;
  final String? consumidorId;
  final String? cacambeiroId;

  /// De 1 a 5.
  final int nota;

  final String? comentario;
  final DateTime? dataAvaliacao;

  /// Nas listagens públicas de avaliações.
  final String? consumidorNome;

  const Avaliacao({
    required this.id,
    required this.nota,
    this.aluguelId,
    this.consumidorId,
    this.cacambeiroId,
    this.comentario,
    this.dataAvaliacao,
    this.consumidorNome,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: parseString(json['id']),
      aluguelId: parseStringOrNull(json['aluguel_id']),
      consumidorId: parseStringOrNull(json['consumidor_id']),
      cacambeiroId: parseStringOrNull(json['cacambeiro_id']),
      nota: parseInt(json['nota']),
      comentario: parseStringOrNull(json['comentario']),
      dataAvaliacao: parseDate(json['data_avaliacao']),
      consumidorNome: parseStringOrNull(json['consumidor_nome']),
    );
  }
}
