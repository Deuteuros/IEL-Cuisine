import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class OrderNotifier extends StateNotifier<List<OrderModel>> {
  OrderNotifier() : super(_generateInitialMockData());

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

  static List<OrderModel> _generateInitialMockData() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: '1',
        tableNumber: 'Table 3',
        status: OrderStatus.aFaire,
        items: const [
          OrderItem(name: 'Phô Boeuf', quantity: 2, notes: 'Sans coriandre'),
          OrderItem(name: 'Bo Bun Poulet', quantity: 1),
          OrderItem(name: 'Nems Crevettes', quantity: 1),
        ],
        createdAt: now.subtract(const Duration(minutes: 8)),
        updatedAt: now.subtract(const Duration(minutes: 8)),
      ),
      OrderModel(
        id: '2',
        tableNumber: 'Table 8',
        status: OrderStatus.aFaire,
        items: const [
          OrderItem(name: 'Banh Mi Porc Grillé', quantity: 2, notes: 'Piment fort à part'),
          OrderItem(name: 'Raviolis Vapeur (Ha Cao)', quantity: 1),
        ],
        createdAt: now.subtract(const Duration(minutes: 12)),
        updatedAt: now.subtract(const Duration(minutes: 12)),
      ),
      OrderModel(
        id: '3',
        tableNumber: 'Table 5',
        status: OrderStatus.enCours,
        items: const [
          OrderItem(name: 'Phô Poulet', quantity: 1),
          OrderItem(name: 'Riz Loc Lac', quantity: 1, notes: 'Bien cuit'),
        ],
        createdAt: now.subtract(const Duration(minutes: 18)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      ),
      OrderModel(
        id: '4',
        tableNumber: 'Table 12',
        status: OrderStatus.enCours,
        items: const [
          OrderItem(name: 'Bô Bun Tofu', quantity: 2, notes: 'Sauce soja uniquement'),
          OrderItem(name: 'Rouleaux de Printemps', quantity: 2),
        ],
        createdAt: now.subtract(const Duration(minutes: 25)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
      ),
      OrderModel(
        id: '5',
        tableNumber: 'Table 2',
        status: OrderStatus.fait,
        items: const [
          OrderItem(name: 'Phô Boeuf Spécial', quantity: 3),
        ],
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier();
});
