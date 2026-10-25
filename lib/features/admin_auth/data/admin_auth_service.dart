import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../domain/admin_session.dart';

class AdminAuthService {
  AdminAuthService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const String _tokenKey = 'admin_access_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<AdminSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/admin/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );

    final session = AdminSession.fromJson(response);

    if (session.accessToken.isEmpty) {
      throw const AdminAuthException('A API não retornou o token de acesso.');
    }

    await _storage.write(key: _tokenKey, value: session.accessToken);

    return session;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String invitationCode,
  }) async {
    await _post(
      '/auth/admin/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'invitationCode': invitationCode.trim(),
      },
    );
  }

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() {
    return _storage.delete(key: _tokenKey);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AdminAuthException(
          data['message']?.toString() ??
              'Não foi possível concluir a solicitação.',
        );
      }

      return data;
    } on TimeoutException {
      throw const AdminAuthException(
        'A solicitação demorou muito. Tente novamente.',
      );
    } on AdminAuthException {
      rethrow;
    } catch (_) {
      throw const AdminAuthException('Não foi possível conectar ao servidor.');
    }
  }
}

class AdminAuthException implements Exception {
  final String message;

  const AdminAuthException(this.message);

  @override
  String toString() => message;
}
