import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class OrderNotifier extends StateNotifier<List<OrderModel>> {
  OrderNotifier() : super([]);

  void moveOrder(String orderId, OrderStatus newStatus) {
    state = state.map((order) {
      if (order.id == orderId) {
        return order.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }
      return order;
    }).toList();
  }

  void addOrUpdateOrder(OrderModel order) {
    final exists = state.any((o) => o.id == order.id);
    if (exists) {
      state = state.map((o) => o.id == order.id ? order : o).toList();
    } else {
      state = [order, ...state];
    }
  }

  void removeOrder(String orderId) {
    state = state.where((o) => o.id != orderId).toList();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    state = state.map((order) {
      if (order.id == orderId) {
        return order.copyWith(status: status, updatedAt: DateTime.now());
      }
      return order;
    }).toList();
  }

  void addMockOrder() {
    final nextTableNum = (state.length + 1) * 3 % 20 + 1;
    final newOrder = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: 'Table $nextTableNum',
      status: OrderStatus.aFaire,
      items: [
        const OrderItem(name: 'Phô Boeuf Spécial', quantity: 1, notes: 'Sans oignons'),
        const OrderItem(name: 'Nems au Porc', quantity: 2),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = [...state, newOrder];
  }

  Future<void> loadDemoOrders() async {
    final jsonString = await rootBundle.loadString('assets/samples/kitchen_demo_orders.json');
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    final now = DateTime.now();

    final orders = jsonList.map((json) {
      final createdAtStr = json['created_at'] as String;
      final createdAt = DateTime.tryParse(createdAtStr) ?? now;

      return OrderModel(
        id: json['order_id'] as String,
        tableNumber: json['table_number'] as String,
        status: _parseStatus(json['status'] as String? ?? 'A_FAIRE'),
        items: (json['items'] as List<dynamic>).map((item) => OrderItem(
          name: item['product_name'] as String,
          quantity: (item['quantity'] as num).toInt(),
          notes: item['notes'] as String?,
        )).toList(),
        createdAt: createdAt,
        updatedAt: createdAt,
        notes: json['notes'] as String?,
      );
    }).toList();

    state = orders;
  }

  OrderStatus _parseStatus(String status) {
    switch (status) {
      case 'EN_COURS':
        return OrderStatus.enCours;
      case 'FAIT':
        return OrderStatus.fait;
      default:
        return OrderStatus.aFaire;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier();
});
