import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/carrinho.dart';
import '../../auth/data/sessao_provider.dart';
import '../data/carrinho_repository.dart';

/// Carrinho do consumidor logado. As alterações usam o carrinho que a API
/// devolve, já com os totais recalculados.
final carrinhoProvider =
    AsyncNotifierProvider.autoDispose<CarrinhoNotifier, Carrinho>(
      CarrinhoNotifier.new,
    );

class CarrinhoNotifier extends AsyncNotifier<Carrinho> {
  CarrinhoRepository get _repositorio => ref.read(carrinhoRepositoryProvider);

  @override
  Future<Carrinho> build() {
    // Recarrega quando alguém entra ou sai da conta.
    ref.watch(sessaoProvider.select((sessao) => sessao.value?.id));
    return ref.watch(carrinhoRepositoryProvider).obter();
  }

  /// [quantidade] de 1 a 10, [diasAluguel] de 1 a 30.
  Future<void> atualizarItem(
    String itemId, {
    int? quantidade,
    int? diasAluguel,
  }) async {
    final carrinho = await _repositorio.atualizarItem(
      itemId,
      quantidade: quantidade,
      diasAluguel: diasAluguel,
    );
    if (ref.mounted) state = AsyncData(carrinho);
  }

  /// Remover o último item apaga o carrinho na API.
  Future<void> removerItem(String itemId) async {
    final carrinho = await _repositorio.removerItem(itemId);
    if (ref.mounted) state = AsyncData(carrinho);
  }
}
