class Device {
  final String id;
  final String deviceType;
  final double x;
  final double y;
  final String street;
  bool active;
  bool powered;
  double level;
  double consumption;
  double signal;
  final List<String> connectedTo;
  final List<String> endDevices;
  final String icon;
  final String color;
  double lastSeen;
  int packetsSent;
  int packetsReceived;

  Device({
    required this.id,
    required this.deviceType,
    required this.x,
    required this.y,
    required this.street,
    this.active = true,
    this.powered = true,
    this.level = 100,
    this.consumption = 0,
    this.signal = -70,
    this.connectedTo = const [],
    this.endDevices = const [],
    this.icon = 'lamp',
    this.color = '#FFD700',
    this.lastSeen = 0,
    this.packetsSent = 0,
    this.packetsReceived = 0,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String? ?? '',
      deviceType: json['device_type'] as String? ?? 'router',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      street: json['street'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      powered: json['powered'] as bool? ?? true,
      level: (json['level'] as num?)?.toDouble() ?? 100,
      consumption: (json['consumption'] as num?)?.toDouble() ?? 0,
      signal: (json['signal'] as num?)?.toDouble() ?? -70,
      connectedTo: (json['connected_to'] as List?)?.cast<String>() ?? [],
      endDevices: (json['end_devices'] as List?)?.cast<String>() ?? [],
      icon: json['icon'] as String? ?? 'lamp',
      color: json['color'] as String? ?? '#FFD700',
      lastSeen: (json['last_seen'] as num?)?.toDouble() ?? 0,
      packetsSent: json['packets_sent'] as int? ?? 0,
      packetsReceived: json['packets_received'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_type': deviceType,
    'x': x,
    'y': y,
    'street': street,
    'active': active,
    'powered': powered,
    'level': level,
    'consumption': consumption,
    'signal': signal,
    'connected_to': connectedTo,
    'end_devices': endDevices,
    'icon': icon,
    'color': color,
    'last_seen': lastSeen,
    'packets_sent': packetsSent,
    'packets_received': packetsReceived,
  };

  bool get isRouter => deviceType == 'router';
  bool get isEndDevice => deviceType == 'end_device';
  bool get isCamera => deviceType == 'camera';
}

class DeviceMetrics {
  final int totalDevices;
  final int powered;
  final int unpowered;
  final int active;
  final int inactive;
  final int routers;
  final int endDevices;
  final int cameras;
  final double totalConsumptionW;
  final double networkHealth;

  DeviceMetrics({
    this.totalDevices = 0,
    this.powered = 0,
    this.unpowered = 0,
    this.active = 0,
    this.inactive = 0,
    this.routers = 0,
    this.endDevices = 0,
    this.cameras = 0,
    this.totalConsumptionW = 0,
    this.networkHealth = 0,
  });

  factory DeviceMetrics.fromJson(Map<String, dynamic> json) {
    return DeviceMetrics(
      totalDevices: json['total_devices'] as int? ?? 0,
      powered: json['powered'] as int? ?? 0,
      unpowered: json['unpowered'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      inactive: json['inactive'] as int? ?? 0,
      routers: json['routers'] as int? ?? 0,
      endDevices: json['end_devices'] as int? ?? 0,
      cameras: json['cameras'] as int? ?? 0,
      totalConsumptionW: (json['total_consumption_w'] as num?)?.toDouble() ?? 0,
      networkHealth: (json['network_health'] as num?)?.toDouble() ?? 0,
    );
  }
}
