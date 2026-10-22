import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/endereco.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/cep_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../perfil/data/enderecos_repository.dart';

/// Abre o formulário de novo endereço e devolve o endereço salvo na API,
/// ou `null` se o usuário desistir.
Future<Endereco?> mostrarNovoEnderecoSheet(BuildContext context) {
  return showModalBottomSheet<Endereco>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => const _NovoEnderecoSheet(),
  );
}

class _NovoEnderecoSheet extends ConsumerStatefulWidget {
  const _NovoEnderecoSheet();

  @override
  ConsumerState<_NovoEnderecoSheet> createState() => _NovoEnderecoSheetState();
}

class _NovoEnderecoSheetState extends ConsumerState<_NovoEnderecoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cepService = CepService();

  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  bool _buscandoCep = false;
  bool _salvando = false;
  String? _ultimoCepBuscado;
  String? _erroCep;

  /// Erro da API ao salvar. Fica no formulário porque um SnackBar
  /// apareceria atrás da folha.
  String? _erro;

  @override
  void dispose() {
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Novo endereço',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  onChanged: _cepAlterado,
                  decoration: _decoracao(
                    label: 'CEP',
                    hint: 'Somente números',
                    errorText: _erroCep,
                    suffixIcon: _buscandoCep
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.green,
                              ),
                            ),
                          )
                        : null,
                  ),
                  validator: (value) => (value ?? '').length == 8
                      ? null
                      : 'Informe um CEP com 8 dígitos',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _logradouroController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoracao(label: 'Logradouro'),
                  validator: _obrigatorio('Informe o logradouro'),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _numeroController,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracao(label: 'Número'),
                        validator: _obrigatorio('Informe o número'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _bairroController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoracao(label: 'Bairro'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _cidadeController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoracao(label: 'Cidade'),
                        validator: _obrigatorio('Informe a cidade'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ufController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                          LengthLimitingTextInputFormatter(2),
                        ],
                        onFieldSubmitted: (_) => _salvar(),
                        decoration: _decoracao(label: 'UF'),
                        validator: (value) => (value ?? '').trim().length == 2
                            ? null
                            : 'Inválida',
                      ),
                    ),
                  ],
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _erro!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      disabledBackgroundColor: AppColors.green.withValues(
                        alpha: 0.55,
                      ),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Salvar endereço',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracao({
    required String label,
    String? hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      errorText: errorText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  FormFieldValidator<String> _obrigatorio(String mensagem) {
    return (value) => (value ?? '').trim().isEmpty ? mensagem : null;
  }

  void _cepAlterado(String valor) {
    if (_erroCep != null) setState(() => _erroCep = null);
    _buscarCep(valor);
  }

  Future<void> _buscarCep(String cep) async {
    if (cep.length != 8 || cep == _ultimoCepBuscado || _buscandoCep) return;

    _ultimoCepBuscado = cep;
    setState(() => _buscandoCep = true);

    try {
      final endereco = await _cepService.findAddress(cep);

      // O usuário pode ter mudado o CEP durante a consulta.
      if (!mounted || _cepController.text != cep) return;

      _logradouroController.text = endereco.street;
      _bairroController.text = endereco.neighborhood;
      _cidadeController.text = endereco.city;
      _ufController.text = endereco.state;
    } on CepException catch (error) {
      _ultimoCepBuscado = null;
      if (mounted) setState(() => _erroCep = error.message);
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final cidade = _cidadeController.text.trim();
      final uf = _ufController.text.trim().toUpperCase();

      final endereco = await ref
          .read(enderecosRepositoryProvider)
          .criar(
            Endereco(
              cep: _cepController.text,
              logradouro: _logradouroController.text.trim(),
              numero: _numeroController.text.trim(),
              bairro: _bairroController.text.trim(),
              cidadeEstado: '$cidade/$uf',
            ),
          );

      if (mounted) Navigator.of(context).pop(endereco);
    } on ApiException catch (error) {
      if (mounted) setState(() => _erro = error.message);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
