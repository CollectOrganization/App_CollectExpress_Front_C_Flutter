import 'package:app_collect_express_with_flutter/core/models/enums.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/features/admin/data/admin_repository.dart';
import 'package:app_collect_express_with_flutter/features/admin/data/fornecedor_repository.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/data/catalogo_repository.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/data/carrinho_repository.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/data/pedidos_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

/// Responde sempre o mesmo `data` e guarda as requisições.
({ApiClient api, FakeApiAdapter adapter}) apiRespondendo(Object? data) {
  final adapter = FakeApiAdapter(
    (_) => FakeResponse(200, {'success': true, 'data': data}),
  );
  final api = ApiClient(
    storage: InMemoryTokenStorage(accessToken: 'jwt'),
    adapter: adapter,
  );
  return (api: api, adapter: adapter);
}

RequestOptions unica(FakeApiAdapter adapter) => adapter.requests.single;

void main() {
  test('catálogo público: filtros na query, sem token, página nova', () async {
    final fake = apiRespondendo({
      'items': [
        {'id': 'c1', 'nome': 'Caçamba 5m³', 'preco_diaria': 120},
      ],
      'pagination': {'total': 1, 'page': 2, 'per_page': 20, 'total_pages': 2},
    });

    final pagina = await CatalogoRepository(fake.api)
        .listarCacambas(pagina: 2, tipoResiduo: 'Madeira', busca: 'ca');

    final request = unica(fake.adapter);
    expect(request.path, '/cacambas');
    // A busca com menos de 3 letras é ignorada (a API recusaria).
    expect(request.queryParameters, {'page': 2, 'tipo_residuo': 'Madeira'});
    expect(bearer(request), isNull);
    expect(pagina.itens.single.precoDiaria, 120);
    expect(pagina.pagina, 2);
  });

  test('carrinho: adicionar manda o item e devolve o carrinho', () async {
    final fake = apiRespondendo({
      'id': 'k1',
      'itens': [
        {'id': 'i1', 'cacamba_id': 'c1', 'quantidade': 1, 'dias_aluguel': 5},
      ],
      'resumo': {'quantidade_itens': 1, 'total_estimado': 640},
    });

    final carrinho = await CarrinhoRepository(fake.api)
        .adicionar(cacambaId: 'c1', diasAluguel: 5);

    final request = unica(fake.adapter);
    expect('${request.method} ${request.path}', 'POST /carrinho/itens');
    expect(bearer(request), 'Bearer jwt');
    expect(sentBody(request), {
      'cacamba_id': 'c1',
      'quantidade': 1,
      'dias_aluguel': 5,
    });
    expect(carrinho.resumo.totalEstimado, 640);
  });

  test('checkout manda a data como YYYY-MM-DD', () async {
    final fake = apiRespondendo({
      'id': 'p1',
      'preco_final': '640.00',
      'status_aluguel': 'AGUARDANDO_ENTREGA',
    });

    final pedido = await PedidosRepository(fake.api)
        .checkout(enderecoId: 'e1', dataInicio: DateTime(2026, 11, 3, 14, 30));

    expect(sentBody(unica(fake.adapter)), {
      'endereco_id': 'e1',
      'data_inicio': '2026-11-03',
    });
    expect(pedido.precoFinal, 640);
    expect(pedido.statusAluguel, StatusAluguel.aguardandoEntrega);
  });

  group('fornecedor', () {
    test('atualizar caçamba envia só os campos informados', () async {
      final fake = apiRespondendo({'id': 'c1', 'nome': 'Nova'});

      await FornecedorRepository(fake.api)
          .atualizarCacamba('c1', precoDiaria: 99.9, removerFoto: true);

      expect(sentBody(unica(fake.adapter)), {
        'preco_diaria': 99.9,
        'foto_url': null,
      });
    });

    test('remover caçamba diz se apagou ou só desativou', () async {
      final apagou = apiRespondendo({'id': 'c1', 'removed': true});
      final desativou = apiRespondendo({'id': 'c1', 'disponivel': false});

      expect(
        await FornecedorRepository(apagou.api).removerCacamba('c1'),
        isTrue,
      );
      expect(
        await FornecedorRepository(desativou.api).removerCacamba('c1'),
        isFalse,
      );
    });

    test('avançar status do pedido', () async {
      final fake = apiRespondendo({'id': 'p1', 'status_aluguel': 'EM_USO'});

      final pedido = await FornecedorRepository(fake.api)
          .atualizarStatus('p1', StatusAluguel.emUso);

      final request = unica(fake.adapter);
      expect('${request.method} ${request.path}', 'PATCH /alugueis/p1/status');
      expect(sentBody(request), {'status_aluguel': 'EM_USO'});
      expect(pedido.statusAluguel, StatusAluguel.emUso);
    });
  });

  test('admin: dashboard semanal e filtro de usuários', () async {
    final fake = apiRespondendo({
      'total_usuarios': 10,
      'total_pedidos': 4,
      'receita_total': 1000,
      'lucro_plataforma': 50,
      'cacambeiros_ativos': 2,
      'pedidos_por_status': {'EM_USO': 1, 'FINALIZADO': 3},
      'pedidos_ao_longo_do_tempo': [
        {'date': '2026-10-19', 'count': 4},
      ],
    });
    final repository = AdminRepository(fake.api);

    final dashboard = await repository.dashboard(semanal: true);

    expect(unica(fake.adapter).queryParameters, {'granularity': 'weekly'});
    expect(dashboard.pedidosPorStatus[StatusAluguel.finalizado], 3);
    expect(dashboard.pedidosAoLongoDoTempo.single.data, DateTime(2026, 10, 19));

    final usuarios = apiRespondendo({
      'items': [],
      'pagination': {'total': 0, 'page': 1, 'per_page': 20, 'total_pages': 0},
    });
    await AdminRepository(usuarios.api)
        .listarUsuarios(tipoPerfil: TipoPerfil.cacambeiro, busca: 'joão');

    expect(unica(usuarios.adapter).queryParameters, {
      'page': 1,
      'tipo_perfil': 'CACAMBEIRO',
      'search': 'joão',
    });
  });
}
