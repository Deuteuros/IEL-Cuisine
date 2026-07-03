import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_client_service.dart';
import 'order_provider.dart';

final networkClientProvider = ChangeNotifierProvider<NetworkClientService>((ref) {
  final orderNotifier = ref.read(orderProvider.notifier);

  final service = NetworkClientService(
    onOrderCreated: (order) {
      orderNotifier.addOrUpdateOrder(order);
    },
    onStatusUpdated: (orderId, status) {
      orderNotifier.updateOrderStatus(orderId, status);
    },
    onOrderPaid: (orderId) {
      orderNotifier.removeOrder(orderId);
    },
  );

  ref.onDispose(() => service.dispose());
  return service;
});
