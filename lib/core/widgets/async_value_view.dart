import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_routes.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Mostra o carregamento, o erro ou o conteúdo de um [AsyncValue].
///
/// Erros de sessão (401) mostram um botão para entrar; os demais, um
/// botão para tentar de novo quando [onRetry] for informado.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(child: CircularProgressIndicator(color: AppColors.green)),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  bool get _semSessao =>
      error is ApiException && (error as ApiException).isUnauthorized;

  @override
  Widget build(BuildContext context) {
    final message = _semSessao
        ? 'Entre na sua conta para continuar.'
        : error is ApiException
        ? (error as ApiException).message
        : 'Algo deu errado. Tente novamente.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _semSessao ? Icons.lock_outline : Icons.cloud_off_outlined,
            size: 48,
            color: Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_semSessao)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entrar'),
            )
          else if (onRetry != null)
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green),
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    );
  }
}

/// Mostra o erro de uma ação (salvar, enviar...) num SnackBar vermelho.
void showApiError(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : 'Algo deu errado. Tente novamente.';

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
}
