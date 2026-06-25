import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const double rSm = 6.0;
  static const double rMd = 12.0;
  static const double rLg = 18.0;
  static const double rPill = 100.0;

  static ThemeData dark() {
    return _build(
      brightness: Brightness.dark,
      bg: AppColors.darkBg,
      surface: AppColors.darkSurface,
      surface2: AppColors.darkSurface2,
      fg: AppColors.darkFg,
      fgMuted: AppColors.darkFgMuted,
      border: AppColors.darkBorder,
    );
  }

  static ThemeData light() {
    return _build(
      brightness: Brightness.light,
      bg: AppColors.lightBg,
      surface: AppColors.lightSurface,
      surface2: AppColors.lightSurface2,
      fg: AppColors.lightFg,
      fgMuted: AppColors.lightFgMuted,
      border: AppColors.lightBorder,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surface2,
    required Color fg,
    required Color fgMuted,
    required Color border,
  }) {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentDk,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: surface,
        onSurface: fg,
        outline: border,
        surfaceContainerHighest: surface2,
      ),
      textTheme: textTheme.apply(
        bodyColor: fg,
        displayColor: fg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      extensions: [
        AppThemeExtension(
          bg: bg,
          surface: surface,
          surface2: surface2,
          fg: fg,
          fgMuted: fgMuted,
          border: border,
        ),
      ],
    );
  }
}

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color fg;
  final Color fgMuted;
  final Color border;

  const AppThemeExtension({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.fg,
    required this.fgMuted,
    required this.border,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? bg, Color? surface, Color? surface2,
    Color? fg, Color? fgMuted, Color? border,
  }) {
    return AppThemeExtension(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      fg: fg ?? this.fg,
      fgMuted: fgMuted ?? this.fgMuted,
      border: border ?? this.border,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other, double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fgMuted: Color.lerp(fgMuted, other.fgMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
