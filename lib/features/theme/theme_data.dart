import 'package:flutter/material.dart';
import 'package:sacdia/core/constants.dart';

class AppThemeData {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: sacRed,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: sacRed,
      secondary: sacRed,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: sacRed,
      foregroundColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sacRed,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: sacRed,
    scaffoldBackgroundColor: Colors.grey[900],
    colorScheme: ColorScheme.dark(
      primary: sacRed,
      secondary: sacRed,
      surface: Colors.grey[900]!,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: sacRed,
      foregroundColor: Colors.white,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.grey[900],
      modalBackgroundColor: Colors.grey[900],
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.grey[900],
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sacRed,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static const appBarTitleStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  static const titleStyle = TextStyle(
    fontSize: 20,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  static const buttonTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    inherit: false,
  );

  static const buttonBlackTextStyle = TextStyle(
    fontSize: 18,
    color: sacBlack,
    fontWeight: FontWeight.bold,
    inherit: false,
  );

  static final primaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(sacRed),
    elevation: WidgetStateProperty.all(0),
    textStyle: WidgetStateProperty.all<TextStyle>(buttonTextStyle),
  );

  static final secondaryButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.grey.shade300),
    elevation: WidgetStateProperty.all(0),
  );

  static final disabledButtonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.grey),
    elevation: WidgetStateProperty.all(0),
  );
}
