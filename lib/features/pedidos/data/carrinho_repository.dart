import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/carrinho.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final carrinhoRepositoryProvider = Provider<CarrinhoRepository>((ref) {
  return CarrinhoRepository(ref.watch(apiClientProvider));
});

/// Carrinho do consumidor logado. Toda alteração devolve o carrinho
/// atualizado, com os totais recalculados pela API.
///
/// Todos os itens precisam ser do mesmo fornecedor.
class CarrinhoRepository {
  CarrinhoRepository(this._api);

  final ApiClient _api;

  Future<Carrinho> obter() async => _carrinho(await _api.get('/carrinho'));

  /// [quantidade] de 1 a 10, [diasAluguel] de 1 a 30.
  Future<Carrinho> adicionar({
    required String cacambaId,
    int quantidade = 1,
    int diasAluguel = 1,
  }) async {
    final data = await _api.post(
      '/carrinho/itens',
      data: {
        'cacamba_id': cacambaId,
        'quantidade': quantidade,
        'dias_aluguel': diasAluguel,
      },
    );

    return _carrinho(data);
  }

  Future<Carrinho> atualizarItem(
    String itemId, {
    int? quantidade,
    int? diasAluguel,
  }) async {
    final data = await _api.put(
      '/carrinho/itens/$itemId',
      data: {'quantidade': ?quantidade, 'dias_aluguel': ?diasAluguel},
    );

    return _carrinho(data);
  }

  Future<Carrinho> removerItem(String itemId) async {
    return _carrinho(await _api.delete('/carrinho/itens/$itemId'));
  }

  Future<void> limpar() => _api.delete('/carrinho');

  Carrinho _carrinho(dynamic data) {
    return Carrinho.fromJson(parseMap(data) ?? const {});
  }
}
