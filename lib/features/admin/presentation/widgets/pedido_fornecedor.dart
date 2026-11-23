import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/endereco.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/fornecedor_repository.dart';
import '../fornecedor_providers.dart';

/// `Av. Paulista, 1000 - Bela Vista, São Paulo/SP`, ou `-` sem endereço.
String formatEnderecoPedido(Endereco? endereco) {
  if (endereco == null) return '-';

  final bairro = endereco.bairro.isEmpty ? '' : ' - ${endereco.bairro}';
  final cidade = endereco.cidadeEstado.isEmpty
      ? ''
      : ', ${endereco.cidadeEstado}';
  return '${endereco.logradouro}, ${endereco.numero}$bairro$cidade';
}

/// Texto do botão que leva o pedido para [proximo].
String textoAvancarStatus(StatusAluguel proximo) => switch (proximo) {
  StatusAluguel.aguardandoEntrega => 'Confirmar Pedido',
  StatusAluguel.emUso => 'Confirmar Entrega da Caçamba',
  StatusAluguel.aguardandoRetirada => 'Solicitar Retirada',
  StatusAluguel.finalizado => 'Confirmar Retirada e Finalizar',
};

/// Pergunta antes de avançar o status, que não pode ser desfeito.
Future<bool> confirmarAvancoStatus(
  BuildContext context,
  StatusAluguel proximo,
) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(textoAvancarStatus(proximo)),
        content: Text(
          'O pedido passará para "${proximo.label}". '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: AppColors.green),
            ),
          ),
        ],
      );
    },
  );

  return confirmado == true;
}

/// Avança o pedido para [proximo] e recarrega o que depende dele.
/// Devolve `true` se o status mudou.
Future<bool> avancarStatusPedido(
  BuildContext context,
  WidgetRef ref,
  String aluguelId,
  StatusAluguel proximo,
) async {
  // O container sobrevive à tela, caso ela feche durante a requisição.
  final container = ProviderScope.containerOf(context, listen: false);

  void recarregar() {
    container.invalidate(pedidosRecebidosProvider);
    container.invalidate(detalhePedidoFornecedorProvider(aluguelId));
    container.invalidate(fornecedorDashboardProvider);
  }

  try {
    await ref
        .read(fornecedorRepositoryProvider)
        .atualizarStatus(aluguelId, proximo);
  } on ApiException catch (error) {
    // 409: o pedido já mudou de etapa; mostra o status atual.
    if (error.statusCode == 409) recarregar();
    if (context.mounted) showApiError(context, error);
    return false;
  }

  recarregar();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido atualizado: ${proximo.label}.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  return true;
}

class StatusAluguelBadge extends StatelessWidget {
  final StatusAluguel? status;

  const StatusAluguelBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (status) {
      StatusAluguel.aguardandoEntrega => (
        const Color(0xFF9A6D00),
        const Color(0xFFFFF9D9),
      ),
      StatusAluguel.emUso => (AppColors.green, const Color(0xFFE5F6E7)),
      StatusAluguel.aguardandoRetirada => (
        const Color(0xFF1F5FA8),
        const Color(0xFFE6EFFA),
      ),
      StatusAluguel.finalizado || null => (Colors.black54, AppColors.lightGray),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        status?.label ?? '-',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
