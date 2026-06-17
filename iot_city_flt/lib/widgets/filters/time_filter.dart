import 'package:flutter/material.dart';
import '../../config/palettes.dart';
import '../../config/constants.dart';

class TimeFilter extends StatelessWidget {
  final String currentFilter;
  final PaletteColors palette;
  final ValueChanged<String> onFilterChanged;

  const TimeFilter({
    super.key,
    required this.currentFilter,
    required this.palette,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.timeFilters.map((filter) {
        final isSelected = filter == currentFilter;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => onFilterChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.accent2
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? palette.accent2
                        : palette.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : palette.text2,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
