import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../models/energy_dashboard.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  String get _apiUrl => '$baseUrl/api';

  Future<List<Device>> getDevices() async {
    final res = await _client.get(Uri.parse('$_apiUrl/devices'));
    if (res.statusCode != 200) throw Exception('Error fetching devices: ${res.statusCode}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['devices'] as List<dynamic>;
    return list.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Device> getDevice(String id) async {
    final res = await _client.get(Uri.parse('$_apiUrl/devices/$id'));
    if (res.statusCode != 200) throw Exception('Error fetching device $id: ${res.statusCode}');
    return Device.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<DeviceMetrics> getMetrics() async {
    final res = await _client.get(Uri.parse('$_apiUrl/metrics'));
    if (res.statusCode != 200) throw Exception('Error fetching metrics: ${res.statusCode}');
    return DeviceMetrics.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<EnergySummary> getDashboardSummary() async {
    final res = await _client.get(Uri.parse('$_apiUrl/dashboard/summary'));
    if (res.statusCode != 200) {
      if (res.statusCode == 503) {
        return EnergySummary();
      }
      throw Exception('Error fetching dashboard summary: ${res.statusCode}');
    }
    return EnergySummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Map<String, ZoneMetrics>> getZones() async {
    final res = await _client.get(Uri.parse('$_apiUrl/dashboard/zones'));
    if (res.statusCode != 200) {
      if (res.statusCode == 503) return {};
      throw Exception('Error fetching zones: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final zones = body['zones'] as Map<String, dynamic>;
    return zones.map((k, v) => MapEntry(k, ZoneMetrics.fromJson(v as Map<String, dynamic>)));
  }

  Future<List<GlobalTimeSample>> getGlobalTimeseries({int lastN = 60}) async {
    final res = await _client.get(Uri.parse('$_apiUrl/dashboard/timeseries/global?last_n=$lastN'));
    if (res.statusCode != 200) {
      if (res.statusCode == 503) return [];
      throw Exception('Error fetching timeseries: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['timeseries'] as List<dynamic>;
    return list.map((e) => GlobalTimeSample.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, TrafficMetrics>> getTraffic() async {
    final res = await _client.get(Uri.parse('$_apiUrl/dashboard/traffic'));
    if (res.statusCode != 200) {
      if (res.statusCode == 503) return {};
      throw Exception('Error fetching traffic: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final traffic = body['traffic'] as Map<String, dynamic>;
    return traffic.map((k, v) => MapEntry(k, TrafficMetrics.fromJson(v as Map<String, dynamic>)));
  }

  Future<Device> toggleDevice(String id) async {
    final res = await _client.post(Uri.parse('$_apiUrl/devices/$id/toggle'));
    if (res.statusCode != 200) throw Exception('Error toggling device $id: ${res.statusCode}');
    return Device.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Device> togglePower(String id) async {
    final res = await _client.post(Uri.parse('$_apiUrl/devices/$id/power'));
    if (res.statusCode != 200) throw Exception('Error toggling power $id: ${res.statusCode}');
    return Device.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() {
    _client.close();
  }
}
