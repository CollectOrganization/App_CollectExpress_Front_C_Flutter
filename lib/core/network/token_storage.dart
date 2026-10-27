import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda os tokens da sessão do usuário logado.
abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  /// Sem [refreshToken] (API antiga), o refresh guardado é apagado.
  Future<void> saveTokens({required String accessToken, String? refreshToken});

  Future<void> clear();
}

/// Usa o armazenamento seguro de cada plataforma (Keychain, Keystore...).
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'collectexpress_access_token';
  static const _refreshTokenKey = 'collectexpress_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);

    if (refreshToken == null) {
      await _storage.delete(key: _refreshTokenKey);
    } else {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
