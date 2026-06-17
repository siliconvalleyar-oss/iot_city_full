class RevenuePoint {
  final String label;
  final double value;
  final bool isHighlighted;

  RevenuePoint({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });
}

class SalesData {
  final String label;
  final double value;

  SalesData({required this.label, required this.value});
}

class CircularMetric {
  final String label;
  final double value;
  final double maxValue;
  final String unit;
  final ColorType colorType;

  CircularMetric({
    required this.label,
    required this.value,
    required this.maxValue,
    this.unit = '%',
    this.colorType = ColorType.primary,
  });

  double get percentage => (value / maxValue * 100).clamp(0, 100);

  bool get isAlert => colorType == ColorType.alert;
}

enum ColorType { primary, success, warning, alert, info }

class ActivityMetrics {
  final String name;
  final IconType icon;
  final int durationMinutes;
  final int calories;
  final double avgSpeedKmh;
  final int heartRateBpm;
  final bool isSelected;

  ActivityMetrics({
    required this.name,
    required this.icon,
    required this.durationMinutes,
    required this.calories,
    required this.avgSpeedKmh,
    required this.heartRateBpm,
    this.isSelected = false,
  });
}

enum IconType { yoga, running, cycling, swimming }

class DashboardSummary {
  final double totalRevenue;
  final double totalSales;
  final double salesTarget;
  final int successfulTransactions;
  final int totalTransactions;
  final double returningCustomerRate;
  final double salesProgress;
  final List<RevenuePoint> revenuePoints;
  final List<SalesData> salesData;
  final List<CircularMetric> circularMetrics;
  final List<ActivityMetrics> activities;

  DashboardSummary({
    required this.totalRevenue,
    required this.totalSales,
    required this.salesTarget,
    required this.successfulTransactions,
    required this.totalTransactions,
    required this.returningCustomerRate,
    required this.salesProgress,
    required this.revenuePoints,
    required this.salesData,
    required this.circularMetrics,
    required this.activities,
  });

  double get transactionRate =>
      totalTransactions > 0
          ? (successfulTransactions / totalTransactions) * 100
          : 0;

  double get billingEstimate => totalRevenue * 1.15;
  double get previousPeriodRevenue => totalRevenue * 0.78;
  double get revenueGrowth =>
      previousPeriodRevenue > 0
          ? ((totalRevenue - previousPeriodRevenue) / previousPeriodRevenue) *
              100
          : 0;
}
