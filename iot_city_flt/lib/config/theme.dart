import 'package:flutter/material.dart';
import 'palettes.dart';

class AppTheme {
  static ThemeData fromPalette(PaletteColors palette) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.bg,
      colorScheme: ColorScheme.dark(
        primary: palette.accent,
        secondary: palette.accent2,
        surface: palette.panel,
        error: palette.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: palette.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.border.withValues(alpha: 0.5)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border.withValues(alpha: 0.5),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.panel,
        contentTextStyle: TextStyle(color: palette.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}
