/// Configuração da conexão com a CollectExpressAPI.
///
/// A URL é definida na hora de rodar ou compilar o app:
/// `flutter run --dart-define=API_BASE_URL=https://minha-api.com/api`
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api',
  );

  static const Duration timeout = Duration(seconds: 15);
}
