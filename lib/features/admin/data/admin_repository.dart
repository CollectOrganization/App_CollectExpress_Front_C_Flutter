import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/aluguel.dart';
import '../../../core/models/categoria.dart';
import '../../../core/models/endereco.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/models/pagina.dart';
import '../../../core/models/usuario.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../domain/models/admin_dashboard.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

/// Área do administrador geral (ADMIN).
class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  /// [semanal] agrupa o gráfico dos últimos 30 dias por semana.
  Future<AdminDashboard> dashboard({bool semanal = false}) async {
    final data = await _api.get(
      '/admin/dashboard',
      query: {'granularity': semanal ? 'weekly' : 'daily'},
    );

    return AdminDashboard.fromJson(parseMap(data) ?? const {});
  }

  /// [busca] procura no nome e no e-mail (mínimo 3 letras).
  Future<Pagina<Usuario>> listarUsuarios({
    int pagina = 1,
    TipoPerfil? tipoPerfil,
    StatusUsuario? status,
    String? busca,
  }) async {
    final data = await _api.get(
      '/usuarios',
      query: {
        'page': pagina,
        if (tipoPerfil != null) 'tipo_perfil': tipoPerfil.apiValue,
        if (status != null) 'status': status.apiValue,
        if (busca != null && busca.trim().length >= 3) 'search': busca.trim(),
      },
    );

    return Pagina.fromJson(data, Usuario.fromJson);
  }

  /// [status] ATIVO aprova um PENDENTE ou reativa um SUSPENSO; SUSPENSO
  /// recusa um PENDENTE ou bloqueia um ATIVO. A API não deixa mudar o
  /// status de administradores nem o da própria conta.
  Future<Usuario> alterarStatusUsuario(String id, StatusUsuario status) async {
    assert(status != StatusUsuario.pendente);

    final data = await _api.patch(
      '/usuarios/$id/status',
      data: {'status': status.apiValue},
    );

    return Usuario.fromJson(parseMap(data) ?? const {});
  }

  Future<({Usuario usuario, List<Endereco> enderecos, List<Aluguel> pedidos})>
  detalheUsuario(String id) async {
    final json = parseMap(await _api.get('/usuarios/$id')) ?? const {};

    return (
      usuario: Usuario.fromJson(json),
      enderecos: parseList(json['enderecos'], Endereco.fromJson),
      pedidos: parseList(json['pedidos'], Aluguel.fromJson),
    );
  }

  /// Cria outro administrador. A senha precisa ter 8+ caracteres, com
  /// maiúscula, minúscula e número.
  Future<Usuario> criarAdmin({
    required String nomeCompleto,
    required String email,
    required String senha,
    required String documento,
    required String telefone,
  }) async {
    final data = await _api.post(
      '/usuarios/admin',
      data: {
        'nome_completo': nomeCompleto.trim(),
        'email': email.trim().toLowerCase(),
        'senha': senha,
        'documento': documento.replaceAll(RegExp(r'\D'), ''),
        'telefone': telefone.replaceAll(RegExp(r'\D'), ''),
      },
    );

    return Usuario.fromJson(parseMap(data) ?? const {});
  }

  /// Todos os pedidos da plataforma. [busca] aceita o id do pedido ou o
  /// nome do cliente/fornecedor.
  Future<Pagina<Aluguel>> listarPedidos({
    int pagina = 1,
    StatusAluguel? statusAluguel,
    StatusPagamento? statusPagamento,
    String? busca,
  }) async {
    final data = await _api.get(
      '/alugueis',
      query: {
        'page': pagina,
        if (statusAluguel != null) 'status_aluguel': statusAluguel.apiValue,
        if (statusPagamento != null)
          'status_pagamento': statusPagamento.apiValue,
        if (busca != null && busca.trim().isNotEmpty) 'search': busca.trim(),
      },
    );

    return Pagina.fromJson(data, Aluguel.fromJson);
  }

  /// Hoje é o único jeito de listar categorias: a API não tem rota pública.
  Future<List<Categoria>> listarCategorias() async {
    return parseList(await _api.get('/admin/categorias'), Categoria.fromJson);
  }

  Future<Categoria> criarCategoria(String nome) async {
    final data = await _api.post(
      '/admin/categorias',
      data: {'nome': nome.trim()},
    );
    return Categoria.fromJson(parseMap(data) ?? const {});
  }

  /// O novo nome também é aplicado às caçambas dessa categoria.
  Future<Categoria> renomearCategoria(String id, String nome) async {
    final data = await _api.put(
      '/admin/categorias/$id',
      data: {'nome': nome.trim()},
    );
    return Categoria.fromJson(parseMap(data) ?? const {});
  }

  /// Falha se alguma caçamba usa a categoria.
  Future<void> removerCategoria(String id) =>
      _api.delete('/admin/categorias/$id');
}
