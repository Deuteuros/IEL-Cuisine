import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/order.dart';

enum ConnectionStatus { disconnected, connecting, connected, error, searching }

class DiscoveredServer {
  final String name;
  final String ip;
  final int port;

  const DiscoveredServer({
    required this.name,
    required this.ip,
    required this.port,
  });
}

class NetworkClientService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  nsd.Discovery? _discovery;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  static const int _maxReconnectAttempts = 10;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _serverUrl;
  String? _errorMessage;
  final List<DiscoveredServer> _discoveredServers = [];

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
  List<DiscoveredServer> get discoveredServers => List.unmodifiable(_discoveredServers);

  Future<void> startMdnsDiscovery() async {
    if (_discovery != null) return;
    _status = ConnectionStatus.searching;
    notifyListeners();

    try {
      _discovery = await nsd.startDiscovery(
        '_caissecash._tcp',
        autoResolve: true,
        ipLookupType: nsd.IpLookupType.v4,
      );

      _discovery!.addServiceListener(_onServiceDiscovered);

      for (final service in _discovery!.services) {
        _addDiscoveredService(service);
      }

      _discovery!.addListener(_onDiscoveryChanged);
    } catch (e) {
      debugPrint('mDNS discovery error: $e');
    }
  }

  void _onDiscoveryChanged() {
    for (final service in _discovery!.services) {
      _addDiscoveredService(service);
    }
  }

  void _onServiceDiscovered(nsd.Service service, nsd.ServiceStatus status) {
    if (status == nsd.ServiceStatus.found) {
      _addDiscoveredService(service);
    }
  }

  void _addDiscoveredService(nsd.Service service) {
    final ip = service.addresses
        ?.where((a) => a.type == InternetAddressType.IPv4)
        .firstOrNull
        ?.address;

    if (ip == null || service.port == null) return;

    final server = DiscoveredServer(
      name: service.name ?? 'Serveur',
      ip: ip,
      port: service.port!,
    );

    final alreadyKnown = _discoveredServers.any(
      (s) => s.ip == server.ip && s.port == server.port,
    );
    if (!alreadyKnown) {
      _discoveredServers.add(server);
      notifyListeners();
    }

    if (_status != ConnectionStatus.connected && _status != ConnectionStatus.connecting) {
      connect(server.ip, port: server.port);
    }
  }

  Future<void> stopMdnsDiscovery() async {
    if (_discovery != null) {
      await nsd.stopDiscovery(_discovery!);
      _discovery = null;
    }
    if (_status == ConnectionStatus.searching) {
      _status = ConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> connect(String ipAddress, {int port = 8080}) async {
    if (_status == ConnectionStatus.connected) return;
    _cancelReconnect();

    final url = 'ws://$ipAddress:$port/ws';
    _serverUrl = url;
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;

      _status = ConnectionStatus.connected;
      _reconnectAttempt = 0;
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
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempt >= _maxReconnectAttempts) return;
    _cancelReconnect();

    final delay = Duration(
      seconds: (_reconnectAttempt + 1) * 2,
    );
    _reconnectAttempt++;

    debugPrint('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempt)');
    _status = ConnectionStatus.searching;
    notifyListeners();

    _reconnectTimer = Timer(delay, () {
      if (_discoveredServers.isNotEmpty) {
        final server = _discoveredServers.first;
        connect(server.ip, port: server.port);
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> disconnect() async {
    _cancelReconnect();
    _reconnectAttempt = 0;
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
    _scheduleReconnect();
  }

  void _handleError(Object error) {
    _status = ConnectionStatus.error;
    _errorMessage = 'Erreur réseau : $error';
    notifyListeners();
    _scheduleReconnect();
  }

  @override
  void dispose() {
    _cancelReconnect();
    _reconnectAttempt = 0;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _status = ConnectionStatus.disconnected;
    if (_discovery != null) {
      _discovery!.removeListener(_onDiscoveryChanged);
      _discovery!.removeServiceListener(_onServiceDiscovered);
      _discovery = null;
    }
    super.dispose();
  }
}
