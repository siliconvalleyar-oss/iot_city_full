import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/device.dart';

class CityMapPainter extends CustomPainter {
  final List<Device> devices;
  final String? selectedDeviceId;
  final double zoom;
  final Offset pan;
  final bool showMesh;
  final bool showLabels;
  final bool showCoverage;

  CityMapPainter({
    required this.devices,
    this.selectedDeviceId,
    this.zoom = 1.0,
    this.pan = Offset.zero,
    this.showMesh = true,
    this.showLabels = true,
    this.showCoverage = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    if (showMesh) _drawMeshConnections(canvas);
    if (showCoverage) _drawCoverageRings(canvas);
    _drawDevices(canvas);
  }

  Offset _worldToScreen(double wx, double wy) {
    return Offset(wx * zoom + pan.dx, wy * zoom + pan.dy);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x661A3A6B)
      ..strokeWidth = 1;

    const positions = [120, 235, 350, 465];
    for (final y in positions) {
      final s = _worldToScreen(0, y.toDouble());
      final e = _worldToScreen(800, y.toDouble());
      canvas.drawLine(s, e, paint);
    }
    for (final x in positions) {
      final s = _worldToScreen(x.toDouble(), 0);
      final e = _worldToScreen(x.toDouble(), 600);
      canvas.drawLine(s, e, paint);
    }
  }

  void _drawMeshConnections(Canvas canvas) {
    final seen = <String>{};
    final activePaint = Paint()
      ..color = const Color(0x590080FF)
      ..strokeWidth = 1.5 * zoom
      ..style = PaintingStyle.stroke;

    final inactivePaint = Paint()
      ..color = const Color(0x33556688)
      ..strokeWidth = 1 * zoom;

    final packetPaint = Paint()
      ..color = const Color(0xCC00D4FF)
      ..style = PaintingStyle.fill;

    final now = DateTime.now().millisecondsSinceEpoch;

    for (final dev in devices) {
      for (final nid in dev.connectedTo) {
        final key = [dev.id, nid]..sort();
        final keyStr = key.join('|');
        if (seen.contains(keyStr)) continue;
        seen.add(keyStr);

        final neighbor = devices.where((d) => d.id == nid).firstOrNull;
        if (neighbor == null) continue;

        final s = _worldToScreen(dev.x, dev.y);
        final e = _worldToScreen(neighbor.x, neighbor.y);

        final bothPowered = dev.powered && neighbor.powered;
        if (bothPowered) {
          canvas.save();
          final path = Path()..moveTo(s.dx, s.dy)..lineTo(e.dx, e.dy);
          final dashEffect = DashPathEffect([6 * zoom, 4 * zoom]);
          dashEffect.paint(canvas, path, activePaint);
          canvas.restore();

          if (dev.deviceType == 'router') {
            final t = (now / 1500) % 1000 / 1000;
            final px = s.dx + (e.dx - s.dx) * t;
            final py = s.dy + (e.dy - s.dy) * t;
            canvas.drawCircle(Offset(px, py), 3 * zoom, packetPaint);
          }
        } else {
          canvas.drawLine(s, e, inactivePaint);
        }
      }
    }
  }

  void _drawCoverageRings(Canvas canvas) {
    for (final dev in devices) {
      if (!dev.powered || dev.deviceType != 'router') continue;
      final s = _worldToScreen(dev.x, dev.y);
      final r = 80 * zoom;

      final gradient = RadialGradient(
        colors: [
          const Color(0x140080FF),
          const Color(0x000080FF),
        ],
      );
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: s, radius: r));
      canvas.drawCircle(s, r, paint);
    }
  }

  void _drawDevices(Canvas canvas) {
    for (final dev in devices) {
      final s = _worldToScreen(dev.x, dev.y);
      final isSelected = dev.id == selectedDeviceId;
      final r = (dev.deviceType == 'router' ? 14.0 : 10.0) * zoom;

      canvas.save();

      final color = _deviceColor(dev);
      final glowColor = _deviceGlow(dev);

      if (dev.powered) {
        final glowPaint = Paint()
          ..color = glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(s, r, glowPaint);
      }

      final fillPaint = Paint()..color = color;
      canvas.drawCircle(s, r, fillPaint);

      if (dev.deviceType == 'router') {
        final ringPaint = Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 * zoom;
        canvas.drawCircle(s, r + 3 * zoom, ringPaint);
      }

      if (isSelected) {
        final selPaint = Paint()
          ..color = const Color(0xCC00D4FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * zoom;
        canvas.drawCircle(s, r + 6 * zoom, selPaint);
      }

      final icon = _deviceIcon(dev.icon);
      if (icon != null) {
        final textPainter = TextPainter(
          text: TextSpan(text: icon, style: TextStyle(fontSize: max(10, r * 1.1))),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(s.dx - textPainter.width / 2, s.dy - textPainter.height / 2));
      }

      if (showLabels && zoom > 0.6) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: dev.id,
            style: TextStyle(
              color: const Color(0xE6C8D8F0),
              fontSize: max(8, 10 * zoom),
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(canvas, Offset(s.dx - labelPainter.width / 2, s.dy + r + 3 * zoom));
      }

      canvas.restore();
    }
  }

  Color _deviceColor(Device dev) {
    if (!dev.powered) return const Color(0xFF556688);
    if (!dev.active) return const Color(0xFFFF3344);
    if (dev.level < 50) return const Color(0xFFFFAA00);
    return const Color(0xFF00FF88);
  }

  Color _deviceGlow(Device dev) {
    if (!dev.powered) return const Color(0x4D556688);
    if (!dev.active) return const Color(0x66FF3344);
    if (dev.level < 50) return const Color(0x66FFAA00);
    return const Color(0x6600FF88);
  }

  String? _deviceIcon(String icon) {
    switch (icon) {
      case 'lamp': return '💡';
      case 'traffic': return '🚦';
      case 'sensor': return '📡';
      case 'camera': return '📷';
      case 'gateway': return '🔌';
      case 'sign': return '⚠️';
      default: return '💡';
    }
  }

  Device? deviceAt(Offset position) {
    for (final dev in devices.reversed) {
      final s = _worldToScreen(dev.x, dev.y);
      final r = (dev.deviceType == 'router' ? 14.0 : 10.0) * zoom;
      if ((position - s).distance <= r + 6 * zoom) return dev;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant CityMapPainter oldDelegate) =>
      oldDelegate.devices != devices ||
      oldDelegate.zoom != zoom ||
      oldDelegate.pan != pan ||
      oldDelegate.selectedDeviceId != selectedDeviceId;
}

class DashPathEffect {
  final List<double> pattern;

  DashPathEffect(this.pattern);

  void paint(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final len = pattern[patternIndex % pattern.length];
        final end = min(distance + len, metric.length);

        if (draw) {
          final segment = metric.extractPath(distance, end);
          canvas.drawPath(segment, paint);
        }

        distance = end;
        draw = !draw;
        patternIndex++;
      }
    }
  }
}
