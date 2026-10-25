import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static const String _ordersKey = 'collectexpress_customer_orders';

  static final ValueNotifier<List<Map<String, dynamic>>> ordersNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_ordersKey);
      if (ordersJson != null && ordersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(ordersJson);
        ordersNotifier.value = decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar pedidos em cache: $e');
    }
  }

  /// Gera um número sequencial e único para cada novo pedido (ex: #COL-2024-1587, #COL-2024-1588...)
  static String generateOrderNumber() {
    final now = DateTime.now();
    int highestNum = 1586;
    for (final o in ordersNotifier.value) {
      final numStr = o['orderNumber']?.toString() ?? '';
      final match = RegExp(r'#COL-\d+-(\d+)').firstMatch(numStr);
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null && parsed > highestNum) {
          highestNum = parsed;
        }
      }
    }
    return '#COL-${now.year}-${highestNum + 1}';
  }

  /// Sempre realiza um novo INSERT de pedido na lista, permitindo múltiplos pedidos ativos
  static Future<Map<String, dynamic>> addOrder(Map<String, dynamic> order) async {
    try {
      final updated = List<Map<String, dynamic>>.from(ordersNotifier.value);
      final newOrder = Map<String, dynamic>.from(order);

      // Se o pedido não tem número ou se já existe um pedido com este número, gera um novo exclusivo
      if (newOrder['orderNumber'] == null ||
          updated.any((o) => o['orderNumber'] == newOrder['orderNumber'])) {
        newOrder['orderNumber'] = generateOrderNumber();
      }

      newOrder['id'] ??= '${DateTime.now().millisecondsSinceEpoch}_${newOrder['orderNumber']}';

      // INSERT no topo da lista (cada tentativa é um novo pedido separado)
      updated.insert(0, newOrder);
      ordersNotifier.value = updated;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ordersKey, jsonEncode(updated));
      return newOrder;
    } catch (e) {
      debugPrint('Erro ao salvar pedido: $e');
      return order;
    }
  }

  static Future<void> cancelOrder(String orderNumber) async {
    try {
      final updated = ordersNotifier.value.map((o) {
        if (o['orderNumber'] == orderNumber) {
          final copy = Map<String, dynamic>.from(o);
          copy['status'] = 'Cancelado';
          return copy;
        }
        return o;
      }).toList();

      ordersNotifier.value = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ordersKey, jsonEncode(updated));
    } catch (e) {
      debugPrint('Erro ao cancelar pedido: $e');
    }
  }

  static Future<void> clearOrders() async {
    try {
      ordersNotifier.value = [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ordersKey);
    } catch (e) {
      debugPrint('Erro ao limpar pedidos: $e');
    }
  }
}
