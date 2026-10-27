import '../../../../core/models/enums.dart';
import '../../../../core/models/json_parsing.dart';

/// `GET /admin/dashboard`.
class AdminDashboard {
  final int totalUsuarios;
  final int totalPedidos;

  /// Soma dos pedidos com pagamento PAGO.
  final double receitaTotal;

  /// 5% da receita total.
  final double lucroPlataforma;

  /// Fornecedores ativos com pelo menos uma caçamba disponível.
  final int cacambeirosAtivos;

  final Map<StatusAluguel, int> pedidosPorStatus;

  /// Últimos 30 dias, por dia ou por semana.
  final List<PontoGrafico> pedidosAoLongoDoTempo;

  const AdminDashboard({
    required this.totalUsuarios,
    required this.totalPedidos,
    required this.receitaTotal,
    required this.lucroPlataforma,
    required this.cacambeirosAtivos,
    this.pedidosPorStatus = const {},
    this.pedidosAoLongoDoTempo = const [],
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final porStatus = <StatusAluguel, int>{};
    parseMap(json['pedidos_por_status'])?.forEach((status, total) {
      final value = StatusAluguel.fromApi(status);
      if (value != null) porStatus[value] = parseInt(total);
    });

    return AdminDashboard(
      totalUsuarios: parseInt(json['total_usuarios']),
      totalPedidos: parseInt(json['total_pedidos']),
      receitaTotal: parseDouble(json['receita_total']),
      lucroPlataforma: parseDouble(json['lucro_plataforma']),
      cacambeirosAtivos: parseInt(json['cacambeiros_ativos']),
      pedidosPorStatus: porStatus,
      pedidosAoLongoDoTempo: parseList(
        json['pedidos_ao_longo_do_tempo'],
        PontoGrafico.fromJson,
      ),
    );
  }
}

class PontoGrafico {
  final DateTime? data;
  final int quantidade;

  const PontoGrafico({required this.data, required this.quantidade});

  factory PontoGrafico.fromJson(Map<String, dynamic> json) {
    return PontoGrafico(
      data: parseDateOnly(json['date']),
      quantidade: parseInt(json['count']),
    );
  }
}
