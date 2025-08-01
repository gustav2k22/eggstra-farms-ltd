import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Farm/Agricultural Theme
  static const Color primary = Color(0xFF2E7D32); // Deep Green
  static const Color primaryLight = Color(0xFF4CAF50); // Light Green
  static const Color primaryDark = Color(0xFF1B5E20); // Dark Green
  static const Color primaryVariant = Color(0xFF66BB6A); // Green Variant
  
  // Secondary Colors - Warm Earth Tones
  static const Color secondary = Color(0xFFFF8F00); // Orange
  static const Color secondaryLight = Color(0xFFFFA726); // Light Orange
  static const Color secondaryDark = Color(0xFFE65100); // Dark Orange
  static const Color secondaryVariant = Color(0xFFFFB74D); // Orange Variant
  
  // Accent Colors
  static const Color accent = Color(0xFFFFC107); // Amber
  static const Color accentLight = Color(0xFFFFD54F); // Light Amber
  static const Color accentDark = Color(0xFFFF8F00); // Dark Amber
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA); // Light Gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Light Surface
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color textSecondary = Color(0xFF757575); // Medium Gray
  static const Color textHint = Color(0xFFBDBDBD); // Light Gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  static const Color textOnSecondary = Color(0xFF000000); // Black
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  
  // Gray Scale
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
  
  // Special Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0xFFE0E0E0);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Card Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x0F000000);
  
  // Button Colors
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonTextDisabled = Color(0xFF9E9E9E);
  
  // Input Colors
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFocused = primary;
  static const Color inputError = error;
  static const Color inputBackground = Color(0xFFFAFAFA);
  static const Color inputFill = Color(0xFFFAFAFA); // Alias for inputBackground
  
  // Product Category Colors
  static const Map<String, Color> categoryColors = {
    'Eggs': Color(0xFFFFF3E0),
    'Poultry': Color(0xFFE8F5E8),
    'Dairy': Color(0xFFE3F2FD),
    'Vegetables': Color(0xFFE8F5E8),
    'Fruits': Color(0xFFFFF3E0),
    'Grains': Color(0xFFF3E5F5),
    'Organic': Color(0xFFE0F2F1),
    'Fresh Produce': Color(0xFFF1F8E9),
  };
  
  // Order Status Colors
  static const Map<String, Color> orderStatusColors = {
    'pending': Color(0xFFFFF3E0),
    'confirmed': Color(0xFFE3F2FD),
    'processing': Color(0xFFE8F5E8),
    'shipped': Color(0xFFF3E5F5),
    'delivered': Color(0xFFE0F2F1),
    'cancelled': Color(0xFFFFEBEE),
  };
}
