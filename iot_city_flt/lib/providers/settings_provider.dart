import 'package:flutter/material.dart';
import '../config/constants.dart';

class SettingsProvider extends ChangeNotifier {
  String _host = 'ms7851.local';
  int _port = AppConstants.defaultPort;

  String get host => _host;
  int get port => _port;
  String get apiUrl => AppConstants.apiUrl(_host, _port);
  String get baseUrl => AppConstants.baseUrl(_host, _port);
  String get wsUrl => AppConstants.wsUrl(_host, _port);
  String get dashboardWsUrl => AppConstants.dashboardWsUrl(_host, _port);

  void setHost(String host) {
    if (host != _host) {
      _host = host;
      notifyListeners();
    }
  }

  void setPort(int port) {
    if (port != _port) {
      _port = port;
      notifyListeners();
    }
  }
}
