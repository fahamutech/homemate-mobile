import 'package:flutter/material.dart';

/// The design system's variables, taken from the Figma file's bound variables
/// (`03 Customer Flows`, node 2:4) rather than eyedropped from a screenshot.
///
/// Nothing in the app writes a raw hex colour or a magic number of pixels: a
/// token here is the only way to say "brand green" or "card radius", so a
/// change in Figma is a change in one file.
class HmColors {
  const HmColors._();

  // color/brand/*
  static const brandPrimary = Color(0xFF059676);
  static const brandPrimaryDark = Color(0xFF047857);
  static const brandPrimarySoft = Color(0x1F059676);

  // color/text/*
  static const textPrimary = Color(0xFF0F1729);
  static const textBody = Color(0xFF4B5563);
  static const textSecondary = Color(0xFF64748B);
  static const textDisabled = Color(0xFF94A3B8);
  static const textOnBrand = Color(0xFFFFFFFF);

  // color/bg/* and color/surface/*
  static const bgPrimary = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF8FAFC);
  static const surfaceInput = Color(0xFFF1F5F9);

  // color/border/*
  static const borderDefault = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);

  // color/status/*
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  /// Status chips share one mapping so a state never reads green on one screen
  /// and grey on another.
  static Color forStatus(String status) => switch (status) {
        'approved' || 'confirmed' || 'verified' || 'successful' || 'paid' || 'completed' ||
        'active' || 'accepted' =>
          success,
        'pending' || 'requested' || 'pending_review' || 'awaiting_payment' ||
        'awaiting_verification' || 'in_review' || 'responded' =>
          warning,
        'rejected' || 'cancelled' || 'failed' || 'expired' || 'no_show' || 'suspended' => error,
        _ => textSecondary,
      };
}

/// spacing/* — the 2/4/8/10/12/16/20/24 scale the designs are laid out on.
class HmSpace {
  const HmSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 16;
  static const double xxxl = 20;
  static const double huge = 24;
  static const double section = 32;
}

/// radius/*
class HmRadius {
  const HmRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18;
  static const double huge = 24;
  static const double pill = 999;

  static BorderRadius get card => BorderRadius.circular(md);
  static BorderRadius get sheet => const BorderRadius.vertical(top: Radius.circular(xl));
}

/// The type ramp. Sizes come from the designs; the family is left to the
/// platform so the app reads natively on Android and iOS alike.
class HmText {
  const HmText._();

  static const display = TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: HmColors.textPrimary);
  static const title = TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w700, color: HmColors.textPrimary);
  static const heading = TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w600, color: HmColors.textPrimary);
  static const body = TextStyle(fontSize: 15, height: 1.45, color: HmColors.textBody);
  static const label = TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600, color: HmColors.textPrimary);
  static const caption = TextStyle(fontSize: 12, height: 1.35, color: HmColors.textSecondary);
  static const price = TextStyle(fontSize: 20, height: 1.2, fontWeight: FontWeight.w700, color: HmColors.brandPrimary);
}

/// The one breakpoint the app cares about. The designs are 390pt wide; above
/// roughly a tablet the same screens get a centred column rather than stretched
/// full-bleed text, which is unreadable on a desktop browser.
class HmLayout {
  const HmLayout._();

  static const double contentMaxWidth = 560;
  static const double wideBreakpoint = 720;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;
}
