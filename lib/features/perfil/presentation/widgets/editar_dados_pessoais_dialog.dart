import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/usuario.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';

/// Edita nome e telefone do usuário logado. Fecha com `true` se salvou.
///
/// A API não permite alterar e-mail nem documento.
class EditarDadosPessoaisDialog extends ConsumerStatefulWidget {
  const EditarDadosPessoaisDialog({super.key, required this.usuario});

  final Usuario usuario;

  @override
  ConsumerState<EditarDadosPessoaisDialog> createState() =>
      _EditarDadosPessoaisDialogState();
}

class _EditarDadosPessoaisDialogState
    extends ConsumerState<EditarDadosPessoaisDialog> {
  static const _camposDoFormulario = {'nome_completo', 'telefone'};

  final _formKey = GlobalKey<FormState>();

  late final _nomeController = TextEditingController(
    text: widget.usuario.nomeCompleto,
  );
  late final _telefoneController = TextEditingController(
    text: widget.usuario.telefone?.replaceAll(RegExp(r'\D'), '') ?? '',
  );

  bool _salvando = false;
  String? _erro;
  Map<String, String> _errosApi = const {};

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_salvando,
      child: AlertDialog(
        title: const Text('Editar dados pessoais'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomeController,
                  enabled: !_salvando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) =>
                      _errosApi['nome_completo'] ?? _validarNome(value),
                ),
                TextFormField(
                  controller: _telefoneController,
                  enabled: !_salvando,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: 'DDD + número',
                  ),
                  validator: (value) =>
                      _errosApi['telefone'] ?? _validarTelefone(value),
                  onFieldSubmitted: (_) => _salvar(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'O e-mail e o CPF/CNPJ não podem ser alterados.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _salvando ? null : () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _salvando ? null : _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              disabledBackgroundColor: AppColors.green.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
            ),
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  String? _validarNome(String? value) {
    final nome = value?.trim() ?? '';

    if (nome.length < 3) {
      return 'Informe seu nome completo';
    }

    if (nome.length > 120) {
      return 'O nome deve possuir no máximo 120 caracteres';
    }

    return null;
  }

  String? _validarTelefone(String? value) {
    final telefone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (telefone.length < 10 || telefone.length > 11) {
      return 'Informe DDD e número (10 ou 11 dígitos)';
    }

    return null;
  }

  Future<void> _salvar() async {
    setState(() {
      _errosApi = const {};
      _erro = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _salvando = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .atualizarPerfil(
            nomeCompleto: _nomeController.text.trim(),
            telefone: _telefoneController.text,
          );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errosApi = error.fields;
        _erro = error.fields.keys.any(_camposDoFormulario.contains)
            ? null
            : error.message;
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
