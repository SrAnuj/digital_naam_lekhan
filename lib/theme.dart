import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette: warm cream paper, deep maroon, temple gold.
class AppColors {
  static const cream = Color(0xFFFFF4DC);
  static const creamLight = Color(0xFFFFF9EC);
  static const creamDark = Color(0xFFF8E3B5);
  static const maroon = Color(0xFF7B1113);
  static const maroonDark = Color(0xFF4F0A0C);
  static const gold = Color(0xFFC9962B);
  static const goldLight = Color(0xFFE8C06A);
  static const saffron = Color(0xFFE2791B);
  static const ink = Color(0xFF3A1E12);
  static const muted = Color(0xFF8A6D58);
  static const line = Color(0xFFEAD7AE);
  static const card = Color(0xFFFFFBF2);
  static const success = Color(0xFF2E7D32);
}

extension ColorOpacity on Color {
  /// Alpha helper that works on every Flutter version.
  Color o(double v) => withAlpha((v * 255).round().clamp(0, 255));
}

class AppText {
  static TextStyle display(double s, {Color? c, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(
          fontSize: s, fontWeight: w, color: c ?? AppColors.maroon, height: 1.2);

  static TextStyle cinzel(double s, {Color? c, FontWeight w = FontWeight.w600}) =>
      GoogleFonts.cinzel(
          fontSize: s, fontWeight: w, color: c ?? AppColors.maroon, height: 1.2);

  static TextStyle hindi(double s, {Color? c, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.notoSerifDevanagari(
          fontSize: s, fontWeight: w, color: c ?? AppColors.maroon, height: 1.3);

  static TextStyle body(double s, {Color? c, FontWeight w = FontWeight.w400}) =>
      GoogleFonts.poppins(
          fontSize: s, fontWeight: w, color: c ?? AppColors.ink, height: 1.35);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      primary: AppColors.maroon,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );
  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.maroon,
    ),
  );
}

/// Indian digit grouping: 1,00,000.
String fmt(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final b = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) b.write(',');
    b.write(rest[i]);
  }
  return '$b,$last3';
}
