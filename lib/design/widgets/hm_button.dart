import 'package:flutter/material.dart';

import '../tokens.dart';

/// Figma `Button`: Primary, Outline, Neutral, Soft, Ghost, Danger and Danger
/// outline, each Large / Medium / Small.
enum HmButtonStyle { primary, outline, neutral, soft, ghost, danger, dangerOutline }

enum HmButtonSize {
  large(52),
  medium(44),
  small(40);

  const HmButtonSize(this.height);

  final double height;
}

/// What a style paints, worked out once so a screen never picks its own
/// "danger red" or disabled grey.
class HmButtonColours {
  const HmButtonColours({required this.fill, required this.label, this.border});

  final Color fill;
  final Color label;
  final Color? border;

  static HmButtonColours of(HmButtonStyle style, {required bool enabled}) {
    if (!enabled) {
      return switch (style) {
        HmButtonStyle.primary || HmButtonStyle.danger =>
          const HmButtonColours(fill: HmColors.borderStrong, label: HmColors.bgPrimary),
        HmButtonStyle.outline || HmButtonStyle.neutral || HmButtonStyle.dangerOutline =>
          const HmButtonColours(
            fill: HmColors.bgPrimary,
            label: HmColors.textDisabled,
            border: HmColors.borderDefault,
          ),
        HmButtonStyle.soft => const HmButtonColours(fill: HmColors.surfaceInput, label: HmColors.textDisabled),
        HmButtonStyle.ghost => const HmButtonColours(fill: Colors.transparent, label: HmColors.textDisabled),
      };
    }
    return switch (style) {
      HmButtonStyle.primary => const HmButtonColours(fill: HmColors.brandPrimary, label: HmColors.textOnBrand),
      HmButtonStyle.outline => const HmButtonColours(
          fill: HmColors.bgPrimary,
          label: HmColors.brandPrimary,
          border: HmColors.brandPrimary,
        ),
      HmButtonStyle.neutral => const HmButtonColours(
          fill: HmColors.bgPrimary,
          label: HmColors.textPrimary,
          border: HmColors.borderDefault,
        ),
      HmButtonStyle.soft => const HmButtonColours(fill: HmColors.brandSubtle, label: HmColors.brandPrimary),
      HmButtonStyle.ghost => const HmButtonColours(fill: Colors.transparent, label: HmColors.brandPrimary),
      HmButtonStyle.danger => const HmButtonColours(fill: HmColors.error, label: HmColors.textOnBrand),
      HmButtonStyle.dangerOutline => const HmButtonColours(
          fill: HmColors.bgPrimary,
          label: HmColors.error,
          border: HmColors.error,
        ),
    };
  }
}

/// The HomeMate button: 12pt radius, 15pt semi-bold label, optional leading
/// icon, and an icon-only form that still announces its label.
class HmButton extends StatelessWidget {
  const HmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = HmButtonStyle.primary,
    this.size = HmButtonSize.large,
    this.icon,
    this.iconOnly = false,
    this.expand = true,
    this.busy = false,
  }) : assert(!iconOnly || icon != null, 'An icon-only button needs an icon');

  final String label;
  final VoidCallback? onPressed;
  final HmButtonStyle style;
  final HmButtonSize size;
  final IconData? icon;

  /// Hides the label on screen; it stays the button's accessible name.
  final bool iconOnly;

  /// Full width, as every form's main action is. Off for inline buttons.
  final bool expand;

  /// An action in flight: shows progress and refuses a second tap.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final colours = HmButtonColours.of(style, enabled: enabled || busy);
    final radius = BorderRadius.circular(HmRadius.md);

    final Widget content = busy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: colours.label),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: colours.label),
              if (icon != null && !iconOnly) const SizedBox(width: HmSpace.md),
              if (!iconOnly)
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: colours.label,
                    ),
                  ),
                ),
            ],
          );

    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colours.fill,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: colours.border == null ? BorderSide.none : BorderSide(color: colours.border!, width: 1.5),
        ),
        child: InkWell(
          key: ValueKey('hm-button-$label'),
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: SizedBox(
            height: size.height,
            width: iconOnly ? size.height : (expand ? double.infinity : null),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : HmSpace.xxl),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );

    return iconOnly ? Tooltip(message: label, child: button) : button;
  }
}
