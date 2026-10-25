import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cep_address.dart';

class CepService {
  static const _baseUrl = 'https://viacep.com.br/ws';

  Future<CepAddress> findAddress(String cep) async {
    final normalizedCep = cep.replaceAll(RegExp(r'\D'), '');

    if (normalizedCep.length != 8) {
      throw const CepException('CEP deve possuir 8 dígitos.');
    }

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$normalizedCep/json/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw const CepException('Não foi possível consultar o CEP.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['erro'] == true) {
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
