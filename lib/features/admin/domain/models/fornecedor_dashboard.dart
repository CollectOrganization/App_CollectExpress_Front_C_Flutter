import '../../../../core/models/aluguel.dart';
import '../../../../core/models/json_parsing.dart';

/// `GET /cacambeiros/dashboard`: resumo do fornecedor logado.
class FornecedorDashboard {
  final int totalPedidos;
  final int pedidosAtivos;
  final double receitaBruta;
  final double taxaPlataforma;

  /// Receita bruta menos a taxa de 5% da plataforma.
  final double receitaLiquida;

  final double? notaMedia;
  final int totalAvaliacoes;

  const FornecedorDashboard({
    required this.totalPedidos,
    required this.pedidosAtivos,
    required this.receitaBruta,
    required this.taxaPlataforma,
    required this.receitaLiquida,
    this.notaMedia,
    this.totalAvaliacoes = 0,
  });

  factory FornecedorDashboard.fromJson(Map<String, dynamic> json) {
    return FornecedorDashboard(
      totalPedidos: parseInt(json['total_orders']),
      pedidosAtivos: parseInt(json['active_orders']),
      receitaBruta: parseDouble(json['total_revenue_bruto']),
      taxaPlataforma: parseDouble(json['taxa_plataforma']),
      receitaLiquida: parseDouble(json['total_revenue']),
      notaMedia: parseDoubleOrNull(json['nota_media']),
      totalAvaliacoes: parseInt(json['total_avaliacoes']),
    );
  }
}

/// `GET /cacambeiros/financeiro`: pedidos FINALIZADO e PAGO no período.
class RelatorioFinanceiro {
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final double total;
  final double taxaPlataforma;
  final double totalLiquido;
  final int quantidade;
  final List<Aluguel> pedidos;

  const RelatorioFinanceiro({
    required this.total,
    required this.taxaPlataforma,
    required this.totalLiquido,
    required this.quantidade,
    this.dataInicio,
    this.dataFim,
    this.pedidos = const [],
  });

  factory RelatorioFinanceiro.fromJson(Map<String, dynamic> json) {
    final periodo = parseMap(json['periodo']) ?? const {};
    final resumo = parseMap(json['resumo_mensal']) ?? const {};

    return RelatorioFinanceiro(
      dataInicio: parseDateOnly(periodo['data_inicio']),
      dataFim: parseDateOnly(periodo['data_fim']),
      total: parseDouble(resumo['total']),
      taxaPlataforma: parseDouble(resumo['taxa_plataforma']),
      totalLiquido: parseDouble(resumo['total_liquido']),
      quantidade: parseInt(resumo['quantidade']),
      pedidos: parseList(json['pedidos'], Aluguel.fromJson),
    );
  }
}
