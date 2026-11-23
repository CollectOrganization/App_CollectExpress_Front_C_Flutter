import 'package:flutter/material.dart';

import '../../../../core/models/carrinho.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

/// Subtotal, taxa de entrega e total do carrinho, calculados pela API.
class ResumoValoresCard extends StatelessWidget {
  const ResumoValoresCard({super.key, required this.resumo});

  final ResumoCarrinho resumo;

  @override
  Widget build(BuildContext context) {
    final quantidade = resumo.quantidadeItens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _ValueRow(
            label: quantidade == 1
                ? 'Subtotal Caçamba (1x)'
                : 'Subtotal Caçambas (${quantidade}x)',
            value: formatMoney(resumo.subtotal),
          ),
          const SizedBox(height: 8),
          _ValueRow(
            label: 'Taxa de Entrega',
            value: resumo.taxaEntrega == 0
                ? 'Grátis'
                : formatMoney(resumo.taxaEntrega),
            valueColor: resumo.taxaEntrega == 0 ? AppColors.green : null,
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border),
          const SizedBox(height: 6),
          _ValueRow(
            label: 'Valor Total:',
            value: formatMoney(resumo.totalEstimado),
            valueColor: AppColors.green,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _ValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? Colors.black : Colors.black54,
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.black,
            fontSize: bold ? 19 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
