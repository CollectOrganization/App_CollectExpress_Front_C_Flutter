import 'cacamba.dart';
import 'json_parsing.dart';

/// Tabelas `carrinho` + `itens_carrinho`, com os totais calculados pela API.
///
/// Todos os itens são do mesmo fornecedor. Sem carrinho criado, a API
/// devolve um carrinho vazio com `id` nulo.
class Carrinho {
  final String? id;
  final String? consumidorId;
  final String? cacambeiroId;
  final DateTime? criadoEm;
  final List<ItemCarrinho> itens;
  final ResumoCarrinho resumo;

  const Carrinho({
    this.id,
    this.consumidorId,
    this.cacambeiroId,
    this.criadoEm,
    this.itens = const [],
    this.resumo = const ResumoCarrinho(),
  });

  bool get isEmpty => itens.isEmpty;

  factory Carrinho.fromJson(Map<String, dynamic> json) {
    final resumo = parseMap(json['resumo']);

    return Carrinho(
      id: parseStringOrNull(json['id']),
      consumidorId: parseStringOrNull(json['consumidor_id']),
      cacambeiroId: parseStringOrNull(json['cacambeiro_id']),
      criadoEm: parseDate(json['criado_em']),
      itens: parseList(json['itens'], ItemCarrinho.fromJson),
      resumo: resumo == null
          ? const ResumoCarrinho()
          : ResumoCarrinho.fromJson(resumo),
    );
  }
}

class ItemCarrinho {
  final String id;
  final String cacambaId;

  /// De 1 a 10.
  final int quantidade;

  /// De 1 a 30.
  final int diasAluguel;

  /// quantidade × dias × preço da diária.
  final double subtotal;

  final Cacamba? cacamba;

  const ItemCarrinho({
    required this.id,
    required this.cacambaId,
    required this.quantidade,
    required this.diasAluguel,
    required this.subtotal,
    this.cacamba,
  });

  factory ItemCarrinho.fromJson(Map<String, dynamic> json) {
    final cacamba = parseMap(json['cacamba']);

    return ItemCarrinho(
      id: parseString(json['id']),
      cacambaId: parseString(json['cacamba_id'] ?? cacamba?['id']),
      quantidade: parseInt(json['quantidade']),
      diasAluguel: parseInt(json['dias_aluguel']),
      subtotal: parseDouble(json['subtotal']),
      cacamba: cacamba == null ? null : Cacamba.fromJson(cacamba),
    );
  }
}

class ResumoCarrinho {
  /// Soma das quantidades, não o número de linhas.
  final int quantidadeItens;

  final double subtotal;

  /// Taxa de entrega do fornecedor.
  final double taxaEntrega;

  /// subtotal + taxa de entrega.
  final double totalEstimado;

  const ResumoCarrinho({
    this.quantidadeItens = 0,
    this.subtotal = 0,
    this.taxaEntrega = 0,
    this.totalEstimado = 0,
  });

  factory ResumoCarrinho.fromJson(Map<String, dynamic> json) {
    return ResumoCarrinho(
      quantidadeItens: parseInt(json['quantidade_itens']),
      subtotal: parseDouble(json['subtotal']),
      taxaEntrega: parseDouble(json['taxa_entrega']),
      totalEstimado: parseDouble(json['total_estimado']),
    );
  }
}
