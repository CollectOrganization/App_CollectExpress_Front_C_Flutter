// ignore_for_file: avoid_print — roteiro de linha de comando que imprime a evidência.

// Evidência do CT-16: consulta o ViaCEP com o mesmo CepService usado nos
// formulários de cadastro e de endereço do app.
//
// Uso: dart run tool/cep_evidence.dart > test-results/cep-evidence.txt
import 'package:app_collect_express_with_flutter/core/services/cep_service.dart';

Future<void> main() async {
  final service = CepService();
  final casos = {
    '01311-200': 'CEP válido (Av. Paulista, São Paulo)',
    '09310-000': 'CEP válido (Mauá)',
    '00000-000': 'CEP inexistente',
    '1234': 'CEP com menos de 8 dígitos',
  };

  print('# Consulta de CEP pelo CepService (${DateTime.now().toIso8601String()})');
  for (final MapEntry(key: cep, value: descricao) in casos.entries) {
    final inicio = DateTime.now();
    try {
      final e = await service.findAddress(cep);
      final ms = DateTime.now().difference(inicio).inMilliseconds;
      print('$cep | $descricao | OK em $ms ms | '
          '${e.street}, ${e.neighborhood}, ${e.city}/${e.state}');
    } on CepException catch (error) {
      final ms = DateTime.now().difference(inicio).inMilliseconds;
      print('$cep | $descricao | recusado em $ms ms | ${error.message}');
    }
  }
}
