import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/palettes.dart';
import '../../models/dashboard_metrics.dart';

class CircularGauge extends StatelessWidget {
  final CircularMetric metric;
  final PaletteColors palette;
  final double size;

  const CircularGauge({
    super.key,
    required this.metric,
    required this.palette,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final percentage = metric.percentage;

    return SizedBox(
      width: size,
      height: size + 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _GaugePainter(
                percentage: percentage,
                color: color,
                bgColor: palette.bg3,
                isAlert: metric.isAlert,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}${metric.unit}',
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      metric.value.toStringAsFixed(1),
                      style: TextStyle(
                        color: palette.text2,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.text2,
              fontSize: 9,
              height: 1.3,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (metric.colorType) {
      case ColorType.primary:
        return palette.accent;
      case ColorType.success:
        return palette.green;
      case ColorType.warning:
        return palette.amber;
      case ColorType.alert:
        return palette.red;
      case ColorType.info:
        return palette.purple;
    }
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;
  final bool isAlert;

  _GaugePainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
    this.isAlert = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;

    // Background arc
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Pulsing outer glow for alert
    if (isAlert) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8;

      canvas.drawCircle(center, radius, glowPaint);
    }

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * 2 * pi;
    const startAngle = -pi / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Small tick marks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = startAngle + (i / 12) * 2 * pi;
      final outer = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      final inner = Offset(
        center.dx + cos(angle) * (radius - 4),
        center.dy + sin(angle) * (radius - 4),
      );
      if (i / 12 * 100 <= percentage) {
        canvas.drawLine(inner, outer, tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
