/// A API está migrando do corpo "puro" para `{success, message, data}`
/// (branch `feature/flutter-integration`). Enquanto as duas versões
/// convivem, devolve o `data` quando existe e o corpo inteiro quando não.
dynamic unwrapData(dynamic body) {
  if (body is Map && body['success'] == true && body.containsKey('data')) {
    final data = body['data'];

    // `GET /usuarios` manda a lista em `data` e a paginação fora dela.
    if (data is List && body['pagination'] is Map) {
      return {'items': data, 'pagination': body['pagination']};
    }

    return data;
  }

  return body;
}
