import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:3000/api';

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}
