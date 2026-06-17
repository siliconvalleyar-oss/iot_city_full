import 'package:flutter/material.dart';
import '../../config/palettes.dart';

class MetricCard extends StatefulWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final PaletteColors palette;
  final double? trend;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.palette,
    this.trend,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void didUpdateWidget(MetricCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.palette.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.palette.border.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: widget.palette.text2,
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(widget.icon, color: widget.accentColor, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.value,
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  height: 1.1,
                ),
              ),
              if (widget.subtitle != null || widget.trend != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (widget.trend != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          widget.trend! >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: widget.trend! >= 0
                              ? widget.palette.green
                              : widget.palette.red,
                          size: 14,
                        ),
                      ),
                    if (widget.subtitle != null)
                      Expanded(
                        child: Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: widget.palette.text2,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
