import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

class SyncInboxWatcher extends ChangeNotifier {
  static const String _inboxDirName = 'sync_queue/inbox';
  static const String _processedDirName = 'sync_queue/inbox/processed';

  Directory? _inboxDir;
  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _retryTimer;
  bool _isWatching = false;
  String? _errorMessage;

  final void Function(OrderModel order)? onOrderReceived;
  final void Function(String orderId, OrderStatus status)? onStatusUpdated;

  SyncInboxWatcher({
    this.onOrderReceived,
    this.onStatusUpdated,
  });

  bool get isWatching => _isWatching;
  String? get errorMessage => _errorMessage;

  Future<void> initialize({String? customPath}) async {
    try {
      final baseDir = customPath ?? (await getApplicationDocumentsDirectory()).path;
      _inboxDir = Directory('$baseDir/$_inboxDirName');
      final processedDir = Directory('$baseDir/$_processedDirName');

      if (!await _inboxDir!.exists()) {
        await _inboxDir!.create(recursive: true);
      }
      if (!await processedDir.exists()) {
        await processedDir.create(recursive: true);
      }

      _processExistingFiles();
      _startWatching();
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation SyncInbox: $e';
      debugPrint(_errorMessage);
      notifyListeners();
    }
  }

  void _processExistingFiles() {
    if (_inboxDir == null) return;
    final files = _inboxDir!.listSync().whereType<File>();
    for (final file in files) {
      _processFile(file);
    }
  }

  void _startWatching() {
    if (_inboxDir == null || _isWatching) return;

    try {
      _subscription = _inboxDir!.watch(recursive: false).listen((event) {
        if (event is FileSystemCreateEvent || event is FileSystemModifyEvent) {
          final file = File(event.path);
          if (file.path.endsWith('.json')) {
            _debounceProcess(file);
          }
        }
      });

      _isWatching = true;
      notifyListeners();
      debugPrint('SyncInboxWatcher: Surveillance active sur ${_inboxDir!.path}');
    } catch (e) {
      _errorMessage = 'Erreur de surveillance: $e';
      notifyListeners();
      _scheduleRetry();
    }
  }

  Timer? _debounceTimer;

  void _debounceProcess(File file) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _processFile(file);
    });
  }

  void _processFile(File file) {
    try {
      final content = file.readAsStringSync();
      final Map<String, dynamic> message = jsonDecode(content);
      final String? type = message['type'];
      final Map<String, dynamic>? payload = message['payload'];

      if (type == null || payload == null) return;

      switch (type) {
        case 'ORDER_CREATED':
          _handleOrderCreated(payload);
          break;
        case 'STATUS_UPDATED':
          _handleStatusUpdated(payload);
          break;
        case 'ORDER_PAID':
          _handleOrderPaid(payload);
          break;
      }

      _moveToProcessed(file);
    } catch (e) {
      debugPrint('Erreur de traitement du fichier ${file.path}: $e');
    }
  }

  void _handleOrderCreated(Map<String, dynamic> payload) {
    final order = _parseOrder(payload);
    if (order != null) {
      onOrderReceived?.call(order);
    }
  }

  void _handleStatusUpdated(Map<String, dynamic> payload) {
    final String orderId = payload['order_id']?.toString() ?? '';
    final String statusStr = payload['status'] ?? 'A_FAIRE';
    final OrderStatus status = _parseStatus(statusStr);

    if (orderId.isNotEmpty) {
      onStatusUpdated?.call(orderId, status);
    }
  }

  void _handleOrderPaid(Map<String, dynamic> payload) {
    final String orderId = payload['order_id']?.toString() ?? '';
    if (orderId.isNotEmpty) {
      onOrderReceived?.call(OrderModel(
        id: orderId,
        tableNumber: '',
        status: OrderStatus.fait,
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: '_paid',
      ));
    }
  }

  void _moveToProcessed(File file) {
    try {
      final parentDir = file.parent;
      final processedDir = Directory('${parentDir.path}/processed');
      if (!processedDir.existsSync()) {
        processedDir.createSync(recursive: true);
      }

      final newPath = '${processedDir.path}/${file.uri.pathSegments.last}';
      file.renameSync(newPath);
      debugPrint('Fichier traité déplacé: $newPath');
    } catch (e) {
      debugPrint('Erreur de déplacement du fichier: $e');
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 10), () {
      _startWatching();
    });
  }

  OrderModel? _parseOrder(Map<String, dynamic> payload) {
    try {
      final String orderId = payload['order_id']?.toString() ?? '';
      final String tableNumber = payload['table_number'] ?? '';
      final String statusStr = payload['status'] ?? 'A_FAIRE';
      final String createdAt = payload['created_at'] ?? DateTime.now().toIso8601String();
      final String? notes = payload['notes'];
      final List<dynamic> itemsData = payload['items'] ?? [];

      final List<OrderItem> items = itemsData.map((item) => OrderItem(
        name: item['product_name'] ?? '',
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        notes: item['notes']?.toString().isNotEmpty == true ? item['notes'] : null,
      )).toList();

      return OrderModel(
        id: orderId,
        tableNumber: tableNumber,
        status: _parseStatus(statusStr),
        items: items,
        createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
        notes: notes,
      );
    } catch (e) {
      debugPrint('Erreur de parsing de commande: $e');
      return null;
    }
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

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    _isWatching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
