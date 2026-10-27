import 'dart:convert';
import 'dart:typed_data';

import 'package:app_collect_express_with_flutter/core/network/token_storage.dart';
import 'package:dio/dio.dart';

/// Resposta simulada da API.
class FakeResponse {
  final int statusCode;
  final Object? body;

  /// Atraso antes de responder, para simular requisições simultâneas.
  final Duration delay;

  /// Simula falha de rede (a requisição não chega à API).
  final bool networkError;

  const FakeResponse(
    this.statusCode,
    this.body, {
    this.delay = Duration.zero,
    this.networkError = false,
  });

  const FakeResponse.networkError()
    : statusCode = 0,
      body = null,
      delay = Duration.zero,
      networkError = true;
}

/// Adapter do Dio que responde a partir de um [handler], sem rede,
/// e guarda as requisições recebidas.
class FakeApiAdapter implements HttpClientAdapter {
  FakeApiAdapter(this.handler);

  final FakeResponse Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  List<String> get paths =>
      requests.map((r) => '${r.method} ${r.path}').toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = handler(options);

    if (response.delay > Duration.zero) {
      await Future<void>.delayed(response.delay);
    }

    if (response.networkError) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'fake network error',
      );
    }

    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

/// Lê o body JSON enviado numa requisição capturada.
Map<String, dynamic> sentBody(RequestOptions request) {
  final data = request.data;
  if (data is Map<String, dynamic>) return data;
  return jsonDecode(data as String) as Map<String, dynamic>;
}

String? bearer(RequestOptions request) {
  return request.headers['Authorization']?.toString();
}
