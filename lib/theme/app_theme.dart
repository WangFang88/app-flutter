import 'package:flutter/material.dart';

const kPrimary = Color(0xFF6366F1);
const kSurface = Color(0xFFF2F2F7);
const kCardLight = Color(0xFFFFFFFF);
const kCardDark = Color(0xFF1C1C1E);
const kBgDark = Color(0xFF000000);

final appTheme = _buildTheme(Brightness.light);
final appDarkTheme = _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: brightness,
    surface: isDark ? kBgDark : kSurface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? kBgDark : kSurface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? kCardDark : kCardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      indicatorColor: kPrimary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
      bodyMedium: TextStyle(fontSize: 15, color: isDark ? const Color(0xFFAEAEB2) : const Color(0xFF8E8E93)),
      bodySmall: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      labelStyle: TextStyle(color: isDark ? const Color(0xFF8E8E93) : const Color(0xFFAEAEB2), fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}