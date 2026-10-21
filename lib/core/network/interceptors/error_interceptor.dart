import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Converte qualquer falha do Dio em [ApiException], com a mensagem
/// que a API enviou ou uma mensagem amigável para falhas de rede.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: ApiException.fromDioException(err)));
  }
}
