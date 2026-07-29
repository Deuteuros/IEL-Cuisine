import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_inbox_watcher.dart';
import 'order_provider.dart';

final syncInboxProvider = ChangeNotifierProvider<SyncInboxWatcher>((ref) {
  final orderNotifier = ref.read(orderProvider.notifier);

  final watcher = SyncInboxWatcher(
    onOrderReceived: (order) {
      orderNotifier.addOrUpdateOrder(order);
    },
    onStatusUpdated: (orderId, status) {
      orderNotifier.updateOrderStatus(orderId, status);
    },
  );

  ref.onDispose(() => watcher.dispose());

  return watcher;
});
