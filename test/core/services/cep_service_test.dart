import 'dart:convert';

import 'package:app_collect_express_with_flutter/core/services/cep_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  CepService serviceRespondendo(int status, Object corpo) {
    return CepService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(corpo),
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
  }

  test('devolve o endereço de um CEP válido', () async {
    final service = serviceRespondendo(200, {
      'cep': '09310-000',
      'logradouro': 'Avenida Barão de Mauá',
      'bairro': 'Vila Bocaina',
      'localidade': 'Mauá',
      'uf': 'SP',
    });

    final endereco = await service.findAddress('09310-000');

    expect(endereco.street, 'Avenida Barão de Mauá');
    expect(endereco.city, 'Mauá');
    expect(endereco.state, 'SP');
  });

  test(
    'recusa CEP inexistente quando o ViaCEP responde "erro" como texto',
    () async {
      final service = serviceRespondendo(200, {'erro': 'true'});

      expect(
        service.findAddress('99999-999'),
        throwsA(
          isA<CepException>().having(
            (e) => e.message,
            'message',
            'CEP não encontrado.',
          ),
        ),
      );
    },
  );

  test(
    'recusa CEP inexistente no formato antigo, com "erro" booleano',
    () async {
      final service = serviceRespondendo(200, {'erro': true});

      expect(service.findAddress('99999-999'), throwsA(isA<CepException>()));
    },
  );

  test('CEP com menos de 8 dígitos nem consulta o ViaCEP', () async {
    var chamadas = 0;
    final service = CepService(
      client: MockClient((_) async {
        chamadas++;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      service.findAddress('1234'),
      throwsA(isA<CepException>()),
    );
    expect(chamadas, 0);
  });
}
