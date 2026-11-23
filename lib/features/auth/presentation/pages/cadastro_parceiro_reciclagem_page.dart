import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/cep_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';

class CadastroParceiroReciclagemPage extends StatefulWidget {
  final String email;
  final String password;

  const CadastroParceiroReciclagemPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<CadastroParceiroReciclagemPage> createState() =>
      _CadastroParceiroReciclagemPageState();
}

class _CadastroParceiroReciclagemPageState
    extends State<CadastroParceiroReciclagemPage> {
  final _formKey = GlobalKey<FormState>();
  final _cepService = CepService();

  final _companyController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _cpfController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _complementController = TextEditingController();
  final _numberController = TextEditingController();

  final _regionController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  String _selectedCategory = 'Remoção de Recicláveis';
  String? _lastSearchedCep;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingCep = false;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _cnpjController.dispose();
    _responsibleController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _cepController.dispose();
    _addressController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _complementController.dispose();
    _numberController.dispose();

    _regionController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _PageHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 90),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cadastro Parceiro de Reciclagem',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Preencha os dados da empresa',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      const SizedBox(height: 28),

                      _buildField(
                        label: 'Nome da Empresa',
                        controller: _companyController,
                        hint: 'Razão social da cooperativa/empresa',
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'CNPJ',
                        controller: _cnpjController,
                        hint: '00.000.000/0001-00',
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly(14),
                        validator: _validateCnpj,
                      ),
                      _buildField(
                        label: 'Nome Completo do Responsável',
                        controller: _responsibleController,
                        hint: 'Responsável pela triagem/parceria',
                        validator: _validateFullName,
                      ),
                      _buildField(
                        label: 'CPF do Responsável',
                        controller: _cpfController,
                        hint: '000.000.000-00',
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly(11),
                        validator: _validateCpf,
                      ),
                      _buildField(
                        label: 'E-mail',
                        controller: _emailController,
                        hint: 'reciclagem@dominio.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      _buildField(
                        label: 'Confirmar E-mail',
                        controller: _confirmEmailController,
                        hint: 'Confirme o e-mail cadastrado',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmailConfirmation,
                      ),
                      _buildField(
                        label: 'Senha',
                        controller: _passwordController,
                        hint: 'Senha segura',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      _buildField(
                        label: 'Confirmar Senha',
                        controller: _confirmPasswordController,
                        hint: 'Confirme a senha',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        validator: _validatePasswordConfirmation,
                      ),

                      _buildField(
                        label: 'CEP',
                        controller: _cepController,
                        hint: '00000-000',
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly(8),
                        validator: _validateCep,
                        onChanged: _searchAddressByCep,
                        suffixIcon: _isLoadingCep
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.green,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Consultar CEP',
                                onPressed: () {
                                  _searchAddressByCep(
                                    _cepController.text,
                                    force: true,
                                  );
                                },
                                icon: const Icon(Icons.search),
                              ),
                      ),
                      _buildField(
                        label: 'Endereço',
                        controller: _addressController,
                        hint: 'Rua do centro de reciclagem',
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Bairro',
                        controller: _neighborhoodController,
                        hint: 'Bairro',
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Cidade',
                        controller: _cityController,
                        hint: 'Cidade',
                        readOnly: true,
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Estado',
                        controller: _stateController,
                        hint: 'UF',
                        readOnly: true,
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Complemento',
                        controller: _complementController,
                        hint: 'Galpão, bloco ou referência (opcional)',
                        validator: (_) => null,
                      ),
                      _buildField(
                        label: 'Número',
                        controller: _numberController,
                        hint: 'Nº',
                        keyboardType: TextInputType.number,
                        validator: _requiredValidator,
                      ),

                      _buildField(
                        label: 'Região de Atendimento',
                        controller: _regionController,
                        hint: 'Ex: Centro, Zona Norte',
                        validator: _requiredValidator,
                      ),
                      _buildField(
                        label: 'Telefone Contato 1',
                        controller: _phone1Controller,
                        hint: '(11) 99999-9999',
                        keyboardType: TextInputType.phone,
                        inputFormatters: _digitsOnly(11),
                        validator: _validatePhone,
                      ),
                      _buildField(
                        label: 'Telefone Contato 2',
                        controller: _phone2Controller,
                        hint: '(11) 99999-9999 (Opcional)',
                        keyboardType: TextInputType.phone,
                        inputFormatters: _digitsOnly(11),
                        validator: _validateOptionalPhone,
                      ),

                      const _FieldLabel('Categoria de Serviço'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Remoção de Recicláveis',
                            child: Text('Remoção de Recicláveis'),
                          ),
                          DropdownMenuItem(
                            value: 'Coleta de Plásticos',
                            child: Text('Coleta de Plásticos'),
                          ),
                          DropdownMenuItem(
                            value: 'Coleta de Metais',
                            child: Text('Coleta de Metais'),
                          ),
                          DropdownMenuItem(
                            value: 'Coleta de Papel e Papelão',
                            child: Text('Coleta de Papel e Papelão'),
                          ),
                          DropdownMenuItem(
                            value: 'Coleta de Vidros',
                            child: Text('Coleta de Vidros'),
                          ),
                          DropdownMenuItem(
                            value: 'Coleta de Eletrônicos',
                            child: Text('Coleta de Eletrônicos'),
                          ),
                          DropdownMenuItem(
                            value: 'Coleta de Óleo',
                            child: Text('Coleta de Óleo'),
                          ),
                          DropdownMenuItem(
                            value: 'Reciclagem Geral',
                            child: Text('Reciclagem Geral'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 38),
                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF2F8334),
                            disabledBackgroundColor: AppColors.green.withValues(
                              alpha: 0.55,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'CADASTRAR-SE',
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
          ],
        ),
      ),
    );
  }

  List<TextInputFormatter> _digitsOnly(int maxLength) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool obscureText = false,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            onChanged: onChanged,
            validator: validator,
            decoration: _inputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
              fillColor: readOnly ? AppColors.lightGray : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    Color fillColor = Colors.white,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }

    return null;
  }

  String? _validateFullName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Informe o nome do responsável';
    }

    if (!name.contains(' ')) {
      return 'Informe nome e sobrenome';
    }

    return null;
  }

  String? _validateCnpj(String? value) {
    final cnpj = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cnpj.length != 14) {
      return 'Informe um CNPJ com 14 dígitos';
    }

    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) {
      return 'Informe um CNPJ válido';
    }

    return null;
  }

  String? _validateCpf(String? value) {
    final cpf = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cpf.length != 11) {
      return 'Informe um CPF com 11 dígitos';
    }

    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'Informe um CPF válido';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail';
    }

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    return valid ? null : 'Informe um e-mail válido';
  }

  String? _validateEmailConfirmation(String? value) {
    final validation = _validateEmail(value);

    if (validation != null) return validation;

    if (value!.trim().toLowerCase() !=
        _emailController.text.trim().toLowerCase()) {
      return 'Os e-mails não são iguais';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }

    if (value.length < 6) {
      return 'A senha deve possuir no mínimo 6 caracteres';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha';
    }

    if (value != _passwordController.text) {
      return 'As senhas não são iguais';
    }

    return null;
  }

  String? _validateCep(String? value) {
    final cep = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    return cep.length == 8 ? null : 'Informe um CEP com 8 dígitos';
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    return phone.length >= 10 ? null : 'Informe um telefone válido';
  }

  String? _validateOptionalPhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (phone.isNotEmpty && phone.length < 10) {
      return 'Informe um telefone válido';
    }

    return null;
  }

  Future<void> _searchAddressByCep(String value, {bool force = false}) async {
    final cep = value.replaceAll(RegExp(r'\D'), '');

    if (cep.length != 8) {
      _lastSearchedCep = null;
      return;
    }

    if (_isLoadingCep) return;

    if (!force && cep == _lastSearchedCep) {
      return;
    }

    _lastSearchedCep = cep;

    setState(() {
      _isLoadingCep = true;
    });

    try {
      final address = await _cepService.findAddress(cep);

      if (!mounted) return;

      final currentCep = _cepController.text.replaceAll(RegExp(r'\D'), '');

      // Impede uma resposta antiga de preencher o formulário.
      if (currentCep != cep) return;

      _addressController.text = address.street;
      _neighborhoodController.text = address.neighborhood;
      _cityController.text = address.city;
      _stateController.text = address.state;

      if (_complementController.text.trim().isEmpty) {
        _complementController.text = address.complement;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endereço encontrado.'),
          backgroundColor: AppColors.green,
        ),
      );
    } on CepException catch (error) {
      if (!mounted) return;

      _lastSearchedCep = null;
      _clearAddressFields();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;

      _lastSearchedCep = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível consultar o CEP.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCep = false;
        });
      }
    }
  }

  void _clearAddressFields() {
    _addressController.clear();
    _neighborhoodController.clear();
    _cityController.clear();
    _stateController.clear();
    _complementController.clear();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Será substituído pela integração com a API principal.
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.green,
            size: 48,
          ),
          title: const Text('Cadastro enviado!'),
          content: const Text(
            'Os dados do parceiro de reciclagem foram enviados para análise.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const AppLogo(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}
