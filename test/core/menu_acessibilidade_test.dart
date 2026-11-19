import 'package:app_collect_express_with_flutter/core/acessibilidade/acessibilidade.dart';
import 'package:app_collect_express_with_flutter/core/acessibilidade/leitura_em_voz_alta.dart';
import 'package:app_collect_express_with_flutter/core/widgets/secao_acessibilidade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _LeitorFalso implements LeitorEmVozAlta {
  final lidos = <String>[];
  var parado = false;

  @override
  Future<void> ler(String texto) async => lidos.add(texto);

  @override
  Future<void> parar() async => parado = true;
}

/// Página com o menu lateral só com a seção de acessibilidade.
Widget _app({required Widget corpo}) {
  return MaterialApp(
    builder: (context, child) => AcessibilidadeBuilder(child: child!),
    home: Scaffold(
      body: corpo,
      endDrawer: const Drawer(
        child: SingleChildScrollView(child: SecaoAcessibilidade()),
      ),
    ),
  );
}

Future<void> _abrirMenu(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
  await tester.pumpAndSettle();
}

void main() {
  group('tamanho do texto', () {
    test('vai de 80% a 200%, de 10 em 10', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(acessibilidadeProvider.notifier);

      expect(container.read(acessibilidadeProvider).escalaTexto, 1.0);
      for (var i = 0; i < 20; i++) {
        notifier.aumentarTexto();
      }
      expect(container.read(acessibilidadeProvider).escalaTexto, 2.0);
      expect(container.read(acessibilidadeProvider).podeAumentar, isFalse);
      for (var i = 0; i < 20; i++) {
        notifier.diminuirTexto();
      }
      expect(container.read(acessibilidadeProvider).escalaTexto, 0.8);
      expect(container.read(acessibilidadeProvider).podeDiminuir, isFalse);
    });

    testWidgets('o botão do menu aumenta o texto do app inteiro', (
      tester,
    ) async {
      late BuildContext contextoDaPagina;
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            corpo: Builder(
              builder: (context) {
                contextoDaPagina = context;
                return const Text('Conteúdo');
              },
            ),
          ),
        ),
      );
      expect(MediaQuery.textScalerOf(contextoDaPagina).scale(10), 10);

      await _abrirMenu(tester);
      await tester.tap(find.byTooltip('Aumentar texto'));
      await tester.tap(find.byTooltip('Aumentar texto'));
      await tester.pumpAndSettle();

      expect(find.text('120%'), findsOneWidget);
      expect(MediaQuery.textScalerOf(contextoDaPagina).scale(10), 12);
    });
  });

  testWidgets('alto contraste aplica o filtro sem reiniciar a navegação', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: _app(corpo: const Text('Conteúdo'))),
    );
    final filtro = find.byWidgetPredicate(
      (w) => w is ColorFiltered && w.colorFilter == filtroAltoContraste,
    );
    expect(filtro, findsNothing);
    final estadoAntes = tester.state<ScaffoldState>(find.byType(Scaffold));

    await _abrirMenu(tester);
    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();

    expect(filtro, findsOneWidget);
    // O mesmo Scaffold: a tela não foi recriada.
    expect(tester.state<ScaffoldState>(find.byType(Scaffold)), estadoAntes);
  });

  testWidgets('ler a tela lê o conteúdo da página, sem o menu', (tester) async {
    final leitor = _LeitorFalso();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [leitorEmVozAltaProvider.overrideWithValue(leitor)],
        child: _app(
          corpo: const Column(
            children: [
              Text('Pedido confirmado'),
              Icon(Icons.check),
              Text('Total: R\$ 450,00'),
            ],
          ),
        ),
      ),
    );

    await _abrirMenu(tester);
    await tester.tap(find.text('Ler a tela em voz alta'));
    await tester.pumpAndSettle();

    expect(leitor.lidos, ['Pedido confirmado\nTotal: R\$ 450,00']);
    // O menu fechou depois de pedir a leitura.
    expect(find.text('ACESSIBILIDADE'), findsNothing);
  });

  test('texto longo é dividido em trechos que o Android aceita', () {
    final linha = 'a' * 1000;
    final texto = List.filled(7, linha).join('\n');

    final trechos = dividirEmTrechos(texto);

    expect(trechos.every((t) => t.length <= 3000), isTrue);
    expect(trechos.join('\n'), texto);
  });
}
