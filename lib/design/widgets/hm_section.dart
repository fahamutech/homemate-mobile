import 'package:flutter/material.dart';

import '../tokens.dart';

/// A section title with the link that opens the whole of it.
///
/// The designs repeat this exact pairing — an 18pt heading on the left, a 13pt
/// brand-coloured action on the right — on the Favourites screen, the home
/// screen and the rental detail. Writing it once is what stops the trailing
/// link being "See All" on one screen and "View all" on the next.
class HmSectionHeader extends StatelessWidget {
  const HmSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailingText,
  });

  final String title;

  /// The tappable link. Omitted when there is nothing more to see than what is
  /// already on screen.
  final String? action;
  final VoidCallback? onAction;

  /// A plain count where the design shows one instead of a link — "3 Items".
  final String? trailingText;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HmSpace.xl),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: HmText.title.copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action != null && onAction != null)
              // A plain InkWell rather than a TextButton: the design's link
              // sits tight against the right edge, and a button's own padding
              // pushes it inwards by eight points.
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(HmRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: HmSpace.xs, vertical: HmSpace.xxs),
                  child: Text(
                    action!,
                    style: HmText.label.copyWith(fontSize: 13, color: HmColors.brandPrimary),
                  ),
                ),
              )
            else if (trailingText != null)
              Text(
                trailingText!,
                style: HmText.label.copyWith(fontSize: 13, color: HmColors.brandPrimary),
              ),
          ],
        ),
      );
}

/// The bordered card every list on the Favourites and rentals screens is made
/// of: a square thumbnail, a column of facts, and a status pill on the right.
class HmListRow extends StatelessWidget {
  const HmListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.highlight,
    this.footnote,
    this.trailing,
    this.onTap,
    this.thumbnailSize = 48,
  });

  final Widget leading;
  final String title;

  /// Where it is, usually.
  final String? subtitle;

  /// The money. Rendered in brand green because on every one of these rows it
  /// is the thing being scanned for.
  final String? highlight;

  /// The quiet fourth line — "Next payment: 1 Nov 2026".
  final String? footnote;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double thumbnailSize;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(HmSpace.xl),
      decoration: BoxDecoration(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        border: Border.all(color: HmColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: thumbnailSize, height: thumbnailSize, child: leading),
          const SizedBox(width: HmSpace.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: HmText.label.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: HmSpace.xs),
                  Text(
                    subtitle!,
                    style: HmText.caption.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (highlight != null) ...[
                  const SizedBox(height: HmSpace.xs),
                  Text(
                    highlight!,
                    style: HmText.label.copyWith(fontSize: 13, color: HmColors.brandPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (footnote != null) ...[
                  const SizedBox(height: HmSpace.xs),
                  Text(
                    footnote!,
                    style: HmText.caption.copyWith(fontSize: 12, color: HmColors.textDisabled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: HmSpace.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: HmRadius.card, child: content),
    );
  }
}

/// A key on the left, its value on the right — the shape every "Financial
/// Summary" and "Reservation Details" card in the designs is built from.
class HmDetailRow extends StatelessWidget {
  const HmDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasise = false,
    this.valueColor,
  });

  final String label;
  final String value;

  /// The last line of a breakdown — the total — which the design sets heavier
  /// than the lines above it.
  final bool emphasise;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HmSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: emphasise
                    ? HmText.label.copyWith(fontSize: 14)
                    : HmText.body.copyWith(fontSize: 14, color: HmColors.textSecondary),
              ),
            ),
            const SizedBox(width: HmSpace.xl),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: emphasise
                    ? HmText.label.copyWith(fontSize: 15, color: valueColor ?? HmColors.textPrimary)
                    : HmText.label.copyWith(
                        fontSize: 14,
                        color: valueColor ?? HmColors.textPrimary,
                      ),
              ),
            ),
          ],
        ),
      );
}

/// A bordered white card with a title — the container the detail screens group
/// their rows into.
class HmCard extends StatelessWidget {
  const HmCard({super.key, required this.child, this.title, this.padding});

  final Widget child;
  final String? title;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(HmSpace.xxl),
        decoration: BoxDecoration(
          color: HmColors.bgPrimary,
          borderRadius: HmRadius.card,
          border: Border.all(color: HmColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title!, style: HmText.heading.copyWith(fontSize: 15)),
              const SizedBox(height: HmSpace.xl),
            ],
            child,
          ],
        ),
      );
}

/// The tinted notice the designs use for a warning or a caveat — "90 days
/// notice required", "Payment amount is server-verified".
class HmNotice extends StatelessWidget {
  const HmNotice({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.colour = HmColors.warning,
    this.action,
  });

  final String message;
  final IconData icon;
  final Color colour;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HmSpace.xl),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.10),
          borderRadius: HmRadius.card,
          border: Border.all(color: colour.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colour),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: HmText.caption.copyWith(fontSize: 13, color: HmColors.textBody)),
                  if (action != null) ...[
                    const SizedBox(height: HmSpace.xl),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
