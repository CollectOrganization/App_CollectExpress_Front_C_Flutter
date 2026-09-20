import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout || 
        err.type == DioExceptionType.receiveTimeout) {
      // Implementar lógica de evento para timeout (ex: avisar UI)
    }

    if (err.response?.statusCode == 401) {
      // Implementar lógica para deslogar usuário (limpar token e redirecionar)
      // Idealmente através de um stream de eventos de autenticação
    }

    super.onError(err, handler);
  }
}
