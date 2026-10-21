/// A API está migrando do corpo "puro" para `{success, message, data}`
/// (branch `feature/flutter-integration`). Enquanto as duas versões
/// convivem, devolve o `data` quando existe e o corpo inteiro quando não.
dynamic unwrapData(dynamic body) {
  if (body is Map && body['success'] == true && body.containsKey('data')) {
    return body['data'];
  }

  return body;
}
