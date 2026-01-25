import 'package:flutter/material.dart';

class AppColors {
  // --- PRIMARY COLOR PALETTE ---
  // Royal Blue (Default)
  static const Color primaryBlue = Color(0xFF0066FF);
  // Rose / Pink
  static const Color primaryRose = Color(0xFFE91E63);
  // Green
  static const Color primaryGreen = Color(0xFF00C853);
  // Yellow / Amber (Gold)
  static const Color primaryYellow = Color(0xFFFFC107);
  // Purple
  static const Color primaryPurple = Color(0xFF9C27B0);
  
  // Default pointers (will be used by static references before theme service takes over if needed, 
  // though Theme.of(context).primaryColor is preferred in UI)
  static const Color primary = primaryBlue; 
  static const Color primaryDark = Color(0xFF0052CC);
  static const Color primaryLight = Color(0xFFE5F0FF);
  
  // --- DARK THEME SPECIFIC ---
  static const Color darkBackground = Color(0xFF18181B); // Very dark grey, almost black
  static const Color darkSurface = Color(0xFF27272A); // Slightly lighter for cards
  
  // In dark mode, we often use the primary color as the accent/highlight.
  // The user requested: rose, blue, green, yellow, purple support.
  // So "darkPrimary" shouldn't be hardcoded to Gold anymore, it should follow the selected theme color.
  // However, for backward compatibility or default Gold look from screenshot:
  static const Color defaultDarkPrimary = Color(0xFFFFD700); // Gold/Yellow
  
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  
  // --- COMMON COLORS ---
  static const Color accent = Color(0xFFFFC107); // Amber for alerts/status
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);

  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}
