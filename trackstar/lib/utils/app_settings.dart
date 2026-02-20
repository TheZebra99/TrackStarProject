import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  // Singleton pattern for settings, rebuild MaterialApp theme whenever a setting changes
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  bool _darkMode = false;
  bool _largeText = false;
  bool _highContrast = false;

  bool get darkMode => _darkMode;
  bool get largeText => _largeText;
  bool get highContrast => _highContrast;

  set darkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }

  set largeText(bool value) {
    _largeText = value;
    notifyListeners();
  }

  set highContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  ThemeMode get themeMode =>
      _darkMode ? ThemeMode.dark : ThemeMode.light;

  /// Text scale factor applied via [MediaQuery] wrapper in main.dart.
  double get textScaleFactor => _largeText ? 1.2 : 1.0;
}