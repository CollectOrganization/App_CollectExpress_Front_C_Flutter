import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/endereco.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/cep_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../perfil/data/enderecos_repository.dart';
import '../../data/auth_repository.dart';
import '../../data/sessao_provider.dart';
import '../validacao_senha.dart';

class CadastroClientePage extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const CadastroClientePage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<CadastroClientePage> createState() =>
      _CadastroClientePageState();
}

class _CadastroClientePageState extends ConsumerState<CadastroClientePage> {
  final _formKey = GlobalKey<FormState>();
  final _cepService = CepService();

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _numberController = TextEditingController();
  final _phoneController = TextEditingController();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingCep = false;

  String? _lastSearchedCep;

  /// Erros de validação devolvidos pela API, por campo.
  Map<String, String> _errosApi = const {};

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    _numberController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Impede sair da tela no meio do cadastro (conta, login e endereço).
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _PageHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 90),
                sliver: SliverToBoxAdapter(child: _buildForm()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cadastro Cliente',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Preencha seus dados pessoais',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 26),
          _buildField(
            label: 'Nome Completo',
            controller: _nameController,
            hint: 'Nome e sobrenome',
            textInputAction: TextInputAction.next,
            validator: _comErroDaApi('nome_completo', _validateName),
          ),
          _buildField(
            label: 'CPF',
            controller: _cpfController,
            hint: '000.000.000-00',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: _digitsOnly(11),
            validator: _comErroDaApi('documento', _validateCpf),
          ),
          _buildField(
            label: 'E-mail',
            controller: _emailController,
            hint: 'seu-email@dominio.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _comErroDaApi('email', _validateEmail),
          ),
          _buildField(
            label: 'Confirmar E-mail',
            controller: _confirmEmailController,
            hint: 'Confirme seu endereço de e-mail',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmailConfirmation,
          ),
          _buildField(
            label: 'Senha',
            controller: _passwordController,
            hint: 'Mínimo 8 caracteres, com maiúscula, minúscula e número',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
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
            validator: _comErroDaApi('senha', validarSenhaCadastro),
          ),
          _buildField(
            label: 'Confirmar Senha',
            controller: _confirmPasswordController,
            hint: 'Digite a senha novamente',
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              tooltip: _obscureConfirmPassword
                  ? 'Mostrar senha'
                  : 'Ocultar senha',
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
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
            textInputAction: TextInputAction.next,
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
                      _searchAddressByCep(_cepController.text, force: true);
                    },
                    icon: const Icon(Icons.search),
                  ),
          ),
          _buildField(
            label: 'Endereço',
            controller: _addressController,
            hint: 'Rua, Avenida, Logradouro',
            textInputAction: TextInputAction.next,
            validator: _validateStreet,
          ),
          _buildField(
            label: 'Bairro',
            controller: _neighborhoodController,
            hint: 'Bairro',
            textInputAction: TextInputAction.next,
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
            label: 'Número',
            controller: _numberController,
            hint: 'Número da residência',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: _requiredValidator,
          ),
          _buildField(
            label: 'Telefone',
            controller: _phoneController,
            hint: '(11) 99999-9999',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: _digitsOnly(11),
            validator: _comErroDaApi('telefone', _validatePhone),
          ),
          const SizedBox(height: 18),
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
    );
  }

  List<TextInputFormatter> _digitsOnly(int maxLength) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  /// Mostra primeiro o erro que a API devolveu para [campo], se houver.
  String? Function(String?) _comErroDaApi(
    String campo,
    String? Function(String?) validator,
  ) {
    return (value) => _errosApi[campo] ?? validator(value);
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
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
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: readOnly ? AppColors.lightGray : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: AppColors.green,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }

    return null;
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Informe seu nome completo';
    }

    if (!name.contains(' ')) {
      return 'Informe nome e sobrenome';
    }

    if (name.length > 150) {
      return 'O nome deve possuir no máximo 150 caracteres';
    }

    return null;
  }

  String? _validateStreet(String? value) {
    final street = value?.trim() ?? '';

    if (street.isEmpty) {
      return 'Este campo é obrigatório';
    }

    if (street.length > 200) {
      return 'O endereço deve possuir no máximo 200 caracteres';
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
      return 'Informe seu e-mail';
    }

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!valid) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  String? _validateEmailConfirmation(String? value) {
    final validation = _validateEmail(value);

    if (validation != null) {
      return validation;
    }

    if (value!.trim().toLowerCase() !=
        _emailController.text.trim().toLowerCase()) {
      return 'Os e-mails não são iguais';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme sua senha';
    }

    if (value != _passwordController.text) {
      return 'As senhas não são iguais';
    }

    return null;
  }

  String? _validateCep(String? value) {
    final cep = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (cep.length != 8) {
      return 'Informe um CEP com 8 dígitos';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (phone.length < 10) {
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

    if (_isLoadingCep) {
      return;
    }

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

      // Evita preencher os campos caso o usuário tenha alterado
      // o CEP enquanto a consulta estava em andamento.
      final currentCep = _cepController.text.replaceAll(RegExp(r'\D'), '');

      if (currentCep != cep) {
        return;
      }

      _addressController.text = address.street;
      _neighborhoodController.text = address.neighborhood;
      _cityController.text = address.city;
      _stateController.text = address.state;

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
  }

  /// Cria a conta, entra com ela e salva o endereço digitado.
  ///
  /// Depois que a conta existe, uma falha no login ou no endereço não volta
  /// para o formulário (cadastrar de novo daria "e-mail já cadastrado"):
  /// avisa o usuário e segue.
  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _errosApi = const {});

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final auth = ref.read(authRepositoryProvider);
    final sessao = ref.read(sessaoProvider.notifier);
    final enderecos = ref.read(enderecosRepositoryProvider);

    final email = _emailController.text.trim();
    final senha = _passwordController.text;
    final endereco = Endereco(
      cep: _cepController.text,
      logradouro: _addressController.text.trim(),
      numero: _numberController.text.trim(),
      bairro: _neighborhoodController.text.trim(),
      cidadeEstado:
          '${_cityController.text.trim()}/${_stateController.text.trim()}',
    );

    try {
      await auth.registrar(
        nomeCompleto: _nameController.text.trim(),
        email: email,
        senha: senha,
        tipoPerfil: TipoPerfil.consumidor,
        documento: _cpfController.text,
        telefone: _phoneController.text,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (error is ApiException) _errosApi = error.fields;
      });
      _formKey.currentState!.validate();
      showApiError(context, error);
      return;
    }

    Object? falhaLogin;
    Object? falhaEndereco;

    try {
      await sessao.entrar(email: email, senha: senha);
    } catch (error) {
      falhaLogin = error;
    }

    if (falhaLogin == null) {
      try {
        await enderecos.criar(endereco);
      } catch (error) {
        falhaEndereco = error;
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (falhaLogin != null) {
      await _mostrarResultado(
        sucesso: false,
        titulo: 'Conta criada!',
        mensagem:
            'Sua conta foi criada, mas não conseguimos entrar '
            'automaticamente. Entre com seu e-mail e senha; o endereço '
            'pode ser cadastrado depois em Meu Perfil.',
        motivo: falhaLogin,
        acao: 'Ir para o login',
      );
    } else if (falhaEndereco != null) {
      await _mostrarResultado(
        sucesso: false,
        titulo: 'Conta criada!',
        mensagem:
            'Sua conta foi criada, mas não foi possível salvar o endereço. '
            'Você pode cadastrá-lo depois em Meu Perfil.',
        motivo: falhaEndereco,
        acao: 'Continuar',
      );
    } else {
      await _mostrarResultado(
        sucesso: true,
        titulo: 'Cadastro realizado!',
        mensagem: 'Sua conta de cliente foi criada com sucesso.',
        acao: 'Continuar',
      );
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      falhaLogin == null ? AppRoutes.home : AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _mostrarResultado({
    required bool sucesso,
    required String titulo,
    required String mensagem,
    required String acao,
    Object? motivo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            sucesso ? Icons.check_circle_outline : Icons.info_outline,
            color: sucesso ? AppColors.green : Colors.orange,
            size: 48,
          ),
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensagem, textAlign: TextAlign.center),
              if (motivo != null) ...[
                const SizedBox(height: 12),
                Text(
                  motivo is ApiException
                      ? motivo.message
                      : 'Ocorreu um erro inesperado.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(acao),
            ),
          ],
        );
      },
    );
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
