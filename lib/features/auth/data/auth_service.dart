import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'collectexpress_token';
  static const _refreshTokenKey = 'collectexpress_refresh_token';
  static const _userKey = 'collectexpress_user';

  static final ValueNotifier<Map<String, dynamic>?> currentUserNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        currentUserNotifier.value = jsonDecode(userStr) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuário em cache: $e');
    }
  }

  /// A API retorna `{ success, data: { access_token, refresh_token, usuario } }`.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'senha': password,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as Map<String, dynamic>;

      final accessToken = (data['access_token'] ?? data['token']) as String?;
      final refreshToken = data['refresh_token'] as String?;
      final usuario = data['usuario'] as Map<String, dynamic>?;

      if (accessToken != null) {
        try {
          await _storage.write(key: _accessTokenKey, value: accessToken);
        } catch (e) {
          debugPrint('Storage write token aviso: $e');
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, accessToken);
      }

      if (refreshToken != null) {
        try {
          await _storage.write(key: _refreshTokenKey, value: refreshToken);
        } catch (e) {
          debugPrint('Storage write refresh aviso: $e');
        }
      }

      if (usuario != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(usuario));
        currentUserNotifier.value = usuario;
      }

      return data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  String _extractErrorMessage(DioException e) {
    final resData = e.response?.data;

    if (resData is Map<String, dynamic>) {
      final errors = resData['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors
            .map((err) => err is Map
                ? (err['mensagem'] ?? err['message'] ?? err['msg'] ?? err.toString())
                : err.toString())
            .join('\n');
      }
      if (resData['message'] != null) return resData['message'].toString();
      if (resData['error'] != null) return resData['error'].toString();
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo de conexão esgotado. Verifique sua internet.';
      case DioExceptionType.connectionError:
        return 'Não foi possível conectar ao servidor. A API está rodando?';
      default:
        return 'Ocorreu um erro ao realizar o login.';
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      await _dio.post(
        '/auth/logout',
        data: {if (refreshToken != null) 'refresh_token': refreshToken},
      );
    } catch (_) {
      // Ignora erro no logout remoto se rede falhar
    } finally {
      try {
        await _storage.delete(key: _accessTokenKey);
      } catch (_) {}
      try {
        await _storage.delete(key: _refreshTokenKey);
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_userKey);
      currentUserNotifier.value = null;
    }
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        return jsonDecode(userStr) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
