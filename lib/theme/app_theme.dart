import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The one brand color (a nature green). Material 3 derives every other color
/// - buttons, containers, text - from this single "seed".
const seedGreen = Color(0xFF138A6B);

/// Builds the whole Material 3 theme in one place so every screen looks the
/// same: rounded corners, soft shadows, pill buttons, two Google Fonts (Sora
/// for titles, Plus Jakarta Sans for text).
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: seedGreen,
    brightness: brightness,
  ).copyWith(
    // A slightly green-tinted page background, like the travel design.
    surface: isDark ? const Color(0xFF0E1815) : const Color(0xFFF3F8F5),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final bodyText = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
  final textTheme = bodyText.copyWith(
    headlineMedium: GoogleFonts.sora(
      textStyle: bodyText.headlineMedium,
      fontWeight: FontWeight.w800,
    ),
    headlineSmall: GoogleFonts.sora(
      textStyle: bodyText.headlineSmall,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: GoogleFonts.sora(
      textStyle: bodyText.titleLarge,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: GoogleFonts.sora(
      textStyle: bodyText.titleMedium,
      fontWeight: FontWeight.w600,
    ),
  );

  OutlineInputBorder border(Color color, [double width = 0]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant, 1),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error, 1.5),
      focusedErrorBorder: border(scheme.error, 2),
    ),
    // Pill buttons: a fully rounded "stadium" shape.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      shape: const StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// A soft, wide shadow used on cards and floating bars. Dark mode needs less
/// of it, because a dark shadow barely shows on a dark background.
List<BoxShadow> softShadow(BuildContext context, {double strength = 1}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: (isDark ? 0.35 : 0.12) * strength),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
