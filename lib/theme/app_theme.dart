import 'package:flutter/material.dart';

class BrandColors {
  static const brand50 = Color(0xFFEEF7FC);
  static const brand100 = Color(0xFFDAEDF8);
  static const brand200 = Color(0xFFBADBF0);
  static const brand300 = Color(0xFF93C4E1);
  static const brand400 = Color(0xFF6AA9CD);
  static const brand500 = Color(0xFF458DB5);
  static const brand600 = Color(0xFF2B7298);
  static const brand700 = Color(0xFF215B7C);
  static const brand800 = Color(0xFF1B4761);
  static const brand900 = Color(0xFF153549);
  static const brand950 = Color(0xFF0A1F2D);

  static const stone100 = Color(0xFFF5F5F4);
  static const stone200 = Color(0xFFE7E5E4);
  static const stone400 = Color(0xFFA6A09B);
  static const stone500 = Color(0xFF79716B);
  static const stone600 = Color(0xFF57534D);
  static const stone700 = Color(0xFF44403B);
  static const stone800 = Color(0xFF292524);
  static const stone900 = Color(0xFF1C1917);
  static const stone950 = Color(0xFF0C0A09);

  static const appBgLight = Color(0xFFF8F5F0);
  static const appBgDark = stone950;
}

enum StatusLevel { good, ok, soon, ended, unknown }

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.good,
    required this.ok,
    required this.soon,
    required this.ended,
    required this.unknown,
    required this.success,
    required this.warning,
    required this.error,
    required this.muted,
    required this.accentedBg,
    required this.invertedBg,
    required this.cardBg,
    required this.cardBorder,
  });

  final Color good;
  final Color ok;
  final Color soon;
  final Color ended;
  final Color unknown;
  final Color success;
  final Color warning;
  final Color error;
  final Color muted;
  final Color accentedBg;
  final Color invertedBg;
  final Color cardBg;
  final Color cardBorder;

  static const light = StatusColors(
    good: Color(0xFF009966),
    ok: Color(0xFF5EA500),
    soon: Color(0xFFFE9A00),
    ended: Color(0xFFFB2C36),
    unknown: BrandColors.stone400,
    success: Color(0xFF00C950),
    warning: Color(0xFFD08700),
    error: Color(0xFFFB2C36),
    muted: BrandColors.stone500,
    accentedBg: BrandColors.stone200,
    invertedBg: BrandColors.stone900,
    cardBg: Colors.white,
    cardBorder: BrandColors.stone200,
  );

  static const dark = StatusColors(
    good: Color(0xFF00D492),
    ok: Color(0xFF9AE600),
    soon: Color(0xFFFFB900),
    ended: Color(0xFFFF6467),
    unknown: BrandColors.stone500,
    success: Color(0xFF05DF72),
    warning: Color(0xFFFDC700),
    error: Color(0xFFFF6467),
    muted: BrandColors.stone400,
    accentedBg: BrandColors.stone800,
    invertedBg: Colors.white,
    cardBg: BrandColors.stone900,
    cardBorder: BrandColors.stone800,
  );

  Color forLevel(StatusLevel level) {
    switch (level) {
      case StatusLevel.good:
        return good;
      case StatusLevel.ok:
        return ok;
      case StatusLevel.soon:
        return soon;
      case StatusLevel.ended:
        return ended;
      case StatusLevel.unknown:
        return unknown;
    }
  }

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return StatusColors(
      good: l(good, other.good),
      ok: l(ok, other.ok),
      soon: l(soon, other.soon),
      ended: l(ended, other.ended),
      unknown: l(unknown, other.unknown),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      muted: l(muted, other.muted),
      accentedBg: l(accentedBg, other.accentedBg),
      invertedBg: l(invertedBg, other.invertedBg),
      cardBg: l(cardBg, other.cardBg),
      cardBorder: l(cardBorder, other.cardBorder),
    );
  }
}

class AppTheme {
  static ThemeData light() => _build(
        brightness: Brightness.light,
        primary: BrandColors.brand600,
        scaffold: BrandColors.appBgLight,
        surface: Colors.white,
        onSurface: BrandColors.stone900,
        status: StatusColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        primary: BrandColors.brand400,
        scaffold: BrandColors.appBgDark,
        surface: BrandColors.stone900,
        onSurface: BrandColors.stone100,
        status: StatusColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required StatusColors status,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.brand600,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: brightness == Brightness.light ? Colors.white : BrandColors.brand950,
      secondary: primary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: status.muted,
      outline: status.cardBorder,
      outlineVariant: status.cardBorder,
      error: status.error,
    );
    final radius = BorderRadius.circular(8);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      extensions: [status],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: status.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
      ),
    );
  }
}
