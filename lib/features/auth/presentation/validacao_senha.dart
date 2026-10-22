/// Regra de senha da API no cadastro: 8 a 128 caracteres, com pelo menos
/// uma letra maiúscula, uma minúscula e um número.
String? validarSenhaCadastro(String? value) {
  if (value == null || value.isEmpty) {
    return 'Informe sua senha';
  }

  if (value.length < 8) {
    return 'A senha deve possuir pelo menos 8 caracteres';
  }

  if (value.length > 128) {
    return 'A senha deve possuir no máximo 128 caracteres';
  }

  if (!RegExp('[A-Z]').hasMatch(value)) {
    return 'A senha deve ter pelo menos uma letra maiúscula';
  }

  if (!RegExp('[a-z]').hasMatch(value)) {
    return 'A senha deve ter pelo menos uma letra minúscula';
  }

  if (!RegExp(r'\d').hasMatch(value)) {
    return 'A senha deve ter pelo menos um número';
  }

  return null;
}
