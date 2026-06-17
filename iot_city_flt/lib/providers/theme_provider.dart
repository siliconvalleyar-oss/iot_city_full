import 'package:flutter/material.dart';
import '../config/palettes.dart';

class ThemeProvider extends ChangeNotifier {
  PaletteColors _currentPalette = PaletteColors.allPalettes.firstWhere(
    (p) => p.name == 'Black Flame',
  );
  int _currentIndex = 7; // Black Flame index

  PaletteColors get currentPalette => _currentPalette;
  int get currentIndex => _currentIndex;
  List<PaletteColors> get allPalettes => PaletteColors.allPalettes;

  void setPalette(int index) {
    if (index < 0 || index >= PaletteColors.allPalettes.length) return;
    _currentIndex = index;
    _currentPalette = PaletteColors.allPalettes[index];
    notifyListeners();
  }
}
