import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/aluguel.dart';
import '../../../core/models/avaliacao.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/models/pagina.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final pedidosRepositoryProvider = Provider<PedidosRepository>((ref) {
  return PedidosRepository(ref.watch(apiClientProvider));
});

/// Pedidos do consumidor logado.
class PedidosRepository {
  PedidosRepository(this._api);

  final ApiClient _api;

  /// Transforma o carrinho em pedido e esvazia o carrinho.
  /// [dataInicio] deve estar entre 1 e 60 dias a partir de hoje.
  ///
  /// A resposta não traz os itens; use [detalhe] para vê-los.
  Future<Aluguel> checkout({
    required String enderecoId,
    required DateTime dataInicio,
  }) async {
    final data = await _api.post(
      '/alugueis/checkout',
      data: {
        'endereco_id': enderecoId,
        'data_inicio': formatApiDate(dataInicio),
      },
    );

    return Aluguel.fromJson(parseMap(data) ?? const {});
  }

  Future<Pagina<Aluguel>> meusPedidos({int pagina = 1}) async {
    final data = await _api.get('/alugueis/meus', query: {'page': pagina});
    return Pagina.fromJson(data, Aluguel.fromJson);
  }

  /// Itens, contatos, endereço, avaliação e etapas do pedido.
  /// Também serve para o fornecedor e o admin.
  Future<Aluguel> detalhe(String id) async {
    return Aluguel.fromJson(
      parseMap(await _api.get('/alugueis/$id')) ?? const {},
    );
  }

  /// Só pedidos FINALIZADO podem ser avaliados, uma vez cada.
  /// [nota] de 1 a 5.
  Future<Avaliacao> avaliar({
    required String aluguelId,
    required int nota,
    String? comentario,
  }) async {
    final data = await _api.post(
      '/avaliacoes',
      data: {
        'aluguel_id': aluguelId,
        'nota': nota,
        if (comentario != null && comentario.trim().isNotEmpty)
          'comentario': comentario.trim(),
      },
    );

    return Avaliacao.fromJson(parseMap(data) ?? const {});
  }
}
