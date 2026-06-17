import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/palettes.dart';
import '../../models/dashboard_metrics.dart';

class SalesBarChart extends StatelessWidget {
  final List<SalesData> data;
  final PaletteColors palette;

  const SalesBarChart({
    super.key,
    required this.data,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final maxY = data.fold<double>(0, (a, b) => a > b.value ? a : b.value);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 8, bottom: 4),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4).clamp(2000, double.infinity),
            getDrawingHorizontalLine: (value) => FlLine(
              color: palette.border.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (data.length / 6).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[i].label,
                      style: TextStyle(
                        color: palette.text2,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: (maxY / 4).clamp(2000, double.infinity),
                getTitlesWidget: (value, meta) {
                  if (value == meta.min) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '\$${(value / 1000).toStringAsFixed(1)}k',
                      style: TextStyle(
                        color: palette.text2,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          maxY: maxY * 1.12,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(0)}',
                  TextStyle(
                    color: palette.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: data.asMap().entries.map((e) {
            final isLast = e.key >= data.length - 2;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: isLast ? palette.accent : palette.accent.withValues(alpha: 0.5),
                  width: 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }
}
