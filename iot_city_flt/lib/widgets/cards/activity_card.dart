import 'package:flutter/material.dart';
import '../../config/palettes.dart';
import '../../models/dashboard_metrics.dart';

class ActivityCard extends StatelessWidget {
  final ActivityMetrics activity;
  final PaletteColors palette;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.palette,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (activity.icon) {
      case IconType.yoga:
        return Icons.self_improvement;
      case IconType.running:
        return Icons.directions_run;
      case IconType.cycling:
        return Icons.directions_bike;
      case IconType.swimming:
        return Icons.pool;
    }
  }

  Color _getIconColor() {
    switch (activity.icon) {
      case IconType.yoga:
        return const Color(0xFF8855FF);
      case IconType.running:
        return const Color(0xFFFF5533);
      case IconType.cycling:
        return const Color(0xFF33BBFF);
      case IconType.swimming:
        return const Color(0xFF44DDBB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: activity.isSelected
              ? iconColor.withValues(alpha: 0.12)
              : palette.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activity.isSelected
                ? iconColor.withValues(alpha: 0.5)
                : palette.border.withValues(alpha: 0.3),
            width: activity.isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), color: iconColor, size: 22),
            const SizedBox(width: 10),
            Text(
              activity.name,
              style: TextStyle(
                color: activity.isSelected ? palette.text : palette.text2,
                fontSize: 12,
                fontWeight: activity.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (activity.isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 8,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
