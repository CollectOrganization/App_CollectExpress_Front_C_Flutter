import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/usuario.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_providers.dart';
import 'auth_repository.dart';

/// Usuário logado, ou `null` se ninguém estiver logado.
///
/// Ao abrir o app, recupera a sessão salva consultando o perfil na API.
/// Volta para `null` sozinho quando a sessão expira.
final sessaoProvider = AsyncNotifierProvider<SessaoNotifier, Usuario?>(
  SessaoNotifier.new,
);

class SessaoNotifier extends AsyncNotifier<Usuario?> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  Future<Usuario?> build() async {
    final subscription = ref
        .watch(apiClientProvider)
        .sessionExpired
        .listen((_) => state = const AsyncData(null));
    ref.onDispose(subscription.cancel);

    if (!await _auth.temSessao()) return null;

    try {
      return await _auth.perfil();
    } on ApiException catch (error) {
      // 401: sessão expirada. 403: conta pendente ou suspensa.
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _auth.limparSessaoLocal();
        return null;
      }
      rethrow;
    }
  }

  Future<Usuario> entrar({required String email, required String senha}) async {
    final usuario = await _auth.login(email: email, senha: senha);
    state = AsyncData(usuario);
    return usuario;
  }

  Future<void> sair() async {
    await _auth.logout();
    state = const AsyncData(null);
  }
}
