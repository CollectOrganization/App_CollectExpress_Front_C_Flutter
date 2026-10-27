// Conversões tolerantes para o JSON da API. O driver do Postgres devolve
// colunas DECIMAL como texto ("350.00") e datas como texto ISO.

String parseString(dynamic value) => value?.toString() ?? '';

String? parseStringOrNull(dynamic value) => value?.toString();

double parseDouble(dynamic value) => parseDoubleOrNull(value) ?? 0;

double? parseDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value == null) return null;
  return double.tryParse(value.toString());
}

int parseInt(dynamic value) => parseIntOrNull(value) ?? 0;

int? parseIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return null;
  return int.tryParse(value.toString()) ?? double.tryParse('$value')?.toInt();
}

bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return value.toString().toLowerCase() == 'true';
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Para colunas DATE. A API pode mandar `2026-10-25` ou
/// `2026-10-25T00:00:00.000Z` (meia-noite no fuso do servidor), então
/// usa só a parte da data, sem converter fuso.
DateTime? parseDateOnly(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.length < 10) return null;
  return DateTime.tryParse(text.substring(0, 10));
}

Map<String, dynamic>? parseMap(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : null;
}

/// Lista de objetos JSON, ignorando o que não for objeto.
List<T> parseList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

/// Data no formato `YYYY-MM-DD`, usado nas colunas DATE da API.
String formatApiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
