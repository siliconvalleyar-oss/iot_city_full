import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';

class IotCityApp extends StatelessWidget {
  const IotCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().currentPalette;

    return MaterialApp(
      title: 'IoT City Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromPalette(palette),
      home: const DashboardScreen(),
    );
  }
}
