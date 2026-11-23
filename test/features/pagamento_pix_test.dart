import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/data/pedidos_repository.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/pages/acompanhar_pedido_page.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/pages/pagamento_pix_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

// PNG 1x1, só para o QR Code ter uma imagem válida.
const _png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0l'
    'EQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

Map<String, dynamic> _pix({
  String status = 'PENDING',
  String statusPagamento = 'PENDENTE',
  bool devMode = true,
}) => {
  'success': true,
  'data': {
    'id': 'pix-1',
    'aluguel_id': 'a1',
    'status': status,
    'status_pagamento': statusPagamento,
    'valor': 450.5,
    'copia_cola': '00020101021226PIXCOPIAECOLA',
    'qr_code_base64': _png,
    'dev_mode': devMode,
    'expira_em': '2026-10-27T18:00:00.000Z',
    'pago_em': null,
  },
};

Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  Widget tela,
  FakeResponse Function(RequestOptions request) handler,
) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage(accessToken: 'jwt');
  final adapter = FakeApiAdapter(handler);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(storage: tokens, adapter: adapter),
        ),
      ],
      child: MaterialApp(home: tela),
    ),
  );
  await _esperar(tester);
  return adapter;
}

const _intervalo = Duration(milliseconds: 100);

/// Avança o tempo sem `pumpAndSettle`: o indicador de "aguardando o
/// pagamento" fica animando e nunca assentaria.
Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

const _tela = PagamentoPixPage(aluguelId: 'a1', intervaloConsulta: _intervalo);

void main() {
  test('repositório lê o PIX e decodifica o QR Code', () async {
    final adapter = FakeApiAdapter((_) => FakeResponse(201, _pix()));
    final tokens = InMemoryTokenStorage(accessToken: 'jwt');
    final repo = PedidosRepository(
      ApiClient(storage: tokens, adapter: adapter),
    );

    final pix = await repo.gerarPix('a1');

    expect(adapter.paths, ['POST /alugueis/a1/pix']);
    expect(pix.valor, 450.5);
    expect(pix.copiaECola, '00020101021226PIXCOPIAECOLA');
    expect(pix.aguardando, isTrue);
    expect(pix.devMode, isTrue);
    expect(pix.qrCodeBytes, isNotNull);
    expect(pix.qrCodeBytes!.take(4), [0x89, 0x50, 0x4E, 0x47]); // PNG
  });

  testWidgets('mostra o PIX e confirma sozinha quando o pagamento chega', (
    tester,
  ) async {
    var consultas = 0;
    final adapter = await _abrir(tester, _tela, (request) {
      if (request.method == 'POST') return FakeResponse(201, _pix());
      consultas++;
      // Na segunda consulta o banco já confirmou o pagamento.
      return FakeResponse(
        200,
        consultas < 2 ? _pix() : _pix(status: 'PAID', statusPagamento: 'PAGO'),
      );
    });

    expect(find.text('R\$ 450,50'), findsOneWidget);
    expect(find.text('00020101021226PIXCOPIAECOLA'), findsOneWidget);
    expect(find.text('Copiar código Pix'), findsOneWidget);
    expect(find.text('Aguardando o pagamento...'), findsOneWidget);
    expect(find.text('Simular pagamento'), findsOneWidget);

    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.tap(find.text('Copiar código Pix'));
    await _esperar(tester);
    expect(copiado, '00020101021226PIXCOPIAECOLA');
    expect(find.text('Código PIX copiado.'), findsOneWidget);

    await tester.pump(_intervalo);
    await _esperar(tester);
    await tester.pump(_intervalo);
    await _esperar(tester);

    expect(find.text('Pagamento confirmado!'), findsOneWidget);
    expect(adapter.paths, [
      'POST /alugueis/a1/pix',
      'GET /alugueis/a1/pix',
      'GET /alugueis/a1/pix',
    ]);

    // Depois de pago, para de consultar.
    await tester.pump(_intervalo * 3);
    expect(adapter.paths.length, 3);
  });

  testWidgets('simula o pagamento no modo de teste', (tester) async {
    final adapter = await _abrir(tester, _tela, (request) {
      if (request.path == '/alugueis/a1/pix/simular') {
        return FakeResponse(200, _pix(status: 'PAID', statusPagamento: 'PAGO'));
      }
      if (request.method == 'POST') return FakeResponse(201, _pix());
      return FakeResponse(200, _pix());
    });

    await tester.tap(find.text('Simular pagamento'));
    await _esperar(tester);

    expect(adapter.paths, contains('POST /alugueis/a1/pix/simular'));
    expect(find.text('Pagamento confirmado!'), findsOneWidget);
  });

  testWidgets('sem o modo de teste, não oferece simular', (tester) async {
    await _abrir(tester, _tela, (request) {
      return FakeResponse(
        request.method == 'POST' ? 201 : 200,
        _pix(devMode: false),
      );
    });

    expect(find.text('Copiar código Pix'), findsOneWidget);
    expect(find.text('Simular pagamento'), findsNothing);
  });

  testWidgets('PIX expirado permite gerar outro', (tester) async {
    var geracoes = 0;
    final adapter = await _abrir(tester, _tela, (request) {
      geracoes++;
      return FakeResponse(
        201,
        geracoes == 1 ? _pix(status: 'EXPIRED') : _pix(),
      );
    });

    expect(find.text('Este PIX expirou.'), findsOneWidget);

    await tester.tap(find.text('Gerar novo PIX'));
    await _esperar(tester);

    expect(adapter.paths.where((path) => path.startsWith('POST')), [
      'POST /alugueis/a1/pix',
      'POST /alugueis/a1/pix',
    ]);
    expect(find.text('Copiar código Pix'), findsOneWidget);
  });

  testWidgets('pedido já pago mostra a confirmação', (tester) async {
    await _abrir(tester, _tela, (_) {
      return const FakeResponse(409, {
        'success': false,
        'message': 'Este pedido já está pago.',
        'code': 'ORDER_ALREADY_PAID',
      });
    });

    expect(find.text('Pagamento confirmado!'), findsOneWidget);
  });

  testWidgets('acompanhar pedido oferece pagar só enquanto está pendente', (
    tester,
  ) async {
    var pago = false;
    await _abrir(tester, const AcompanharPedidoPage(aluguelId: 'a1'), (_) {
      return FakeResponse(200, {
        'success': true,
        'data': {
          'id': 'a1',
          'data_pedido': '2026-10-20T10:00:00.000Z',
          'data_inicio': '2026-10-28',
          'dias_aluguel': 3,
          'preco_final': 450.5,
          'status_pagamento': pago ? 'PAGO' : 'PENDENTE',
          'status_aluguel': 'AGUARDANDO_ENTREGA',
        },
      });
    });

    expect(find.text('Pagamento pendente'), findsOneWidget);
    expect(find.text('Pagar com Pix'), findsOneWidget);

    pago = true;
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();

    expect(find.text('Pagar com Pix'), findsNothing);
  });
}
