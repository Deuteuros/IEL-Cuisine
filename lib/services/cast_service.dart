import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CastDevice {
  final String id;
  final String name;
  final String ipAddress;

  const CastDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
  });
}

enum CastStatus { unavailable, available, connecting, connected, casting }

class CastService extends ChangeNotifier {
  static const _channel = MethodChannel('com.iel.cuisine/cast');

  CastStatus _status = CastStatus.unavailable;
  List<CastDevice> _devices = [];
  CastDevice? _selectedDevice;
  String? _errorMessage;

  CastStatus get status => _status;
  List<CastDevice> get devices => List.unmodifiable(_devices);
  CastDevice? get selectedDevice => _selectedDevice;
  String? get errorMessage => _errorMessage;
  bool get isCasting => _status == CastStatus.casting;

  Future<void> initialize() async {
    try {
      final available = await _channel.invokeMethod<bool>('isCastAvailable') ?? false;
      _status = available ? CastStatus.available : CastStatus.unavailable;
      notifyListeners();

      if (available) {
        _channel.setMethodCallHandler(_handleNativeCall);
      }
    } catch (e) {
      _status = CastStatus.unavailable;
      _errorMessage = 'Cast non disponible: $e';
      notifyListeners();
    }
  }

  Future<void> startDiscovery() async {
    if (_status == CastStatus.unavailable) return;
    try {
      await _channel.invokeMethod('startDiscovery');
    } catch (e) {
      debugPrint('Cast discovery error: $e');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
    } catch (e) {
      debugPrint('Cast stopDiscovery error: $e');
    }
  }

  Future<void> connect(CastDevice device) async {
    try {
      _status = CastStatus.connecting;
      _selectedDevice = device;
      notifyListeners();

      final success = await _channel.invokeMethod<bool>('connect', {
        'deviceId': device.id,
      }) ?? false;

      if (success) {
        _status = CastStatus.connected;
      } else {
        _status = CastStatus.available;
        _selectedDevice = null;
        _errorMessage = 'Échec de connexion au périphérique Cast';
      }
      notifyListeners();
    } catch (e) {
      _status = CastStatus.available;
      _selectedDevice = null;
      _errorMessage = 'Erreur de connexion Cast: $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _status = CastStatus.available;
      _selectedDevice = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Cast disconnect error: $e');
    }
  }

  Future<void> startCast() async {
    if (_status != CastStatus.connected) return;
    try {
      await _channel.invokeMethod('startCast');
      _status = CastStatus.casting;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur de démarrage du Cast: $e';
      notifyListeners();
    }
  }

  Future<void> stopCast() async {
    try {
      await _channel.invokeMethod('stopCast');
      _status = CastStatus.connected;
      notifyListeners();
    } catch (e) {
      debugPrint('Cast stop error: $e');
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeviceFound':
        final args = call.arguments as Map<dynamic, dynamic>;
        final device = CastDevice(
          id: args['id'] as String,
          name: args['name'] as String,
          ipAddress: args['ipAddress'] as String,
        );
        if (!_devices.any((d) => d.id == device.id)) {
          _devices = [..._devices, device];
          notifyListeners();
        }
        break;
      case 'onDeviceLost':
        final deviceId = call.arguments as String;
        _devices = _devices.where((d) => d.id != deviceId).toList();
        if (_selectedDevice?.id == deviceId) {
          _selectedDevice = null;
          _status = CastStatus.available;
        }
        notifyListeners();
        break;
    }
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}
