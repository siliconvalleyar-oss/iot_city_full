import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/palettes.dart';
import '../config/constants.dart';
import '../models/device.dart';
import '../models/energy_dashboard.dart';
import '../providers/dashboard_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/cards/metric_card.dart';
import '../widgets/charts/circular_gauge_widget.dart';
import '../widgets/map/device_map.dart';
import '../models/dashboard_metrics.dart' as mock;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late Animation<double> _bgAnim;
  String _viewMode = 'dashboard'; // 'dashboard' or 'map'

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgAnimController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      final dashboard = context.read<DashboardProvider>();
      if (!dashboard.isConnected) {
        dashboard.connect(
          apiUrl: settings.apiUrl,
          wsUrl: settings.wsUrl,
        );
      }
    });
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final palette = themeProvider.currentPalette;

    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.bg,
                Color.lerp(palette.bg, palette.bg2, _bgAnim.value)!,
                palette.bg2,
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: _viewMode == 'map'
                  ? _buildMapView(palette, dashboard)
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(palette, dashboard, themeProvider),
                        ),
                        SliverToBoxAdapter(
                          child: _buildKpiRow(palette, dashboard),
                        ),
                        SliverToBoxAdapter(
                          child: _buildChartsRow(palette, dashboard),
                        ),
                        SliverToBoxAdapter(
                          child: _buildGaugesRow(palette, dashboard),
                        ),
                        SliverToBoxAdapter(
                          child: _buildDeviceList(palette, dashboard),
                        ),
                        SliverToBoxAdapter(
                          child: _buildSystemInfo(palette, dashboard),
                        ),
                        SliverToBoxAdapter(
                          child: _buildTopology(palette, dashboard),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 32),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView(PaletteColors palette, DashboardProvider dashboard) {
    return Column(
      children: [
        _buildMapHeader(palette, dashboard),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: DeviceMap(
              devices: dashboard.devices,
              palette: palette,
              onDeviceTap: (device) => _showDeviceDetail(context, palette, device, dashboard),
              onToggle: (device) => dashboard.toggleDevice(device.id),
              onTogglePower: (device) => dashboard.togglePower(device.id),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapHeader(PaletteColors palette, DashboardProvider dashboard) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: dashboard.isConnected ? palette.green : palette.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'IoT CITY',
                    style: TextStyle(
                      color: palette.text2,
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MAP VIEW',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${dashboard.devices.length} devices',
                style: TextStyle(color: palette.text2, fontSize: 10, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _viewMode = 'dashboard'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.bg3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(Icons.dashboard_outlined, color: palette.text2, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showSettingsDialog(context, palette),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: palette.bg3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Icon(Icons.settings_outlined, color: palette.text2, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    PaletteColors palette,
    DashboardProvider dashboard,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: dashboard.isConnected ? palette.green : palette.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'IoT CITY',
                        style: TextStyle(
                          color: palette.text2,
                          fontSize: 10,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dashboard.isConnected ? 'CONNECTED' : 'DISCONNECTED',
                        style: TextStyle(
                          color: dashboard.isConnected ? palette.green : palette.red,
                          fontSize: 8,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Energy Dashboard',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  PopupMenuButton<int>(
                    offset: const Offset(0, 40),
                    color: palette.panel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: palette.border),
                    ),
                    onSelected: (index) => themeProvider.setPalette(index),
                    itemBuilder: (context) =>
                        List.generate(PaletteColors.allPalettes.length, (i) {
                      final p = PaletteColors.allPalettes[i];
                      return PopupMenuItem(
                        value: i,
                        child: Row(
                          children: [
                            Container(
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: palette.border),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              p.name,
                              style: TextStyle(
                                color: i == themeProvider.currentIndex
                                    ? palette.accent
                                    : palette.text,
                                fontSize: 12,
                                fontWeight: i == themeProvider.currentIndex
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (i == themeProvider.currentIndex) ...[
                              const Spacer(),
                              Icon(Icons.check, size: 14, color: palette.accent),
                            ],
                          ],
                        ),
                      );
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.bg3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(Icons.palette_outlined,
                          color: palette.text2, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _viewMode = _viewMode == 'dashboard' ? 'map' : 'dashboard'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.bg3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(
                        _viewMode == 'dashboard' ? Icons.map_outlined : Icons.dashboard_outlined,
                        color: palette.text2, size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showSettingsDialog(context, palette),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.bg3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(Icons.settings_outlined,
                          color: palette.text2, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(PaletteColors palette, DashboardProvider dashboard) {
    final m = dashboard.metrics;
    final devices = dashboard.devices;
    final activeCount = devices.where((d) => d.active && d.powered).length;
    final totalPower = m.totalConsumptionW;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 10.0;
          final cardWidth = (constraints.maxWidth - gap * 3) / 4;
          return Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: MetricCard(
                  label: 'Total Power',
                  value: '${totalPower.toStringAsFixed(1)}W',
                  subtitle: '${m.totalDevices} devices',
                  icon: Icons.bolt,
                  accentColor: palette.accent,
                  palette: palette,
                  trend: m.networkHealth - 50,
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: cardWidth,
                child: MetricCard(
                  label: 'Active',
                  value: '$activeCount/${m.totalDevices}',
                  subtitle: '${((activeCount / (m.totalDevices > 0 ? m.totalDevices : 1)) * 100).toStringAsFixed(0)}% online',
                  icon: Icons.wifi,
                  accentColor: palette.green,
                  palette: palette,
                  trend: m.networkHealth,
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: cardWidth,
                child: MetricCard(
                  label: 'Efficiency',
                  value: '${dashboard.energySummary.avgEfficiencyScore.toStringAsFixed(0)}%',
                  subtitle: 'Avg score',
                  icon: Icons.energy_savings_leaf,
                  accentColor: palette.purple,
                  palette: palette,
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: cardWidth,
                child: MetricCard(
                  label: 'Network Health',
                  value: '${m.networkHealth.toStringAsFixed(0)}%',
                  subtitle: '${m.routers}R / ${m.endDevices}E / ${m.cameras}C',
                  icon: Icons.monitor_heart_outlined,
                  accentColor: palette.amber,
                  palette: palette,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartsRow(PaletteColors palette, DashboardProvider dashboard) {
    final zones = dashboard.zones;
    final zoneNames = zones.keys.toList();
    final devices = dashboard.devices;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 12.0;
          final chartWidth = (constraints.maxWidth - gap) / 2;
          return Row(
            children: [
              SizedBox(
                width: chartWidth,
                child: _buildChartPanel(
                  palette: palette,
                  title: 'Zone Power',
                  badge: '${dashboard.energySummary.totalPowerW.toStringAsFixed(2)}W',
                  child: _buildZoneBarChart(palette, zones, zoneNames),
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: chartWidth,
                child: _buildChartPanel(
                  palette: palette,
                  title: 'Device Types',
                  badge: '${devices.length} total',
                  child: _buildDeviceTypeChart(palette, devices),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartPanel({
    required PaletteColors palette,
    required String title,
    required String badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: palette.text2,
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.bg3,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: AppConstants.chartHeight,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildZoneBarChart(
    PaletteColors palette,
    Map<String, ZoneMetrics> zones,
    List<String> zoneNames,
  ) {
    if (zoneNames.isEmpty) {
      return Center(
        child: Text('No zone data', style: TextStyle(color: palette.text2, fontSize: 11)),
      );
    }

    final colors = [palette.accent, palette.green, palette.amber, palette.purple];
    final maxPower = zones.values.fold<double>(
      0, (a, b) => a > b.totalPowerMW ? a : b.totalPowerMW,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: zoneNames.asMap().entries.map((entry) {
                final i = entry.key;
                final z = entry.value;
                final zm = zones[z]!;
                final height = maxPower > 0 ? (zm.totalPowerMW / maxPower) : 0.0;
                final color = colors[i % colors.length];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${zm.totalPowerMW.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: palette.text2,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: (AppConstants.chartHeight - 60) * height.clamp(0.05, 1.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          z.replaceFirst('zona-', ''),
                          style: TextStyle(
                            color: palette.text2,
                            fontSize: 8,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTypeChart(
    PaletteColors palette,
    List<Device> devices,
  ) {
    final routers = devices.where((d) => d.isRouter).length;
    final endDevices = devices.where((d) => d.isEndDevice).length;
    final cameras = devices.where((d) => d.isCamera).length;
    final total = devices.length;

    if (total == 0) {
      return Center(
        child: Text('No devices', style: TextStyle(color: palette.text2, fontSize: 11)),
      );
    }

    final items = [
      ('Router', routers, palette.accent),
      ('End Device', endDevices, palette.green),
      ('Camera', cameras, palette.amber),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.where((e) => e.$2 > 0).map((item) {
          final pct = (item.$2 / total * 100).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: item.$3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  item.$1,
                  style: TextStyle(color: palette.text2, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '${item.$2}',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      color: palette.text2,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGaugesRow(PaletteColors palette, DashboardProvider dashboard) {
    final summary = dashboard.energySummary;
    final metrics = dashboard.metrics;
    final activeCount = dashboard.devices.where((d) => d.active && d.powered).length;
    final totalCount = dashboard.devices.length;

    final gaugeMetrics = [
      mock.CircularMetric(
        label: 'Network\nEfficiency',
        value: summary.avgEfficiencyScore,
        maxValue: 100,
        unit: '%',
        colorType: summary.avgEfficiencyScore > 70
            ? mock.ColorType.success
            : summary.avgEfficiencyScore > 40
                ? mock.ColorType.warning
                : mock.ColorType.alert,
      ),
      mock.CircularMetric(
        label: 'Active\nDevices',
        value: activeCount.toDouble(),
        maxValue: totalCount > 0 ? totalCount.toDouble() : 1,
        unit: '%',
        colorType: activeCount > totalCount * 0.7
            ? mock.ColorType.success
            : mock.ColorType.warning,
      ),
      mock.CircularMetric(
        label: 'Network\nHealth',
        value: metrics.networkHealth,
        maxValue: 100,
        unit: '%',
        colorType: metrics.networkHealth > 70
            ? mock.ColorType.info
            : mock.ColorType.warning,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PERFORMANCE METRICS',
                  style: TextStyle(
                    color: palette.text2,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.bg3,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    'REAL-TIME',
                    style: TextStyle(
                      color: palette.green,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (gaugeMetrics.isEmpty)
              SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'Loading metrics...',
                    style: TextStyle(color: palette.text2, fontSize: 11),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: gaugeMetrics.map((m) {
                  return CircularGauge(
                    metric: m,
                    palette: palette,
                    size: 110,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(PaletteColors palette, DashboardProvider dashboard) {
    final devices = dashboard.devices;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DEVICES',
                  style: TextStyle(
                    color: palette.text2,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.devices, color: palette.text2, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            if (devices.isEmpty)
              SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    dashboard.isLoading ? 'Loading...' : 'No devices',
                    style: TextStyle(color: palette.text2, fontSize: 11),
                  ),
                ),
              )
            else
              ...devices.take(20).map((device) => _buildDeviceRow(palette, device, dashboard)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRow(PaletteColors palette, Device device, DashboardProvider dashboard) {
    final isOn = device.active && device.powered;
    return GestureDetector(
      onTap: () => _showDeviceDetail(context, palette, device, dashboard),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.bg3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOn ? palette.border : palette.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: isOn ? palette.green : palette.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.id,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  device.street,
                  style: TextStyle(color: palette.text2, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _deviceTypeColor(device.deviceType, palette).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                device.deviceType.replaceFirst('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: _deviceTypeColor(device.deviceType, palette),
                  fontSize: 8,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${device.consumption.toStringAsFixed(1)} mW',
              style: TextStyle(
                color: palette.text,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${device.signal.toStringAsFixed(0)} dBm',
              style: TextStyle(
                color: palette.text2,
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => dashboard.toggleDevice(device.id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.bg2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  device.active ? Icons.power_settings_new : Icons.power_off,
                  color: device.active ? palette.green : palette.red,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceDetail(BuildContext context, PaletteColors palette, Device device, DashboardProvider dashboard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: (device.active && device.powered) ? palette.green : palette.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        device.id,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          dashboard.togglePower(device.id);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.bg3,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.border),
                          ),
                          child: Icon(
                            device.powered ? Icons.bolt : Icons.bolt_outlined,
                            color: device.powered ? palette.amber : palette.red,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          dashboard.toggleDevice(device.id);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.bg3,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.border),
                          ),
                          child: Icon(
                            device.active ? Icons.power_settings_new : Icons.power_off,
                            color: device.active ? palette.green : palette.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _deviceTypeColor(device.deviceType, palette).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  device.deviceType.replaceFirst('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: _deviceTypeColor(device.deviceType, palette),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _detailItem(palette, 'Street', device.street),
                const SizedBox(width: 24),
                _detailItem(palette, 'Position', '(${device.x.toStringAsFixed(0)}, ${device.y.toStringAsFixed(0)})'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _detailItem(palette, 'Consumption', '${device.consumption.toStringAsFixed(1)} mW'),
                const SizedBox(width: 24),
                _detailItem(palette, 'Signal', '${device.signal.toStringAsFixed(1)} dBm'),
                const SizedBox(width: 24),
                _detailItem(palette, 'Level', '${device.level.toStringAsFixed(0)}%'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _detailItem(palette, 'Packets TX', '${device.packetsSent}'),
                const SizedBox(width: 24),
                _detailItem(palette, 'Packets RX', '${device.packetsReceived}'),
                const SizedBox(width: 24),
                _detailItem(palette, 'Last Seen', device.lastSeen > 0
                    ? '${DateTime.fromMillisecondsSinceEpoch((device.lastSeen * 1000).toInt()).difference(DateTime.now()).inMinutes.abs()}m ago'
                    : '---'),
              ]),
              if (device.connectedTo.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'CONNECTED TO',
                  style: TextStyle(color: palette.text2, fontSize: 8, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: device.connectedTo.map((nid) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(nid, style: TextStyle(color: palette.accent, fontSize: 10, fontFamily: 'monospace')),
                  )).toList(),
                ),
              ],
              if (device.endDevices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'END DEVICES',
                  style: TextStyle(color: palette.text2, fontSize: 8, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: device.endDevices.map((nid) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.green.withValues(alpha: 0.3)),
                    ),
                    child: Text(nid, style: TextStyle(color: palette.green, fontSize: 10, fontFamily: 'monospace')),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _detailItem(PaletteColors palette, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: palette.text2, fontSize: 8, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: palette.text, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace')),
      ],
    );
  }

  Color _deviceTypeColor(String type, PaletteColors palette) {
    switch (type) {
      case 'router':
        return palette.accent;
      case 'end_device':
        return palette.green;
      case 'camera':
        return palette.amber;
      default:
        return palette.text2;
    }
  }

  Widget _buildSystemInfo(PaletteColors palette, DashboardProvider dashboard) {
    final settings = context.watch<SettingsProvider>();
    final energy = dashboard.energySummary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SYSTEM INFO',
                  style: TextStyle(
                    color: palette.text2,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.info_outline, color: palette.text2, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(palette, 'Server', settings.host),
                const SizedBox(width: 20),
                _buildInfoItem(palette, 'Port', '${settings.port}'),
                const SizedBox(width: 20),
                _buildInfoItem(palette, 'Uptime', '${energy.uptimeS ~/ 3600}h ${(energy.uptimeS % 3600) ~/ 60}m'),
                const SizedBox(width: 20),
                _buildInfoItem(palette, 'Est. Daily', '${energy.estimatedDailyWh.toStringAsFixed(1)} Wh'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoItem(palette, 'Total Energy', '${energy.totalEnergyMWh.toStringAsFixed(1)} mWh'),
                const SizedBox(width: 20),
                _buildInfoItem(palette, 'Top Consumer', energy.topConsumers.isNotEmpty
                    ? '${energy.topConsumers.first[0]} (${energy.topConsumers.first[1]} mW)'
                    : '---'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopology(PaletteColors palette, DashboardProvider dashboard) {
    final devices = dashboard.devices;
    final routers = devices.where((d) => d.isRouter && d.powered).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MESH TOPOLOGY',
                  style: TextStyle(
                    color: palette.text2,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.hub, color: palette.text2, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            if (routers.isEmpty)
              SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    'No powered routers in mesh',
                    style: TextStyle(color: palette.text2, fontSize: 11),
                  ),
                ),
              )
            else
              ...routers.map((r) {
                final connections = r.connectedTo.where((nid) => devices.any((d) => d.id == nid && d.powered)).toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: palette.bg3,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: r.active ? palette.green : palette.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(r.id, style: TextStyle(color: palette.accent, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text('${r.consumption.toStringAsFixed(0)}mW', style: TextStyle(color: palette.text2, fontSize: 9, fontFamily: 'monospace')),
                      const Spacer(),
                      ...connections.map((nid) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(nid, style: TextStyle(color: palette.green, fontSize: 8, fontFamily: 'monospace')),
                        ),
                      )),
                      if (r.endDevices.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('+${r.endDevices.length}E', style: TextStyle(color: palette.amber, fontSize: 8, fontFamily: 'monospace')),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(PaletteColors palette, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: palette.text2,
            fontSize: 8,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: palette.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context, PaletteColors palette) {
    final settings = context.read<SettingsProvider>();
    final hostController = TextEditingController(text: settings.host);
    final portController = TextEditingController(text: settings.port.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.border),
        ),
        title: Text(
          'Connection Settings',
          style: TextStyle(color: palette.text, fontSize: 16),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                style: TextStyle(color: palette.text, fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Host',
                  labelStyle: TextStyle(color: palette.text2),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: palette.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: palette.accent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: palette.bg3,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                style: TextStyle(color: palette.text, fontFamily: 'monospace', fontSize: 13),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Port',
                  labelStyle: TextStyle(color: palette.text2),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: palette.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: palette.accent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: palette.bg3,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: palette.text2)),
          ),
          TextButton(
            onPressed: () {
              final host = hostController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 5062;
              settings.setHost(host);
              settings.setPort(port);
              Navigator.pop(ctx);
              final dashboard = context.read<DashboardProvider>();
              dashboard.connect(
                apiUrl: settings.apiUrl,
                wsUrl: settings.wsUrl,
              );
            },
            child: Text('Connect', style: TextStyle(color: palette.accent)),
          ),
        ],
      ),
    );
  }
}
