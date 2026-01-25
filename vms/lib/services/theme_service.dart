import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color'; // New key for color

  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = AppColors.primaryBlue; // Default Blue

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Mode
    final String? themeStr = prefs.getString(_themeModeKey);
    if (themeStr != null) {
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    // Load Color
    final int? colorValue = prefs.getInt(_themeColorKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    await prefs.setString(_themeModeKey, modeStr);
  }
  
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeColorKey, color.value);
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
