import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../design/widgets/hm_feedback.dart';
import '../../routing/app_router.dart';
import '../discovery/data/search_providers.dart';
import 'models.dart';
import 'property_image.dart';
import '../../core/i18n/app_text.dart';
import 'property_facts.dart';

/// Which way round the card is laid out.
enum PropertyCardLayout {
  /// Photo on top, facts beneath — results, the home carousel, the map card.
  vertical,

  /// Photo on the left, facts on the right, in a 100pt-tall row. What the
  /// Favourites screen's sideways strip uses (CUS-013a).
  horizontal,
}

/// One listing, as it appears on the home screen, in results, on the map and
/// in the Favourites strip. All of them used the same card in the designs, so
/// they use the same widget here — a second "saved card" is how the two drift
/// apart, and the heart is the part that must never behave differently.
class PropertyCard extends ConsumerStatefulWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.onSavedChanged,
    this.compact = false,
    this.fillHeight = false,
    this.layout = PropertyCardLayout.vertical,
  });

  final PropertySummary property;

  /// Lets the containing list update its own copy, so the heart does not snap
  /// back when the screen rebuilds from cached data.
  final ValueChanged<bool>? onSavedChanged;
  final bool compact;

  /// Set by a parent that has already fixed the card's height — the home
  /// screen's sideways carousel.
  ///
  /// The photo then takes whatever space the text leaves rather than a fixed
  /// 176, so the card cannot overflow: with a fixed image height, a longer
  /// title or a larger system text size pushes the price off the bottom edge.
  /// In a vertical list the height is unbounded and an `Expanded` image would
  /// throw, so this stays off by default.
  final bool fillHeight;

  final PropertyCardLayout layout;

  @override
  ConsumerState<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends ConsumerState<PropertyCard> {
  late bool _saved = widget.property.isSaved;
  bool _busy = false;

  @override
  void didUpdateWidget(PropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.isSaved != widget.property.isSaved) {
      _saved = widget.property.isSaved;
    }
  }

  Future<void> _toggleSaved() async {
    if (_busy) return;
    final next = !_saved;
    // Optimistic: a heart that waits for a round trip feels broken.
    setState(() {
      _saved = next;
      _busy = true;
    });

    try {
      final repository = ref.read(catalogueRepositoryProvider);
      next
          ? await repository.save(widget.property.id)
          : await repository.unsave(widget.property.id);
      widget.onSavedChanged?.call(next);
      ref.invalidate(activitySummaryProvider);
      // The Saved tab is a branch of an IndexedStack, so its provider stays
      // alive with whatever it last fetched. Without this, a heart tapped on
      // the home screen leaves that list still saying "Nothing saved".
      ref.invalidate(savedPropertiesProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saved = !next);
      HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Only inside a parent that has bounded the height — see [PropertyCard.fillHeight].
  Widget _maybeExpanded(Widget child) =>
      widget.fillHeight ? Expanded(child: child) : child;

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.property(property.id)),
        child: widget.layout == PropertyCardLayout.horizontal
            ? _horizontal(property)
            : _vertical(property),
      ),
    );
  }

  /// The Favourites strip's card: a square photo, then price, title, place and
  /// facts. The price leads here rather than the title, because this strip is
  /// scanned for "what can I afford" rather than read.
  Widget _horizontal(PropertySummary property) => SizedBox(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PropertyImage(
                    mediaId: property.coverMediaId,
                    borderRadius: BorderRadius.zero,
                  ),
                  // The design hides the heart on this card, on the reasoning
                  // that everything in the Favourites strip is saved already.
                  // It is kept, smaller and tucked into the corner, because
                  // otherwise the only way to unsave something is to open the
                  // listing — and the tap that put it here should be the tap
                  // that takes it away.
                  Positioned(
                    top: HmSpace.xs,
                    right: HmSpace.xs,
                    child: _SaveButton(
                      saved: _saved,
                      onPressed: _toggleSaved,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HmSpace.xl,
                  vertical: HmSpace.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      property.priceLabel(context.text, short: true),
                      style: HmText.price.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: HmSpace.sm),
                    Text(
                      property.title,
                      style: HmText.label.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: HmSpace.xxs),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 13, color: HmColors.textBody),
                        const SizedBox(width: HmSpace.xs),
                        Expanded(
                          child: Text(
                            property.locationLabel,
                            style: HmText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HmSpace.sm),
                    Text(
                      _factsLine(property),
                      style: HmText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  /// "3 Bed · 2 Bath · 95 m²" — the design's run-on line, which fits where
  /// three icon-and-number pairs would not.
  String _factsLine(PropertySummary property) => propertyFacts(context.text, property).join(' · ');

  Widget _vertical(PropertySummary property) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _maybeExpanded(
              Stack(
                fit: widget.fillHeight ? StackFit.expand : StackFit.loose,
                children: [
                  PropertyImage(
                    mediaId: property.coverMediaId,
                    height: widget.fillHeight ? null : (widget.compact ? 120 : 176),
                    borderRadius: BorderRadius.zero,
                  ),
                  Positioned(
                    top: HmSpace.md,
                    right: HmSpace.md,
                    child: _SaveButton(saved: _saved, onPressed: _toggleSaved),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(HmSpace.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: HmText.heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: HmSpace.xs),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: HmColors.textSecondary),
                      const SizedBox(width: HmSpace.xs),
                      Expanded(
                        child: Text(
                          property.locationLabel,
                          style: HmText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Facts above the price, each on its own line, as the
                  // designs have it: side by side, a seven-figure rent wraps
                  // to three lines and takes the card's layout with it.
                  const SizedBox(height: HmSpace.md),
                  _Facts(property: property),
                  const SizedBox(height: HmSpace.md),
                  Text(
                    property.priceLabel(context.text, short: true),
                    style: HmText.price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onPressed, this.dense = false});

  final bool saved;
  final VoidCallback onPressed;

  /// The 100pt-wide photo on a horizontal card has no room for a 48pt tap
  /// target, so this one is drawn smaller — still 32pt, which stays above the
  /// minimum a thumb can reliably hit.
  final bool dense;

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.bgPrimary.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: IconButton(
          // The label says what tapping does, not what the icon looks like.
          tooltip: saved ? context.text.savedRemove : context.text.savedAdd,
          onPressed: onPressed,
          iconSize: dense ? 16 : 20,
          padding: dense ? const EdgeInsets.all(HmSpace.md) : null,
          constraints: dense ? const BoxConstraints.tightFor(width: 32, height: 32) : null,
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_outline,
            color: saved ? HmColors.error : HmColors.textSecondary,
            size: dense ? 16 : 20,
          ),
        ),
      );
}

/// Bedrooms, bathrooms and size — only the ones actually recorded.
class _Facts extends StatelessWidget {
  const _Facts({required this.property});

  final PropertySummary property;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      if (property.bedrooms != null) (Icons.bed_outlined, '${property.bedrooms}'),
      if (property.bathrooms != null) (Icons.shower_outlined, '${property.bathrooms}'),
      if (property.sizeSqm != null) (Icons.square_foot, '${property.sizeSqm!.round()}m²'),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final (icon, label) in facts) ...[
          Icon(icon, size: 15, color: HmColors.textSecondary),
          const SizedBox(width: HmSpace.xs),
          Flexible(
            child: Text(
              label,
              style: HmText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: HmSpace.xl),
        ],
      ],
    );
  }
}
