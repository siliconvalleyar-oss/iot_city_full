import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String defaultHost = 'localhost';
  static const int defaultPort = 5062;

  static String get defaultBaseUrl => 'http://$defaultHost:$defaultPort';
  static String get defaultWsUrl => 'ws://$defaultHost:$defaultPort';

  static String baseUrl(String host, int port) => 'http://$host:$port';
  static String apiUrl(String host, int port) => 'http://$host:$port/api';
  static String wsUrl(String host, int port) => 'ws://$host:$port/ws';
  static String dashboardWsUrl(String host, int port) =>
      'ws://$host:$port/api/dashboard/ws';

  // Layout
  static const double cardPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double gridSpacing = 12.0;
  static const double contentPadding = 20.0;
  static const double kpiHeight = 120.0;
  static const double chartHeight = 220.0;
  static const double smallChartHeight = 150.0;

  // Animation
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 600);

  // Filter options
  static const List<String> timeFilters = ['Day', 'Week', 'Month', 'Semester'];

  // Activities
  static const List<Map<String, dynamic>> activities = [
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'color': Color(0xFF8855FF)},
    {'name': 'Running', 'icon': Icons.directions_run, 'color': Color(0xFFFF5533)},
    {'name': 'Cycling', 'icon': Icons.directions_bike, 'color': Color(0xFF33BBFF)},
    {'name': 'Swimming', 'icon': Icons.pool, 'color': Color(0xFF44DDBB)},
  ];
}
