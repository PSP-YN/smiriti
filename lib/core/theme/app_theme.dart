import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static const Color _gold = Color(0xFFC9A84C);
  static const Color _goldDark = Color(0xFFB8943A);
  static const Color _surfaceLight = Color(0xFFFCF9F0);
  static const Color _surfaceDark = Color(0xFF1A1814);
  static const Color _cardDark = Color(0xFF252220);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _gold,
        brightness: Brightness.light,
        surface: _surfaceLight,
        primary: _gold,
        onPrimary: Colors.black,
        secondary: const Color(0xFF8B7355),
        tertiary: const Color(0xFFD4A574),
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: _surfaceLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8DCC8)),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: const BorderSide(color: _gold, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8DCC8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8DCC8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A1814), height: 1.2),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1814), height: 1.3),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1814)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1814)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1814)),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF252220)),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF44413D)),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF78746E)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8DCC8), thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF252220),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _goldDark,
        brightness: Brightness.dark,
        surface: _surfaceDark,
        primary: _goldDark,
        onPrimary: Colors.black,
        secondary: const Color(0xFFA6936E),
        tertiary: const Color(0xFFC49A6C),
        error: const Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: _surfaceDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _cardDark,
        foregroundColor: Color(0xFFF5F0E6),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: Color(0xFFF5F0E6),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3A3733)),
        ),
        color: _cardDark,
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _goldDark,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _goldDark,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _goldDark,
          side: const BorderSide(color: _goldDark, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3733)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3733)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _goldDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFF78746E)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFFF5F0E6), height: 1.2),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF5F0E6), height: 1.3),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF5F0E6)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F0E6)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFF5F0E6)),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: Color(0xFFE8E0D4)),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFFC4BDB2)),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF78746E)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF3A3733), thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _cardDark,
        contentTextStyle: const TextStyle(color: Color(0xFFF5F0E6), fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
    );
  }
}
