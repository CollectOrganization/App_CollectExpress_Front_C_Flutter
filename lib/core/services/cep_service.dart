import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cep_address.dart';

class CepService {
  /// [client] permite trocar o acesso à rede nos testes.
  CepService({this.client});

  static const _baseUrl = 'https://viacep.com.br/ws';

  final http.Client? client;

  Future<CepAddress> findAddress(String cep) async {
    final normalizedCep = cep.replaceAll(RegExp(r'\D'), '');

    if (normalizedCep.length != 8) {
      throw const CepException('CEP deve possuir 8 dígitos.');
    }

    try {
      final uri = Uri.parse('$_baseUrl/$normalizedCep/json/');
      final response = await (client?.get(uri) ?? http.get(uri)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw const CepException('Não foi possível consultar o CEP.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // O ViaCEP responde {"erro": "true"} (texto) para CEP inexistente;
      // versões antigas respondiam {"erro": true}. A chave basta.
      if (json.containsKey('erro')) {
        throw const CepException('CEP não encontrado.');
      }

      return CepAddress.fromJson(json);
    } on TimeoutException {
      throw const CepException('A consulta demorou muito. Tente novamente.');
    } on CepException {
      rethrow;
    } catch (_) {
      throw const CepException('Não foi possível consultar o CEP.');
    }
  }
}

class CepException implements Exception {
  final String message;

  const CepException(this.message);

  @override
  String toString() => message;
}
