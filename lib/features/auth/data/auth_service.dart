import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final usuario = data['usuario'] as Map<String, dynamic>?;

      if (token != null) {
        await _storage.write(key: 'collectexpress_token', value: token);
      }

      if (usuario != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('collectexpress_user', jsonEncode(usuario));
      }

      return data;
    } on DioException catch (e) {
      String errorMessage = 'Ocorreu um erro ao realizar o login.';

      if (e.response != null && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map<String, dynamic>) {
          if (resData['error'] != null) {
            errorMessage = resData['error'].toString();
          } else if (resData['errors'] != null && resData['errors'] is List) {
            final errorsList = resData['errors'] as List;
            errorMessage = errorsList
                .map((err) => err is Map ? (err['mensagem'] ?? err['msg'] ?? err.toString()) : err.toString())
                .join('\n');
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.sendTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Tempo de conexão esgotado. Verifique sua internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Não foi possível conectar ao servidor. A API está rodando?';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignora erro no logout remoto se rede falhar
    } finally {
      await _storage.delete(key: 'collectexpress_token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('collectexpress_user');
    }
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('collectexpress_user');
      if (userStr != null) {
        return jsonDecode(userStr) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
