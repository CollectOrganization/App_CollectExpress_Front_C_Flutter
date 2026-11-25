import 'package:app_collect_express_with_flutter/core/models/enums.dart';
import 'package:app_collect_express_with_flutter/core/models/usuario.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/data/admin_repository.dart';
import 'package:app_collect_express_with_flutter/features/admin/domain/models/analise_cnpj.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/widgets/analise_cnpj_sheet.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

const _id = '7b0c3a52-1f7e-4c55-9d7a-2a7f2f9f0a11';

const _fornecedor = Usuario(
  id: _id,
  nomeCompleto: 'JR Caçambas',
  email: 'jr@cacambas.com',
  tipoPerfil: TipoPerfil.cacambeiro,
  status: StatusUsuario.pendente,
);

const _analiseComIa = {
  'cnpj': '**.***.333/0001-81',
  'nota': 8.5,
  'recomendacao': 'APROVAR',
  'resumo': 'Dados conferem com o perfil.',
  'checagens': [
    {
      'item': 'Situação cadastral',
      'resultado': 'ATIVA',
      'ok': true,
      'pontos': 35,
      'maximo': 35,
    },
    {
      'item': 'Atividade compatível (IA)',
      'resultado': 'Atividade principal compatível',
      'ok': true,
      'pontos': 40,
      'maximo': 40,
    },
  ],
  'atividade': {
    'classificacao': 'PRINCIPAL_COMPATIVEL',
    'cnaes_compativeis': ['3811-4/00'],
    'justificativa': 'Coleta de resíduos é o serviço de quem aluga caçambas.',
  },
  'nome': {
    'classificacao': 'CONSISTENTE',
    'justificativa': 'JR Caçambas é o nome fantasia.',
  },
  'pontos_de_atencao': ['Empresa aberta há 2 meses: ainda não tem histórico.'],
  'parecer': 'Empresa ativa, com atividade principal de coleta de resíduos.',
  'dados_receita': {
    'razao_social': 'JR LOCACAO DE CACAMBAS LTDA',
    'nome_fantasia': 'JR CACAMBAS',
    'situacao_cadastral': 'ATIVA',
    'data_inicio_atividade': '2026-09-01',
    'cnae_principal': {
      'codigo': '3811-4/00',
      'descricao': 'Coleta de resíduos não-perigosos',
    },
    'cnaes_secundarios': [],
    'municipio': 'SAO PAULO',
    'uf': 'SP',
  },
  'fonte': 'BrasilAPI',
  'ia': {'usada': true, 'modelo': 'claude-opus-5-5', 'motivo': null},
  'gerado_em': '2026-11-25T15:00:00.000Z',
};

FakeResponse _naoEncontrada() => const FakeResponse(404, {
  'success': false,
  'message': 'Este cadastro ainda não tem análise de CNPJ.',
  'code': 'ANALISE_NAO_ENCONTRADA',
});

/// Tela com um botão que abre o sheet e mostra o que ele devolveu.
Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  FakeResponse Function(RequestOptions request) handler,
) async {
  tester.view.physicalSize = const Size(390, 844);
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
      child: MaterialApp(home: const Scaffold(body: _Abridor())),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return adapter;
}

StatusUsuario? _ultimoResultado;

class _Abridor extends StatelessWidget {
  const _Abridor();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        _ultimoResultado = await showAnaliseCnpjSheet(context, _fornecedor);
      },
      child: const Text('abrir'),
    );
  }
}

void main() {
  setUp(() => _ultimoResultado = null);

  group('AdminRepository', () {
    test('análise salva: 404 da API vira null', () async {
      final adapter = FakeApiAdapter((_) => _naoEncontrada());
      final api = ApiClient(
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
        adapter: adapter,
      );

      expect(await AdminRepository(api).analiseCnpjSalva(_id), isNull);
      expect(adapter.paths, ['GET /usuarios/$_id/analise-cnpj']);
    });

    test('gerar análise: POST com espera longa e leitura do JSON', () async {
      final adapter = FakeApiAdapter(
        (_) =>
            const FakeResponse(200, {'success': true, 'data': _analiseComIa}),
      );
      final api = ApiClient(
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
        adapter: adapter,
      );

      final analise = await AdminRepository(api).gerarAnaliseCnpj(_id);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.receiveTimeout, const Duration(seconds: 90));
      expect(analise.nota, 8.5);
      expect(analise.recomendacao, RecomendacaoCnpj.aprovar);
      expect(analise.cnaesCompativeis, ['3811-4/00']);
      expect(analise.dadosReceita!.cnaePrincipal!.codigo, '3811-4/00');
      expect(analise.dadosReceita!.dataInicioAtividade, DateTime(2026, 9, 1));
      expect(analise.iaUsada, isTrue);
      expect(analise.checagens.first.ok, isTrue);
    });
  });

  testWidgets('sem análise salva, gera uma e mostra nota, parecer e ações', (
    tester,
  ) async {
    final adapter = await _abrir(tester, (request) {
      return request.method == 'GET'
          ? _naoEncontrada()
          : const FakeResponse(200, {'success': true, 'data': _analiseComIa});
    });

    expect(adapter.paths, [
      'GET /usuarios/$_id/analise-cnpj',
      'POST /usuarios/$_id/analise-cnpj',
    ]);
    expect(find.text('8,5'), findsOneWidget);
    expect(find.text('Recomendo aprovar'), findsOneWidget);
    expect(find.text('Parecer da IA'), findsOneWidget);
    expect(
      find.text(
        'Empresa ativa, com atividade principal de coleta de resíduos.',
      ),
      findsOneWidget,
    );
    expect(find.text('3811-4/00'), findsOneWidget);
    expect(find.text('40/40'), findsOneWidget);

    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();

    expect(_ultimoResultado, StatusUsuario.ativo);
  });

  testWidgets('sem IA configurada: sem nota e com o motivo na tela', (
    tester,
  ) async {
    await _abrir(tester, (_) {
      return const FakeResponse(200, {
        'success': true,
        'data': {
          'cnpj': '**.***.333/0001-81',
          'nota': null,
          'recomendacao': 'REVISAR',
          'resumo': 'Empresa ativa. Falta conferir a atividade.',
          'checagens': [],
          'parecer': 'Confira manualmente se as atividades combinam.',
          'ia': {
            'usada': false,
            'modelo': null,
            'motivo':
                'IA não configurada: defina ANTHROPIC_API_KEY no .env da API.',
          },
        },
      });
    });

    expect(find.text('–'), findsOneWidget);
    expect(find.text('Conferir antes de aprovar'), findsOneWidget);
    expect(
      find.text('IA não configurada: defina ANTHROPIC_API_KEY no .env da API.'),
      findsOneWidget,
    );
    expect(find.text('Parecer'), findsOneWidget);
  });

  testWidgets('erro da API mostra a mensagem e deixa tentar de novo', (
    tester,
  ) async {
    var chamadas = 0;
    await _abrir(tester, (request) {
      chamadas++;
      if (request.method == 'GET') return _naoEncontrada();
      return const FakeResponse(503, {
        'success': false,
        'message':
            'A consulta de CNPJ está fora do ar. Tente de novo em instantes.',
        'code': 'CNPJ_CONSULTA_INDISPONIVEL',
      });
    });

    expect(
      find.text(
        'A consulta de CNPJ está fora do ar. Tente de novo em instantes.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(chamadas, 3);
  });
}
