import '../../../core/models/endereco.dart';
import '../../../core/utils/formatters.dart';

extension EnderecoTexto on Endereco {
  /// `Avenida Paulista, 1000`
  String get ruaENumero => numero.isEmpty ? logradouro : '$logradouro, $numero';

  /// `Bela Vista, São Paulo/SP • CEP 01311-200`
  String get regiaoECep {
    final regiao = [
      bairro,
      cidadeEstado,
    ].where((parte) => parte.isNotEmpty).join(', ');
    return '$regiao • CEP ${formatCep(cep)}';
  }
}
