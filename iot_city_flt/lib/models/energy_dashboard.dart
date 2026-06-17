class EnergySummary {
  final double timestamp;
  final int uptimeS;
  final int totalNodes;
  final double totalPowerMW;
  final double totalPowerW;
  final double totalEnergyMWh;
  final double estimatedDailyWh;
  final double avgEfficiencyScore;
  final List<List<dynamic>> topConsumers;
  final List<String> zones;

  EnergySummary({
    this.timestamp = 0,
    this.uptimeS = 0,
    this.totalNodes = 0,
    this.totalPowerMW = 0,
    this.totalPowerW = 0,
    this.totalEnergyMWh = 0,
    this.estimatedDailyWh = 0,
    this.avgEfficiencyScore = 0,
    this.topConsumers = const [],
    this.zones = const [],
  });

  factory EnergySummary.fromJson(Map<String, dynamic> json) {
    return EnergySummary(
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0,
      uptimeS: json['uptime_s'] as int? ?? 0,
      totalNodes: json['total_nodes'] as int? ?? 0,
      totalPowerMW: (json['total_power_mW'] as num?)?.toDouble() ?? 0,
      totalPowerW: (json['total_power_W'] as num?)?.toDouble() ?? 0,
      totalEnergyMWh: (json['total_energy_mWh'] as num?)?.toDouble() ?? 0,
      estimatedDailyWh: (json['estimated_daily_Wh'] as num?)?.toDouble() ?? 0,
      avgEfficiencyScore: (json['avg_efficiency_score'] as num?)?.toDouble() ?? 0,
      topConsumers: (json['top_consumers'] as List?)?.cast<List<dynamic>>() ?? [],
      zones: (json['zones'] as List?)?.cast<String>() ?? [],
    );
  }
}

class ZoneMetrics {
  final String zone;
  final int nodeCount;
  final double totalPowerMW;
  final double avgPowerPerNodeMW;
  final double totalEnergyMWh;
  final int activeNodes;
  final int totalPacketsTx;
  final double avgEfficiencyScore;

  ZoneMetrics({
    this.zone = '',
    this.nodeCount = 0,
    this.totalPowerMW = 0,
    this.avgPowerPerNodeMW = 0,
    this.totalEnergyMWh = 0,
    this.activeNodes = 0,
    this.totalPacketsTx = 0,
    this.avgEfficiencyScore = 0,
  });

  factory ZoneMetrics.fromJson(Map<String, dynamic> json) {
    return ZoneMetrics(
      zone: json['zone'] as String? ?? '',
      nodeCount: json['node_count'] as int? ?? 0,
      totalPowerMW: (json['total_power_mW'] as num?)?.toDouble() ?? 0,
      avgPowerPerNodeMW: (json['avg_power_per_node_mW'] as num?)?.toDouble() ?? 0,
      totalEnergyMWh: (json['total_energy_mWh'] as num?)?.toDouble() ?? 0,
      activeNodes: json['active_nodes'] as int? ?? 0,
      totalPacketsTx: json['total_packets_tx'] as int? ?? 0,
      avgEfficiencyScore: (json['avg_efficiency_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GlobalTimeSample {
  final double ts;
  final String dt;
  final double totalPowerMW;
  final double totalPowerW;
  final int activeNodes;
  final int totalNodes;

  GlobalTimeSample({
    this.ts = 0,
    this.dt = '',
    this.totalPowerMW = 0,
    this.totalPowerW = 0,
    this.activeNodes = 0,
    this.totalNodes = 0,
  });

  factory GlobalTimeSample.fromJson(Map<String, dynamic> json) {
    return GlobalTimeSample(
      ts: (json['ts'] as num?)?.toDouble() ?? 0,
      dt: json['dt'] as String? ?? '',
      totalPowerMW: (json['total_power_mW'] as num?)?.toDouble() ?? 0,
      totalPowerW: (json['total_power_W'] as num?)?.toDouble() ?? 0,
      activeNodes: json['active_nodes'] as int? ?? 0,
      totalNodes: json['total_nodes'] as int? ?? 0,
    );
  }
}

class TrafficMetrics {
  final String nodeId;
  final String zone;
  final double txRatePps;
  final int totalTx;
  final int totalRx;
  final double linkUtilization;

  TrafficMetrics({
    this.nodeId = '',
    this.zone = '',
    this.txRatePps = 0,
    this.totalTx = 0,
    this.totalRx = 0,
    this.linkUtilization = 0,
  });

  factory TrafficMetrics.fromJson(Map<String, dynamic> json) {
    return TrafficMetrics(
      nodeId: json['node_id'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      txRatePps: (json['tx_rate_pps'] as num?)?.toDouble() ?? 0,
      totalTx: json['total_tx'] as int? ?? 0,
      totalRx: json['total_rx'] as int? ?? 0,
      linkUtilization: (json['link_utilization'] as num?)?.toDouble() ?? 0,
    );
  }
}
