import 'package:flutter/material.dart';

/// Color and theme definitions for the app
class AppTheme {
  /// Light theme colors
  static final ColorScheme lightColorScheme = ColorScheme(
    primary: Color(0xFF1E88E5), // Blue
    primaryContainer: Color(0xFFBBDEFB), // Light Blue
    secondary: Color(0xFF26A69A), // Teal
    secondaryContainer: Color(0xFFB2DFDB), // Light Teal
    surface: Colors.white, // Light Grey
    error: Color(0xFFE53935), // Red
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Color(0xFF212121), // Dark Grey
    onError: Colors.white,
    brightness: Brightness.light,
  );

  /// Dark theme colors
  static final ColorScheme darkColorScheme = ColorScheme(
    primary: Color(0xFF42A5F5), // Blue
    primaryContainer: Color(0xFF0D47A1), // Dark Blue
    secondary: Color(0xFF26A69A), // Teal
    secondaryContainer: Color(0xFF00695C), // Dark Teal
    surface: Color(0xFF424242), // Very Dark Grey
    error: Color(0xFFEF5350), // Red
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
    brightness: Brightness.dark,
  );

  /// Light theme
  static ThemeData lightTheme = ThemeData(
    colorScheme: lightColorScheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      iconTheme: IconThemeData(color: Color(0xFF1E88E5)),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF1E88E5),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color(0xFF1E88E5),
      ),
    ),
    iconTheme: IconThemeData(
      color: Color(0xFF616161), // Medium Grey
      size: 24,
    ),
    sliderTheme: SliderThemeData(
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      trackHeight: 4,
      activeTrackColor: Color(0xFF1E88E5),
      inactiveTrackColor: Color(0xFFBBDEFB),
      thumbColor: Color(0xFF1E88E5),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.withOpacity(.32);
        }
        return Color(0xFF1E88E5);
      }),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Color(0xFFE0E0E0),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF212121)),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF212121)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF212121)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF212121)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF757575)),
    ),
  );

  /// Dark theme
  static ThemeData darkTheme = ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFF424242),
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF42A5F5)),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF42A5F5),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color(0xFF42A5F5),
      ),
    ),
    iconTheme: IconThemeData(
      color: Color(0xFFBDBDBD), // Light Grey
      size: 24,
    ),
    sliderTheme: SliderThemeData(
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      trackHeight: 4,
      activeTrackColor: Color(0xFF42A5F5),
      inactiveTrackColor: Color(0xFF0D47A1),
      thumbColor: Color(0xFF42A5F5),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.withOpacity(.32);
        }
        return Color(0xFF42A5F5);
      }),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: Color(0xFF616161),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFBDBDBD)),
    ),
  );

  /// Icon colors
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Color(0xFF616161)
        : Color(0xFFBDBDBD);
  }

  /// Tool icon color
  static Color getToolIconColor(BuildContext context, bool isSelected) {
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).brightness == Brightness.light
          ? Color(0xFF616161)
          : Color(0xFFBDBDBD);
    }
  }

  /// Tool background color
  static Color getToolBackgroundColor(BuildContext context, bool isSelected) {
    if (isSelected) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4);
    } else {
      return Colors.transparent;
    }
  }
}
