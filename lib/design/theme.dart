import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material's own knobs, set once from the tokens.
///
/// Doing it here rather than styling each widget means a plain `ElevatedButton`
/// or `TextField` already looks like the design — a screen only styles
/// something when it genuinely differs.
ThemeData buildHomeMateTheme() {
  const scheme = ColorScheme.light(
    primary: HmColors.brandPrimary,
    onPrimary: HmColors.textOnBrand,
    secondary: HmColors.brandPrimaryDark,
    onSecondary: HmColors.textOnBrand,
    surface: HmColors.bgPrimary,
    onSurface: HmColors.textPrimary,
    error: HmColors.error,
    onError: HmColors.textOnBrand,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: HmColors.bgSecondary,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: HmColors.bgPrimary,
      foregroundColor: HmColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: HmText.heading,
    ),
    textTheme: const TextTheme(
      displaySmall: HmText.display,
      titleLarge: HmText.title,
      titleMedium: HmText.heading,
      bodyLarge: HmText.body,
      bodyMedium: HmText.body,
      labelLarge: HmText.label,
      bodySmall: HmText.caption,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HmColors.brandPrimary,
        foregroundColor: HmColors.textOnBrand,
        disabledBackgroundColor: HmColors.borderStrong,
        disabledForegroundColor: HmColors.bgPrimary,
        // 52pt: comfortably above the 44pt minimum touch target, and what the
        // designs use for a primary action.
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: HmRadius.card),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HmColors.textPrimary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: HmColors.borderDefault),
        shape: RoundedRectangleBorder(borderRadius: HmRadius.card),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: HmColors.brandPrimary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HmColors.surfaceInput,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HmSpace.xxl,
        vertical: HmSpace.xxl,
      ),
      border: OutlineInputBorder(
        borderRadius: HmRadius.card,
        borderSide: const BorderSide(color: HmColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: HmRadius.card,
        borderSide: const BorderSide(color: HmColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: HmRadius.card,
        borderSide: const BorderSide(color: HmColors.brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: HmRadius.card,
        borderSide: const BorderSide(color: HmColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: HmRadius.card,
        borderSide: const BorderSide(color: HmColors.error, width: 1.5),
      ),
      labelStyle: HmText.caption,
      hintStyle: const TextStyle(color: HmColors.textDisabled, fontSize: 15),
    ),
    cardTheme: CardThemeData(
      color: HmColors.bgPrimary,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: HmRadius.card,
        side: const BorderSide(color: HmColors.borderDefault),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: HmColors.surfaceInput,
      selectedColor: HmColors.brandPrimarySoft,
      labelStyle: HmText.caption,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HmRadius.pill)),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: HmColors.bgPrimary,
      selectedItemColor: HmColors.brandPrimary,
      unselectedItemColor: HmColors.textDisabled,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showUnselectedLabels: true,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: HmColors.bgPrimary,
      shape: RoundedRectangleBorder(borderRadius: HmRadius.sheet),
    ),
    dividerTheme: const DividerThemeData(color: HmColors.borderDefault, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: HmColors.textPrimary,
      contentTextStyle: const TextStyle(color: HmColors.bgPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: HmRadius.card),
    ),
  );
}
