import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/endereco.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/cep_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/enderecos_repository.dart';

/// Cadastra um endereço novo ou edita [endereco]. Fecha com `true` se salvou.
class EnderecoFormDialog extends ConsumerStatefulWidget {
  const EnderecoFormDialog({super.key, this.endereco});

  final Endereco? endereco;

  @override
  ConsumerState<EnderecoFormDialog> createState() => _EnderecoFormDialogState();
}

class _EnderecoFormDialogState extends ConsumerState<EnderecoFormDialog> {
  static const _camposDoFormulario = {
    'cep',
    'logradouro',
    'numero',
    'bairro',
    'cidade_estado',
  };

  final _formKey = GlobalKey<FormState>();
  final _cepService = CepService();

  late final TextEditingController _cepController;
  late final TextEditingController _logradouroController;
  late final TextEditingController _numeroController;
  late final TextEditingController _bairroController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _ufController;

  bool _salvando = false;
  bool _buscandoCep = false;
  String? _ultimoCepBuscado;
  String? _erroCep;
  String? _erro;
  Map<String, String> _errosApi = const {};

  bool get _editando => widget.endereco != null;

  @override
  void initState() {
    super.initState();

    final endereco = widget.endereco;
    final cep = _digitos(endereco?.cep ?? '');

    // `cidade_estado` vem como "Cidade/UF".
    final cidadeEstado = endereco?.cidadeEstado ?? '';
    final barra = cidadeEstado.lastIndexOf('/');

    _cepController = TextEditingController(text: cep);
    _logradouroController = TextEditingController(text: endereco?.logradouro);
    _numeroController = TextEditingController(text: endereco?.numero);
    _bairroController = TextEditingController(text: endereco?.bairro);
    _cidadeController = TextEditingController(
      text: barra < 0 ? cidadeEstado : cidadeEstado.substring(0, barra),
    );
    _ufController = TextEditingController(
      text: barra < 0 ? '' : cidadeEstado.substring(barra + 1),
    );
    _ultimoCepBuscado = cep.isEmpty ? null : cep;
  }

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
    return PopScope(
      canPop: !_salvando,
      child: AlertDialog(
        title: Text(_editando ? 'Editar endereço' : 'Novo endereço'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _cepController,
                  enabled: !_salvando,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CEP',
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
                        : IconButton(
                            tooltip: 'Consultar CEP',
                            onPressed: () =>
                                _buscarCep(_cepController.text, force: true),
                            icon: const Icon(Icons.search),
                          ),
                  ),
                  onChanged: _buscarCep,
                  validator: (value) {
                    if (_errosApi['cep'] case final erro?) return erro;
                    return _digitos(value ?? '').length == 8
                        ? null
                        : 'Informe um CEP com 8 dígitos';
                  },
                ),
                TextFormField(
                  controller: _logradouroController,
                  enabled: !_salvando,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    hintText: 'Rua, Avenida, Logradouro',
                  ),
                  validator: (value) {
                    if (_errosApi['logradouro'] case final erro?) return erro;
                    final logradouro = value?.trim() ?? '';
                    if (logradouro.isEmpty) return 'Informe o endereço';
                    if (logradouro.length > 200) {
                      return 'Use no máximo 200 caracteres';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _numeroController,
                  enabled: !_salvando,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Número'),
                  validator: (value) {
                    if (_errosApi['numero'] case final erro?) return erro;
                    return (value?.trim() ?? '').isEmpty
                        ? 'Informe o número'
                        : null;
                  },
                ),
                TextFormField(
                  controller: _bairroController,
                  enabled: !_salvando,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Bairro (opcional)',
                  ),
                  validator: (_) => _errosApi['bairro'],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cidadeController,
                        enabled: !_salvando,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                        validator: (value) {
                          if (_errosApi['cidade_estado'] case final erro?) {
                            return erro;
                          }
                          final cidade = value?.trim() ?? '';
                          if (cidade.isEmpty) return 'Informe a cidade';
                          if (cidade.length > 97) {
                            return 'Use no máximo 97 caracteres';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 64,
                      child: TextFormField(
                        controller: _ufController,
                        enabled: !_salvando,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(labelText: 'UF'),
                        validator: (value) => (value?.trim() ?? '').length == 2
                            ? null
                            : 'Inválida',
                        onFieldSubmitted: (_) => _salvar(),
                      ),
                    ),
                  ],
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
            onPressed: _salvando || _buscandoCep ? null : _salvar,
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

  static String _digitos(String value) => value.replaceAll(RegExp(r'\D'), '');

  Future<void> _buscarCep(String value, {bool force = false}) async {
    final cep = _digitos(value);

    if (_erroCep != null) setState(() => _erroCep = null);

    if (cep.length != 8) {
      _ultimoCepBuscado = null;
      return;
    }

    if (_buscandoCep || (!force && cep == _ultimoCepBuscado)) {
      return;
    }

    _ultimoCepBuscado = cep;
    setState(() => _buscandoCep = true);

    try {
      final endereco = await _cepService.findAddress(cep);

      // O usuário pode ter mudado o CEP durante a consulta.
      if (!mounted || _digitos(_cepController.text) != cep) return;

      _logradouroController.text = endereco.street;
      _bairroController.text = endereco.neighborhood;
      _cidadeController.text = endereco.city;
      _ufController.text = endereco.state;
    } on CepException catch (error) {
      if (!mounted) return;
      _ultimoCepBuscado = null;
      setState(() => _erroCep = error.message);
    } catch (_) {
      if (!mounted) return;
      _ultimoCepBuscado = null;
      setState(() => _erroCep = 'Não foi possível consultar o CEP.');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
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

    final endereco = Endereco(
      id: widget.endereco?.id ?? '',
      cep: _digitos(_cepController.text),
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidadeEstado:
          '${_cidadeController.text.trim()}/'
          '${_ufController.text.trim().toUpperCase()}',
    );
    final repositorio = ref.read(enderecosRepositoryProvider);

    try {
      if (_editando) {
        await repositorio.atualizar(endereco);
      } else {
        await repositorio.criar(endereco);
      }

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
