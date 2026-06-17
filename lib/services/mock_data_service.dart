import '../models/dashboard_metrics.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._();
  factory MockDataService() => _instance;
  MockDataService._();

  DashboardSummary generateSummary({String filter = 'Week'}) {
    int pointCount;
    switch (filter) {
      case 'Day':
        pointCount = 24;
        break;
      case 'Week':
        pointCount = 7;
        break;
      case 'Month':
        pointCount = 30;
        break;
      case 'Semester':
        pointCount = 6;
        break;
      default:
        pointCount = 7;
    }

    final revenuePoints = _generateRevenuePoints(pointCount, filter);
    final salesData = _generateSalesData(pointCount, filter);
    final totalRevenue = revenuePoints.fold<double>(0, (a, b) => a + b.value);
    final totalSales = salesData.fold<double>(0, (a, b) => a + b.value);

    return DashboardSummary(
      totalRevenue: totalRevenue,
      totalSales: totalSales,
      salesTarget: 35000,
      successfulTransactions: 342,
      totalTransactions: 400,
      returningCustomerRate: 0.68,
      salesProgress: (totalSales / 35000).clamp(0, 1),
      revenuePoints: revenuePoints,
      salesData: salesData,
      circularMetrics: _generateCircularMetrics(),
      activities: _generateActivities(),
    );
  }

  List<RevenuePoint> _generateRevenuePoints(int count, String filter) {
    final labels = _generateLabels(count, filter);
    return List.generate(count, (i) {
      final isWeekend = filter == 'Week' && (i == 5 || i == 6);
      final baseValue = isWeekend ? 4500.0 : 3000.0;
      final variance = (i * 0.7).floorToDouble();
      return RevenuePoint(
        label: labels[i],
        value: baseValue + variance * 100 + (i % 3) * 200,
        isHighlighted: i == count - 1 || i == count - 2,
      );
    });
  }

  List<SalesData> _generateSalesData(int count, String filter) {
    final labels = _generateLabels(count, filter);
    double cumulative = 0;
    return List.generate(count, (i) {
      cumulative += 1500 + (i * 300) % 2000 + (i % 4) * 500;
      return SalesData(label: labels[i], value: cumulative);
    });
  }

  List<String> _generateLabels(int count, String filter) {
    switch (filter) {
      case 'Day':
        return List.generate(count, (i) => '${i.toString().padLeft(2, '0')}:00');
      case 'Week':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Month':
        return List.generate(count, (i) => '${i + 1}');
      case 'Semester':
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      default:
        return List.generate(count, (i) => '$i');
    }
  }

  List<CircularMetric> _generateCircularMetrics() {
    return [
      CircularMetric(
        label: 'Successful\nTransactions',
        value: 85.5,
        maxValue: 100,
        unit: '%',
        colorType: ColorType.success,
      ),
      CircularMetric(
        label: 'Returning\nCustomer Rate',
        value: 68,
        maxValue: 100,
        unit: '%',
        colorType: ColorType.info,
      ),
      CircularMetric(
        label: 'Sales Target\nCompleted',
        value: 81,
        maxValue: 100,
        unit: '%',
        colorType: ColorType.alert,
      ),
    ];
  }

  List<ActivityMetrics> _generateActivities() {
    return [
      ActivityMetrics(
        name: 'Yoga',
        icon: IconType.yoga,
        durationMinutes: 45,
        calories: 320,
        avgSpeedKmh: 0,
        heartRateBpm: 98,
        isSelected: true,
      ),
      ActivityMetrics(
        name: 'Running',
        icon: IconType.running,
        durationMinutes: 30,
        calories: 450,
        avgSpeedKmh: 10.2,
        heartRateBpm: 155,
        isSelected: false,
      ),
      ActivityMetrics(
        name: 'Cycling',
        icon: IconType.cycling,
        durationMinutes: 60,
        calories: 520,
        avgSpeedKmh: 22.5,
        heartRateBpm: 135,
        isSelected: false,
      ),
    ];
  }
}
