import 'package:flutter/material.dart';

/// A restrained instrument-panel palette; movement colors match the physical gait.
abstract final class OctoColors {
  static const canvas = Color(0xFFF4F5F2);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF18242A);
  static const muted = Color(0xFF67767C);
  static const line = Color(0xFFE0E6E3);
  static const dark = Color(0xFF1D292F);
  static const darkLine = Color(0xFF38474D);
  static const teal = Color(0xFF276F69);
  static const tealWash = Color(0xFFE5F2EF);
  static const blue = Color(0xFF438ABD); // L1/R1 and L3/R3.
  static const orange = Color(0xFFE7A057); // L2/R2 and L4/R4.
  static const danger = Color(0xFFC64638);
  static const dangerWash = Color(0xFFFFECE9);
}

ThemeData buildOctoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: OctoColors.teal,
      secondary: OctoColors.blue,
      surface: OctoColors.paper,
      onSurface: OctoColors.ink,
      error: OctoColors.danger,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: OctoColors.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: OctoColors.canvas,
      foregroundColor: OctoColors.ink,
      elevation: 0,
    ),
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        fontSize: 29, height: 1.1, fontWeight: FontWeight.w800,
        letterSpacing: -1.0, color: OctoColors.ink,
      ),
      titleLarge: const TextStyle(
        fontSize: 19, fontWeight: FontWeight.w700,
        letterSpacing: -0.35, color: OctoColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14, height: 1.45, color: OctoColors.ink,
      ),
      bodySmall: const TextStyle(
        fontSize: 12, height: 1.4, color: OctoColors.muted,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OctoColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: OctoColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: OctoColors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: OctoColors.paper,
      indicatorColor: OctoColors.tealWash,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11.5,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700 : FontWeight.w500,
      )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: OctoColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
