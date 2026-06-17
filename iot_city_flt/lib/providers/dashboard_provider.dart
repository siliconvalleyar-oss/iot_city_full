import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/energy_dashboard.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart' as ws;

class DashboardProvider extends ChangeNotifier {
  ApiService? _api;
  ws.WebSocketService? _wsService;

  List<Device> _devices = [];
  DeviceMetrics _metrics = DeviceMetrics();
  EnergySummary _energySummary = EnergySummary();
  Map<String, ZoneMetrics> _zones = {};
  List<GlobalTimeSample> _timeseries = [];
  Map<String, TrafficMetrics> _traffic = {};

  bool _isLoading = false;
  String? _error;
  ws.ConnectionState _wsState = ws.ConnectionState.disconnected;
  StreamSubscription<ws.WsMessage>? _wsSub;
  StreamSubscription<ws.ConnectionState>? _stateSub;

  List<Device> get devices => _devices;
  DeviceMetrics get metrics => _metrics;
  EnergySummary get energySummary => _energySummary;
  Map<String, ZoneMetrics> get zones => _zones;
  List<GlobalTimeSample> get timeseries => _timeseries;
  Map<String, TrafficMetrics> get traffic => _traffic;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ws.ConnectionState get wsState => _wsState;
  bool get isConnected => _wsState == ws.ConnectionState.connected;

  void connect({required String apiUrl, required String wsUrl}) {
    disconnect();
    _api = ApiService(baseUrl: apiUrl.replaceAll('/api', ''));
    _wsService = ws.WebSocketService(url: wsUrl);
    _setupWsListeners();
    _wsService!.connect();
    loadData();
  }

  void _setupWsListeners() {
    _stateSub = _wsService!.stateStream.listen((state) {
      _wsState = state;
      notifyListeners();
    });
    _wsSub = _wsService!.messages.listen((msg) {
      _handleWsMessage(msg);
    });
  }

  void _handleWsMessage(ws.WsMessage msg) {
    switch (msg.type) {
      case ws.WsMessageType.init:
        final devicesList = msg.data['devices'] as Map<String, dynamic>?;
        if (devicesList != null) {
          _devices = devicesList.values
              .map((e) => Device.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        final metricsData = msg.data['metrics'] as Map<String, dynamic>?;
        if (metricsData != null) {
          _metrics = DeviceMetrics.fromJson(metricsData);
        }
        notifyListeners();
      case ws.WsMessageType.networkUpdate:
        final devicesList = msg.data['devices'] as Map<String, dynamic>?;
        if (devicesList != null) {
          _devices = devicesList.values
              .map((e) => Device.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        final metricsData = msg.data['metrics'] as Map<String, dynamic>?;
        if (metricsData != null) {
          _metrics = DeviceMetrics.fromJson(metricsData);
        }
        notifyListeners();
      case ws.WsMessageType.deviceUpdate:
        final deviceData = msg.data['device'] as Map<String, dynamic>?;
        if (deviceData != null) {
          final updated = Device.fromJson(deviceData);
          final index = _devices.indexWhere((d) => d.id == updated.id);
          if (index >= 0) {
            _devices[index] = updated;
          } else {
            _devices.add(updated);
          }
          notifyListeners();
        }
      case ws.WsMessageType.deviceAdded:
        final deviceData = msg.data['device'] as Map<String, dynamic>?;
        if (deviceData != null) {
          _devices.add(Device.fromJson(deviceData));
          notifyListeners();
        }
      case ws.WsMessageType.deviceRemoved:
        final id = msg.data['device_id'] as String?;
        if (id != null) {
          _devices.removeWhere((d) => d.id == id);
          notifyListeners();
        }
      case ws.WsMessageType.blackout:
        for (final d in _devices) {
          d.powered = false;
          d.active = false;
        }
        notifyListeners();
      case ws.WsMessageType.restore:
        for (final d in _devices) {
          d.powered = true;
          d.active = true;
        }
        notifyListeners();
      case ws.WsMessageType.dashboardTick:
        final global = msg.data['global'] as Map<String, dynamic>?;
        if (global != null) {
          _energySummary = EnergySummary.fromJson(global);
        }
        final zonesData = msg.data['zones'] as Map<String, dynamic>?;
        if (zonesData != null) {
          _zones = zonesData.map(
            (k, v) => MapEntry(k, ZoneMetrics.fromJson(v as Map<String, dynamic>)),
          );
        }
        final summaryData = msg.data['summary'] as Map<String, dynamic>?;
        if (summaryData != null) {
          _energySummary = EnergySummary.fromJson(summaryData);
        }
        notifyListeners();
      default:
        break;
    }
  }

  Future<void> loadData() async {
    if (_api == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api!.getDevices(),
        _api!.getMetrics(),
        _api!.getDashboardSummary(),
        _api!.getZones(),
        _api!.getGlobalTimeseries(),
        _api!.getTraffic(),
      ], eagerError: false);

      _devices = results[0] as List<Device>;
      _metrics = results[1] as DeviceMetrics;
      _energySummary = results[2] as EnergySummary;
      _zones = results[3] as Map<String, ZoneMetrics>;
      _timeseries = results[4] as List<GlobalTimeSample>;
      _traffic = results[5] as Map<String, TrafficMetrics>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleDevice(String id) async {
    try {
      final updated = await _api!.toggleDevice(id);
      final index = _devices.indexWhere((d) => d.id == id);
      if (index >= 0) {
        _devices[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> togglePower(String id) async {
    try {
      final updated = await _api!.togglePower(id);
      final index = _devices.indexWhere((d) => d.id == id);
      if (index >= 0) {
        _devices[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void disconnect() {
    _wsSub?.cancel();
    _stateSub?.cancel();
    _wsService?.dispose();
    _wsService = null;
    _api?.dispose();
    _api = null;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
