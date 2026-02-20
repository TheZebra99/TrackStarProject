import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  bool _darkMode    = false;
  bool _largeText   = false;
  bool _highContrast = false;
  int  _userId      = 0; // 0 = no user loaded yet

  bool get darkMode     => _darkMode;
  bool get largeText    => _largeText;
  bool get highContrast => _highContrast;

  /// Call this right after a successful login or signup.
  /// Loads the settings that were last saved for this specific user.
  Future<void> loadForUser(int userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    _darkMode     = prefs.getBool('darkMode_$userId')     ?? false;
    _largeText    = prefs.getBool('largeText_$userId')    ?? false;
    _highContrast = prefs.getBool('highContrast_$userId') ?? false;
    notifyListeners();
  }

  /// Call this on logout so the app returns to neutral defaults
  /// before the next user logs in.
  void resetToDefaults() {
    _userId       = 0;
    _darkMode     = false;
    _largeText    = false;
    _highContrast = false;
    notifyListeners();
  }

  set darkMode(bool value) {
    _darkMode = value;
    notifyListeners();
    if (_userId != 0) {
      SharedPreferences.getInstance()
          .then((p) => p.setBool('darkMode_$_userId', value));
    }
  }

  set largeText(bool value) {
    _largeText = value;
    notifyListeners();
    if (_userId != 0) {
      SharedPreferences.getInstance()
          .then((p) => p.setBool('largeText_$_userId', value));
    }
  }

  set highContrast(bool value) {
    _highContrast = value;
    notifyListeners();
    if (_userId != 0) {
      SharedPreferences.getInstance()
          .then((p) => p.setBool('highContrast_$_userId', value));
    }
  }

  ThemeMode get themeMode =>
      _darkMode ? ThemeMode.dark : ThemeMode.light;

  double get textScaleFactor => _largeText ? 1.2 : 1.0;
}