import 'package:flutter/material.dart';

class AppTheme {
  // Web app inspired colors
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  
  static const Color sidebarBg = Color(0xFF172231);
  static const Color sidebarActive = Color(0xFF21366F);
  static const Color sidebarBorder = Color(0x0FFFFFFF);
  
  static const Color contentBgLight = Color(0xFFEEF3F8);
  static const Color contentBgDark = Color(0xFF0B111C);
  
  static const Color topbarBgLight = Color(0xFFFFFFFF);
  static const Color topbarBgDark = Color(0xFF172231);
  
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color infoColor = Color(0xFF3B82F6);
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSidebar = Color(0xFFB7C2D2);
  static const Color textSidebarActive = Color(0xFFBCD3FF);
  
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color cardBg = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: primaryLight,
        surface: cardBg,
        error: errorColor,
      ),
      scaffoldBackgroundColor: contentBgLight,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: topbarBgLight,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderLight.withValues(alpha: 0.5)),
        ),
        color: cardBg,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(color: borderLight.withValues(alpha: 0.5), thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        indicatorColor: primaryColor.withValues(alpha: 0.15),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: Colors.grey.shade500, size: 24);
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBg,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: primaryLight,
        error: errorColor,
      ),
      scaffoldBackgroundColor: contentBgDark,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: topbarBgDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        color: const Color(0xFF1E1E1E),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0F172A),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: primaryLight.withValues(alpha: 0.2),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}
