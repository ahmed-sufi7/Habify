import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeProvider extends ChangeNotifier {
  // Theme mode
  ThemeMode _themeMode = ThemeMode.system;
  
  // Primary colors from design system
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color secondaryBlue = Color(0xFF2196F3);
  static const Color accentPurple = Color(0xFF9C27B0);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFF3F4F6);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCardBackground = Color(0xFF262626);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkDivider = Color(0xFF2D2D2D);
  
  // Semantic colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Habit priority colors
  static const Color highPriorityColor = Color(0xFFE53E3E);
  static const Color mediumPriorityColor = Color(0xFFFF9800);
  static const Color lowPriorityColor = Color(0xFF4CAF50);
  
  // Streak colors
  static const Color streakFireColor = Color(0xFFFF4500);
  static const Color streakGoldColor = Color(0xFFFFD700);
  static const Color streakSilverColor = Color(0xFFC0C0C0);
  
  // Category colors (from design system)
  static const List<Color> categoryColors = [
    primaryOrange,
    primaryGreen,
    secondaryBlue,
    accentPurple,
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Amber
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF009688), // Teal
  ];
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  // Theme mode management
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _updateSystemUIOverlay();
      notifyListeners();
    }
  }
  
  void toggleTheme() {
    ThemeMode newMode;
    switch (_themeMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
    }
    setThemeMode(newMode);
  }
  
  // Light Theme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: lightBackground,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: primaryGreen,
        surface: lightSurface,
        background: lightBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
        onError: Colors.white,
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: lightBackground,
        foregroundColor: lightTextPrimary,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: lightCardBackground,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryOrange.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOrange,
          side: const BorderSide(color: primaryOrange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextSecondary),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCardBackground,
        selectedItemColor: primaryOrange,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return primaryOrange;
            }
            return Colors.grey;
          },
        ),
        trackColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return primaryOrange.withOpacity(0.3);
            }
            return Colors.grey.withOpacity(0.3);
          },
        ),
      ),
      
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return primaryOrange;
            }
            return Colors.transparent;
          },
        ),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        labelLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: lightTextSecondary),
        labelSmall: TextStyle(color: lightTextSecondary),
      ),
    );
  }
  
  // Dark Theme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: darkBackground,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: primaryGreen,
        surface: darkSurface,
        background: darkBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
        onError: Colors.white,
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryOrange.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOrange,
          side: const BorderSide(color: primaryOrange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCardBackground,
        selectedItemColor: primaryOrange,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return primaryOrange;
            }
            return Colors.grey;
          },
        ),
        trackColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return primaryOrange.withOpacity(0.3);
            }
            return Colors.grey.withOpacity(0.3);
          },
        ),
      ),
      
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return primaryOrange;
            }
            return Colors.transparent;
          },
        ),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextPrimary),
        bodySmall: TextStyle(color: darkTextSecondary),
        labelLarge: TextStyle(color: darkTextPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: darkTextSecondary),
        labelSmall: TextStyle(color: darkTextSecondary),
      ),
    );
  }
  
  // Utility methods
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return highPriorityColor;
      case 'medium':
        return mediumPriorityColor;
      case 'low':
        return lowPriorityColor;
      default:
        return mediumPriorityColor;
    }
  }
  
  Color getStreakColor(int streak) {
    if (streak >= 30) return streakFireColor;
    if (streak >= 14) return streakGoldColor;
    if (streak >= 7) return streakSilverColor;
    return primaryGreen;
  }
  
  Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }
  
  Color getCompletionStatusColor(bool isCompleted) {
    return isCompleted ? successColor : lightTextSecondary;
  }
  
  // System UI overlay
  void _updateSystemUIOverlay() {
    SystemUiOverlayStyle overlayStyle;
    
    switch (_themeMode) {
      case ThemeMode.light:
        overlayStyle = SystemUiOverlayStyle.dark;
        break;
      case ThemeMode.dark:
        overlayStyle = SystemUiOverlayStyle.light;
        break;
      case ThemeMode.system:
        overlayStyle = SystemUiOverlayStyle.dark; // Default to dark
        break;
    }
    
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }
  
  // Custom color extensions
  static const Map<String, Color> semanticColors = {
    'success': successColor,
    'warning': warningColor,
    'error': errorColor,
    'info': infoColor,
  };
  
  static const Map<String, Color> priorityColors = {
    'high': highPriorityColor,
    'medium': mediumPriorityColor,
    'low': lowPriorityColor,
  };
  
  static const Map<String, Color> streakColors = {
    'fire': streakFireColor,
    'gold': streakGoldColor,
    'silver': streakSilverColor,
  };
}