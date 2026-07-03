import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/order.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class NetworkClientService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _serverUrl;
  String? _errorMessage;

  // Callbacks pour notifier les providers
  final void Function(OrderModel order)? onOrderCreated;
  final void Function(String orderId, OrderStatus status)? onStatusUpdated;
  final void Function(String orderId)? onOrderPaid;

  NetworkClientService({
    this.onOrderCreated,
    this.onStatusUpdated,
    this.onOrderPaid,
  });

  ConnectionStatus get status => _status;
  String? get serverUrl => _serverUrl;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == ConnectionStatus.connected;

  Future<void> connect(String ipAddress, {int port = 8080}) async {
    if (_status == ConnectionStatus.connected || _status == ConnectionStatus.connecting) {
      await disconnect();
    }

    final url = 'ws://$ipAddress:$port/ws';
    _serverUrl = url;
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;

      _status = ConnectionStatus.connected;
      notifyListeners();

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: _handleError,
      );
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = 'Connexion échouée : $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    _serverUrl = null;
    notifyListeners();
  }

  void send(Map<String, dynamic> message) {
    if (_status != ConnectionStatus.connected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Sends UPDATE_STATUS when the kitchen drags an order to a new column.
  void sendUpdateStatus(String orderId, OrderStatus status) {
    final String statusStr;
    switch (status) {
      case OrderStatus.enCours:
        statusStr = 'EN_COURS';
        break;
      case OrderStatus.fait:
        statusStr = 'FAIT';
        break;
      default:
        statusStr = 'A_FAIRE';
    }

    send({
      'type': 'UPDATE_STATUS',
      'sender': 'KITCHEN_APP',
      'timestamp': DateTime.now().toIso8601String(),
      'payload': {
        'order_id': orderId,
        'status': statusStr,
      },
    });
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final Map<String, dynamic> message = jsonDecode(rawMessage.toString());
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
        // SYNC_MENU is ignored by the kitchen app
      }
    } catch (e) {
      debugPrint('Error parsing message: $e');
    }
  }

  void _handleOrderCreated(Map<String, dynamic> payload) {
    final order = _parseOrder(payload);
    if (order != null) {
      onOrderCreated?.call(order);
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
      onOrderPaid?.call(orderId);
    }
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
      debugPrint('Error parsing order: $e');
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

  void _handleDisconnect() {
    _status = ConnectionStatus.disconnected;
    _errorMessage = 'Connexion perdue. Reconnexion…';
    notifyListeners();
  }

  void _handleError(Object error) {
    _status = ConnectionStatus.error;
    _errorMessage = 'Erreur réseau : $error';
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
