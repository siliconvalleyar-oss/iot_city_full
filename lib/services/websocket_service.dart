import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/device.dart';
import '../models/energy_dashboard.dart';

enum ConnectionState { disconnected, connecting, connected }

enum WsMessageType {
  init,
  networkUpdate,
  deviceUpdate,
  deviceAdded,
  deviceRemoved,
  blackout,
  restore,
  systemReset,
  settingsUpdate,
  pong,
  dashboardTick,
  unknown,
}

class WsMessage {
  final WsMessageType type;
  final Map<String, dynamic> data;

  WsMessage({required this.type, required this.data});
}

class WebSocketService {
  WebSocketChannel? _channel;
  ConnectionState _state = ConnectionState.disconnected;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String _url;
  bool _disposed = false;

  final StreamController<WsMessage> _messageController =
      StreamController<WsMessage>.broadcast();
  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();

  Stream<WsMessage> get messages => _messageController.stream;
  Stream<ConnectionState> get stateStream => _stateController.stream;
  ConnectionState get state => _state;

  WebSocketService({required String url}) : _url = url;

  void updateUrl(String url) {
    _url = url;
    if (_state == ConnectionState.connected) {
      disconnect();
      connect();
    }
  }

  Future<void> connect() async {
    if (_disposed) return;
    if (_state == ConnectionState.connected) return;

    _state = ConnectionState.connecting;
    _stateController.add(_state);

    try {
      final uri = Uri.parse(_url);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _state = ConnectionState.connected;
      _stateController.add(_state);

      _startPing();

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );
    } catch (e) {
      _state = ConnectionState.disconnected;
      _stateController.add(_state);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final msg = data is String ? jsonDecode(data) as Map<String, dynamic> : data as Map<String, dynamic>;
      final typeStr = msg['type'] as String? ?? '';
      final type = _parseType(typeStr);
      _messageController.add(WsMessage(type: type, data: msg));
    } catch (_) {}
  }

  WsMessageType _parseType(String type) {
    switch (type) {
      case 'init':
        return WsMessageType.init;
      case 'network_update':
        return WsMessageType.networkUpdate;
      case 'device_update':
        return WsMessageType.deviceUpdate;
      case 'device_added':
        return WsMessageType.deviceAdded;
      case 'device_removed':
        return WsMessageType.deviceRemoved;
      case 'blackout':
        return WsMessageType.blackout;
      case 'restore':
        return WsMessageType.restore;
      case 'system_reset':
        return WsMessageType.systemReset;
      case 'settings_update':
        return WsMessageType.settingsUpdate;
      case 'pong':
        return WsMessageType.pong;
      case 'dashboard_tick':
        return WsMessageType.dashboardTick;
      default:
        return WsMessageType.unknown;
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      try {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      } catch (_) {}
    });
  }

  void _handleDisconnect() {
    _state = ConnectionState.disconnected;
    _stateController.add(_state);
    _pingTimer?.cancel();
    if (!_disposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_disposed) {
        connect();
      }
    });
  }

  void send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _state = ConnectionState.disconnected;
    _stateController.add(_state);
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}
