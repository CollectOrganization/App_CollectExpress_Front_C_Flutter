import 'json_parsing.dart';

/// Uma página de resultados. A API usa 20 itens por página.
class Pagina<T> {
  final List<T> itens;
  final int total;
  final int pagina;
  final int porPagina;
  final int totalPaginas;

  const Pagina({
    required this.itens,
    required this.total,
    required this.pagina,
    required this.porPagina,
    required this.totalPaginas,
  });

  bool get temProxima => pagina < totalPaginas;

  /// Aceita `{items, pagination: {total, page, per_page, total_pages}}`
  /// (API nova) e `{data, total, page, totalPages}` (API antiga).
  factory Pagina.fromJson(
    dynamic json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    if (json is List) {
      final itens = parseList(json, itemFromJson);
      return Pagina(
        itens: itens,
        total: itens.length,
        pagina: 1,
        porPagina: itens.length,
        totalPaginas: 1,
      );
    }

    final map = parseMap(json) ?? const {};
    final meta = parseMap(map['pagination']) ?? map;
    final itens = parseList(map['items'] ?? map['data'], itemFromJson);

    return Pagina(
      itens: itens,
      total: parseIntOrNull(meta['total']) ?? itens.length,
      pagina: parseIntOrNull(meta['page']) ?? 1,
      porPagina: parseIntOrNull(meta['per_page']) ?? 20,
      totalPaginas:
          parseIntOrNull(meta['total_pages'] ?? meta['totalPages']) ?? 1,
    );
  }
}
