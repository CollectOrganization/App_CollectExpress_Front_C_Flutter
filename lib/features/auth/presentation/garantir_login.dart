import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_routes.dart';
import '../data/sessao_provider.dart';

/// Use antes de uma ação que exige conta (ex.: adicionar ao carrinho).
///
/// Se ninguém estiver logado, abre o login. Devolve `true` se, no fim,
/// houver um usuário logado e a ação puder continuar.
Future<bool> garantirLogin(BuildContext context, WidgetRef ref) async {
  try {
    if (await ref.read(sessaoProvider.future) != null) return true;
  } catch (_) {
    // Sem conseguir checar a sessão, trata como deslogado.
  }

  if (!context.mounted) return false;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Entre na sua conta para continuar.')),
  );
  await Navigator.of(context).pushNamed(AppRoutes.login);

  return ref.read(sessaoProvider).value != null;
}
