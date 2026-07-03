enum OrderStatus {
  aFaire,
  enCours,
  fait,
}

class OrderItem {
  final String name;
  final int quantity;
  final String? notes;

  const OrderItem({
    required this.name,
    required this.quantity,
    this.notes,
  });
}

class OrderModel {
  final String id;
  final String tableNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  const OrderModel({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  OrderModel copyWith({
    String? id,
    String? tableNumber,
    OrderStatus? status,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Duration get elapsed => DateTime.now().difference(createdAt);
}
