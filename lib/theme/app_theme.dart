import 'package:flutter/material.dart';

const kPrimary = Color(0xFF6366F1);
const kPrimaryVar = Color(0xFF8B5CF6);
const kSurface = Color(0xFFF8F7FF);
const kCardLight = Color(0xFFFFFFFF);
const kCardDark = Color(0xFF1E1B2E);
const kBgDark = Color(0xFF13111E);

const gradientPurple = LinearGradient(
  colors: [kPrimary, kPrimaryVar],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const gradientHeader = LinearGradient(
  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? kCardDark : kCardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1A1730) : Colors.white,
      indicatorColor: kPrimary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1A1730),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1A1730)),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1A1730)),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1730)),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1A1730)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1730)),
      bodyMedium: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
      bodySmall: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2640) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      labelStyle: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
