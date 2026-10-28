import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/admin_geral_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/painel_admin_page.dart';
import 'package:app_collect_express_with_flutter/features/admin_auth/presentation/pages/admin_login_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:app_collect_express_with_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _usuario(String tipoPerfil) => {
  'id': 'u1',
  'nome_completo': 'Usuário Teste',
  'email': 'teste@email.com',
  'tipo_perfil': tipoPerfil,
  'status': 'ATIVO',
};

/// Abre o app de verdade (com a tabela de rotas do main.dart), vai para
/// [rotaLogin], entra com um usuário [tipoPerfil] e devolve depois do login.
Future<void> _entrar(
  WidgetTester tester, {
  required String rotaLogin,
  required Type tela,
  required String botao,
  required String tipoPerfil,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage();
  final adapter = FakeApiAdapter((request) {
    if (request.path == '/auth/login') {
      return FakeResponse(200, {
        'success': true,
        'data': {
          'access_token': 'token',
          'refresh_token': 'refresh',
          'usuario': _usuario(tipoPerfil),
        },
      });
    }
    if (request.path == '/usuarios/perfil') {
      return FakeResponse(200, {'success': true, 'data': _usuario(tipoPerfil)});
    }
    return const FakeResponse(404, {
      'success': false,
      'error': 'não encontrado',
    });
  });

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(storage: tokens, adapter: adapter),
        ),
      ],
      child: const CollectApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));

  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .pushNamed(rotaLogin);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  // A página inicial continua na pilha; procura só dentro da tela de login.
  Finder naTela(Finder f) =>
      find.descendant(of: find.byType(tela), matching: f);
  await tester.enterText(
    naTela(find.byType(TextFormField)).at(0),
    'teste@email.com',
  );
  await tester.enterText(naTela(find.byType(TextFormField)).at(1), '123456');
  await tester.tap(naTela(find.text(botao)));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('login comum com ADMIN abre o painel do administrador', (
    tester,
  ) async {
    await _entrar(
      tester,
      rotaLogin: AppRoutes.login,
      tela: LoginPage,
      botao: 'ENTRAR',
      tipoPerfil: 'ADMIN',
    );

    expect(find.byType(AdminGeralPage), findsOneWidget);
    expect(find.byType(PainelAdminPage), findsNothing);
  });

  testWidgets(
    'login do administrador com ADMIN abre o painel do administrador',
    (tester) async {
      await _entrar(
        tester,
        rotaLogin: AppRoutes.adminLogin,
        tela: AdminLoginPage,
        botao: 'ENTRAR NO PAINEL',
        tipoPerfil: 'ADMIN',
      );

      expect(find.byType(AdminGeralPage), findsOneWidget);
      expect(find.byType(PainelAdminPage), findsNothing);
    },
  );

  testWidgets('login comum com CACAMBEIRO abre o painel do fornecedor', (
    tester,
  ) async {
    await _entrar(
      tester,
      rotaLogin: AppRoutes.login,
      tela: LoginPage,
      botao: 'ENTRAR',
      tipoPerfil: 'CACAMBEIRO',
    );

    expect(find.byType(PainelAdminPage), findsOneWidget);
    expect(find.byType(AdminGeralPage), findsNothing);
  });
}
