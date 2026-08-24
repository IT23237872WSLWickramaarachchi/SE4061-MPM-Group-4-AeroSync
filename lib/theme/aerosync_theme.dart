import 'package:flutter/material.dart';

class AeroSyncTheme {
  // Brand Colors (Exact Specifications)
  static const Color darkBackground = Color(0xFF0E1513); // Scaffold background
  static const Color panelBackground = Color(0xFF161D1B); // Surface panels
  static const Color cardBackground = Color(0xFF1E2724);
  static const Color cardSelectedBackground = Color(0xFF152A26);
  static const Color borderColor = Color(0xFF26332E);
  static const Color borderHighlightColor = Color(0xFF35DBC7);

  // Primary Accent
  static const Color primaryTeal = Color(0xFF35DBC7);
  static const Color tealGlow = Color(0x3335DBC7);
  static const Color tealDark = Color(0xFF1B6A61);

  // Fan Accents
  static const Color fan1Orange = Color(0xFFE07A48);
  static const Color fan1OrangeFill = Color(0x33E07A48);
  
  static const Color fan2Pink = Color(0xFFE05688);
  static const Color fan2PinkFill = Color(0x33E05688);

  static const Color fan3Blue = Color(0xFF569AE0);
  static const Color fan3BlueFill = Color(0x33569AE0);

  // Video Track Accent
  static const Color videoClipBg = Color(0xFF234B4E);
  static const Color videoClipBorder = Color(0xFF35DBC7);

  // Status & Telemetry
  static const Color liveRed = Color(0xFFFF4D4D);
  static const Color textMain = Color(0xFFECEFF4);
  static const Color textMuted = Color(0xFF8B9BB0);
  static const Color textDim = Color(0xFF506075);

  // Font Families
  static const String fontHeadline = 'Inter';
  static const String fontTechnical = 'JetBrains Mono';

  static ThemeData get themeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        surface: panelBackground,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: fontHeadline, color: textMain, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontFamily: fontHeadline, color: textMain),
        bodyMedium: TextStyle(fontFamily: fontHeadline, color: textMuted),
        labelSmall: TextStyle(fontFamily: fontTechnical, color: textDim),
      ),
    );
  }
}
