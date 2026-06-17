import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/palettes.dart';
import '../../models/dashboard_metrics.dart';

class RevenueLineChart extends StatelessWidget {
  final List<RevenuePoint> data;
  final PaletteColors palette;

  const RevenueLineChart({
    super.key,
    required this.data,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final maxY = data.fold<double>(0, (a, b) => a > b.value ? a : b.value);
    final minY = data.fold<double>(double.infinity, (a, b) => a < b.value ? a : b.value);
    final padding = (maxY - minY) * 0.15;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 8, bottom: 4),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(500, double.infinity),
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
                interval: ((maxY - minY) / 4).clamp(500, double.infinity),
                getTitlesWidget: (value, meta) {
                  if (value == meta.min) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '\$${(value / 1000).toStringAsFixed(0)}k',
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
          minY: (minY - padding).clamp(0, double.infinity),
          maxY: maxY + padding,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                return LineTooltipItem(
                  '\$${spot.y.toStringAsFixed(0)}',
                  TextStyle(
                    color: palette.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) =>
                FlSpot(e.key.toDouble(), e.value.value)
              ).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: palette.accent,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isHighlighted = index < data.length && data[index].isHighlighted;
                  return FlDotCirclePainter(
                    radius: isHighlighted ? 5 : 2,
                    color: isHighlighted ? palette.accent : palette.bg3,
                    strokeWidth: isHighlighted ? 2 : 0,
                    strokeColor: palette.accent2,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: palette.accent.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }
}
