import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/endereco.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final enderecosRepositoryProvider = Provider<EnderecosRepository>((ref) {
  return EnderecosRepository(ref.watch(apiClientProvider));
});

/// Endereços do usuário logado (no máximo 10).
class EnderecosRepository {
  EnderecosRepository(this._api);

  final ApiClient _api;

  Future<List<Endereco>> listar() async {
    return parseList(await _api.get('/enderecos'), Endereco.fromJson);
  }

  Future<Endereco> criar(Endereco endereco) async {
    final data = await _api.post('/enderecos', data: endereco.toJson());
    return Endereco.fromJson(parseMap(data) ?? const {});
  }

  /// Substitui o endereço inteiro. Falha se houver pedido em andamento nele.
  Future<Endereco> atualizar(Endereco endereco) async {
    final data = await _api.put(
      '/enderecos/${endereco.id}',
      data: endereco.toJson(),
    );
    return Endereco.fromJson(parseMap(data) ?? const {});
  }

  /// Falha se o endereço já foi usado em algum pedido.
  Future<void> remover(String id) => _api.delete('/enderecos/$id');
}
