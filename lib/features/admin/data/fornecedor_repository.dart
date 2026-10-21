import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/aluguel.dart';
import '../../../core/models/cacamba.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../domain/models/fornecedor_dashboard.dart';

final fornecedorRepositoryProvider = Provider<FornecedorRepository>((ref) {
  return FornecedorRepository(ref.watch(apiClientProvider));
});

/// Área do fornecedor (CACAMBEIRO): painel, caçambas e pedidos recebidos.
class FornecedorRepository {
  FornecedorRepository(this._api);

  final ApiClient _api;

  Future<FornecedorDashboard> dashboard() async {
    final data = await _api.get('/cacambeiros/dashboard');
    return FornecedorDashboard.fromJson(parseMap(data) ?? const {});
  }

  /// Informe [mes] e [ano], ou [dataInicio] e [dataFim] (até 366 dias).
  /// Sem nenhum, usa o mês atual.
  Future<RelatorioFinanceiro> financeiro({
    int? mes,
    int? ano,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final data = await _api.get(
      '/cacambeiros/financeiro',
      query: {
        'mes': ?mes,
        'ano': ?ano,
        if (dataInicio != null) 'data_inicio': formatApiDate(dataInicio),
        if (dataFim != null) 'data_fim': formatApiDate(dataFim),
      },
    );

    return RelatorioFinanceiro.fromJson(parseMap(data) ?? const {});
  }

  /// Todas as caçambas do fornecedor, inclusive as indisponíveis.
  Future<List<Cacamba>> minhasCacambas() async {
    return parseList(await _api.get('/cacambas/minhas'), Cacamba.fromJson);
  }

  /// [tipoResiduo] precisa ser o nome de uma categoria cadastrada.
  Future<Cacamba> criarCacamba({
    required String nome,
    required String tipoResiduo,
    required double tamanhoM3,
    required double precoDiaria,
    String? fotoUrl,
  }) async {
    final data = await _api.post(
      '/cacambas',
      data: {
        'nome': nome.trim(),
        'tipo_residuo': tipoResiduo,
        'tamanho_m3': tamanhoM3,
        'preco_diaria': precoDiaria,
        'foto_url': ?fotoUrl,
      },
    );

    return Cacamba.fromJson(parseMap(data) ?? const {});
  }

  /// Envia só os campos informados. [removerFoto] apaga a foto atual.
  Future<Cacamba> atualizarCacamba(
    String id, {
    String? nome,
    String? tipoResiduo,
    double? tamanhoM3,
    double? precoDiaria,
    String? fotoUrl,
    bool removerFoto = false,
    bool? disponivel,
  }) async {
    final data = await _api.put(
      '/cacambas/$id',
      data: {
        if (nome != null) 'nome': nome.trim(),
        'tipo_residuo': ?tipoResiduo,
        'tamanho_m3': ?tamanhoM3,
        'preco_diaria': ?precoDiaria,
        if (removerFoto) 'foto_url': null else 'foto_url': ?fotoUrl,
        'disponivel': ?disponivel,
      },
    );

    return Cacamba.fromJson(parseMap(data) ?? const {});
  }

  /// Devolve `true` se a caçamba foi apagada, ou `false` se ela tinha
  /// histórico de pedidos e por isso só foi desativada.
  Future<bool> removerCacamba(String id) async {
    final data = parseMap(await _api.delete('/cacambas/$id'));
    return data?['removed'] == true;
  }

  /// Pedidos recebidos, com contato do cliente e endereço de entrega.
  Future<List<Aluguel>> pedidosRecebidos() async {
    return parseList(await _api.get('/alugueis/gestao'), Aluguel.fromJson);
  }

  /// Avança o pedido uma etapa por vez:
  /// AGUARDANDO_ENTREGA → EM_USO → AGUARDANDO_RETIRADA → FINALIZADO.
  Future<Aluguel> atualizarStatus(
    String aluguelId,
    StatusAluguel status,
  ) async {
    final data = await _api.patch(
      '/alugueis/$aluguelId/status',
      data: {'status_aluguel': status.apiValue},
    );

    return Aluguel.fromJson(parseMap(data) ?? const {});
  }
}
