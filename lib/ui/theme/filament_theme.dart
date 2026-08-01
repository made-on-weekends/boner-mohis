import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class FilamentColors {
  static const emberOrange = Color(0xFFB25409);
  static const emberOrangeDark = Color(0xFF8A4108);

  static const warmPaper = Color(0xFFF9F6F0);
  static const cardBgLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE2DCCF);

  static const darkBg = Color(0xFF1C1914);
  static const darkCard = Color(0xFF25221C);
  static const darkBorder = Color(0xFF38342C);

  static const textPrimary = Color(0xFF181510);
  static const textSecondary = Color(0xFF535046);
  static const textMuted = Color(0xFF756F61);

  static const textPrimaryDark = Color(0xFFF0ECE3);
  static const textSecondaryDark = Color(0xFFB2AEA2);
  static const textMutedDark = Color(0xFF8E897D);

  static const success = Color(0xFF2E7D3A);
  static const warning = Color(0xFFB25409);
  static const danger = Color(0xFFC22A21);
}

ThemeData filamentLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: FilamentColors.warmPaper,
    colorScheme: const ColorScheme.light(
      primary: FilamentColors.emberOrange,
      onPrimary: Colors.white,
      secondary: FilamentColors.textSecondary,
      onSecondary: Colors.white,
      surface: FilamentColors.cardBgLight,
      onSurface: FilamentColors.textPrimary,
      error: FilamentColors.danger,
    ),
    textTheme: _buildTextTheme(
      bodyColor: FilamentColors.textPrimary,
      labelColor: FilamentColors.textMuted,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FilamentColors.warmPaper,
      foregroundColor: FilamentColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: FilamentColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: FilamentColors.cardBgLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FilamentColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FilamentColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FilamentColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: FilamentColors.emberOrange, width: 1.5),
      ),
      labelStyle: GoogleFonts.dmSans(
          color: FilamentColors.textMuted, fontSize: 15),
      hintStyle: GoogleFonts.dmSans(
          color: FilamentColors.textMuted, fontSize: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FilamentColors.emberOrange,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 15),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FilamentColors.textPrimary,
        side: const BorderSide(color: FilamentColors.borderLight),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 15),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: FilamentColors.borderLight,
      thickness: 1,
    ),
  );
}

ThemeData filamentDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: FilamentColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: FilamentColors.emberOrange,
      onPrimary: Colors.white,
      secondary: FilamentColors.textSecondaryDark,
      surface: FilamentColors.darkCard,
      onSurface: FilamentColors.textPrimaryDark,
      error: FilamentColors.danger,
    ),
    textTheme: _buildTextTheme(
      bodyColor: FilamentColors.textPrimaryDark,
      labelColor: FilamentColors.textMutedDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FilamentColors.darkBg,
      foregroundColor: FilamentColors.textPrimaryDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: FilamentColors.textPrimaryDark,
      ),
    ),
    cardTheme: CardThemeData(
      color: FilamentColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FilamentColors.darkBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FilamentColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FilamentColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FilamentColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: FilamentColors.emberOrange, width: 1.5),
      ),
      labelStyle: GoogleFonts.dmSans(
          color: FilamentColors.textMutedDark, fontSize: 15),
      hintStyle: GoogleFonts.dmSans(
          color: FilamentColors.textMutedDark, fontSize: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FilamentColors.emberOrange,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 15),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FilamentColors.textPrimaryDark,
        side: const BorderSide(color: FilamentColors.darkBorder),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle:
            GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 15),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: FilamentColors.darkBorder,
      thickness: 1,
    ),
  );
}

TextTheme _buildTextTheme({
  required Color bodyColor,
  required Color labelColor,
}) {
  return TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 44, fontWeight: FontWeight.w500, color: bodyColor, height: 1.0),
    headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24, fontWeight: FontWeight.w500, color: bodyColor, height: 1.2),
    titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w500, color: bodyColor, height: 1.4),
    bodyLarge: GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.w400, color: bodyColor, height: 1.6),
    bodyMedium: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400, color: bodyColor, height: 1.3),
    bodySmall: GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w400, color: labelColor, height: 1.2),
    labelLarge: GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.w500, color: bodyColor),
    labelMedium: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w500, color: labelColor),
    labelSmall: GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w400, color: labelColor),
  );
}
