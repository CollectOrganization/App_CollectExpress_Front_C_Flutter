import 'package:dio/dio.dart';

import '../api_response.dart';
import '../token_storage.dart';

/// Coloca o token JWT nas requisições e, quando a API responde 401, renova
/// a sessão com o refresh token e repete a requisição uma vez.
///
/// Por ser um [QueuedInterceptor], os erros são tratados um de cada vez:
/// vários 401 ao mesmo tempo disparam uma única renovação.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._storage,
    required this._refreshClient,
    required this._onSessionExpired,
  });

  /// Em `Options.extra`, marca requisições que não levam token
  /// (login, cadastro, recuperação de senha).
  static const skipAuth = 'skipAuth';

  static const _retried = 'authRetried';

  final TokenStorage _storage;

  /// Dio sem interceptors, usado para renovar o token e repetir a
  /// requisição sem passar de novo por esta fila.
  final Dio _refreshClient;

  final void Function() _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] != true) {
      final token = await _storage.readAccessToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final sentToken = _sentToken(options);

    if (err.response?.statusCode != 401 ||
        sentToken == null ||
        options.extra[_retried] == true) {
      return handler.next(err);
    }

    final String? newToken;
    try {
      newToken = await _renewToken(sentToken);
    } on DioException {
      // Falha de rede ao renovar: mantém a sessão e repassa o erro original.
      return handler.next(err);
    }

    if (newToken == null) {
      await _storage.clear();
      _onSessionExpired();
      return handler.next(err);
    }

    options.headers['Authorization'] = 'Bearer $newToken';
    options.extra[_retried] = true;

    try {
      handler.resolve(await _refreshClient.fetch(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  String? _sentToken(RequestOptions options) {
    final header = options.headers['Authorization']?.toString();
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }

  /// Devolve o novo access token, ou `null` se a API recusou a renovação.
  Future<String?> _renewToken(String expiredToken) async {
    // Outra requisição já renovou enquanto esta esperava na fila.
    final current = await _storage.readAccessToken();
    if (current != null && current.isNotEmpty && current != expiredToken) {
      return current;
    }

    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _refreshClient.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = unwrapData(response.data);
      final accessToken = data is Map ? data['access_token']?.toString() : null;
      if (accessToken == null || accessToken.isEmpty) return null;

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken:
            (data as Map)['refresh_token']?.toString() ?? refreshToken,
      );

      return accessToken;
    } on DioException catch (error) {
      if (error.response != null) return null;
      rethrow;
    }
  }
}
