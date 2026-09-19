import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/tokens.dart';

/// The dots above a PIN keypad.
///
/// Filled as digits arrive, so the customer can see how many they have typed
/// without the digits themselves ever being on screen — a PIN pad that echoes
/// the number is a PIN pad readable over a shoulder.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, this.of = 4, this.error = false});

  final int length;
  final int of;
  final bool error;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < of; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: const EdgeInsets.symmetric(horizontal: HmSpace.lg),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < length
                    ? (error ? HmColors.error : HmColors.brandPrimary)
                    : HmColors.surfaceInput,
                border: Border.all(
                  color: error ? HmColors.error : HmColors.borderStrong,
                ),
              ),
            ),
        ],
      );
}

/// An on-screen number pad.
///
/// The app draws its own rather than raising the system keyboard, for the
/// reason every banking app does: the keypad is the screen, so there is no
/// layout that shifts under the customer's thumb when the keyboard appears,
/// the digits sit where a phone dialler puts them, and a four-digit PIN is
/// four taps in the same place every time.
///
/// It is still fully accessible — each key is a real button with a label, so a
/// screen reader announces "3, button" rather than a mystery rectangle.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onAction,
    this.actionIcon,
    this.actionLabel,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// The bottom-left key, which is otherwise blank — used for "Forgot PIN?".
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionLabel;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final digit in row)
                _Key(
                  label: digit,
                  onPressed: enabled ? () => _press(digit) : null,
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Key(
              icon: actionIcon,
              semanticLabel: actionLabel,
              onPressed: enabled ? onAction : null,
            ),
            _Key(label: '0', onPressed: enabled ? () => _press('0') : null),
            _Key(
              icon: Icons.backspace_outlined,
              semanticLabel: 'Delete the last digit',
              onPressed: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onBackspace();
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  void _press(String digit) {
    HapticFeedback.selectionClick();
    onDigit(digit);
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, this.semanticLabel, this.onPressed});

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // An empty slot still takes up its space, so the grid does not reflow when
    // there is no action key to show.
    if (label == null && icon == null) return const SizedBox(width: 88, height: 68);

    return SizedBox(
      width: 88,
      height: 68,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: HmRadius.card),
          foregroundColor: HmColors.textPrimary,
        ),
        child: label != null
            ? Text(
                label!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: HmColors.textPrimary,
                ),
              )
            : Icon(icon, size: 24, semanticLabel: semanticLabel, color: HmColors.textSecondary),
      ),
    );
  }
}
