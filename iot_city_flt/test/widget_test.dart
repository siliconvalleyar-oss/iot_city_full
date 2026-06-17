import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:iot_city_flt/app.dart';
import 'package:iot_city_flt/providers/dashboard_provider.dart';
import 'package:iot_city_flt/providers/theme_provider.dart';

void main() {
  testWidgets('Dashboard app loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const IotCityApp(),
      ),
    );

    // Verify the app title is present
    expect(find.text('IoT CITY'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
