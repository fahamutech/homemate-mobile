import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../design/widgets/hm_feedback.dart';
import '../../routing/app_router.dart';
import 'models.dart';
import 'property_image.dart';

/// One listing, as it appears on the home screen, in results, and in the saved
/// list. All three used the same card in the designs, so they use the same
/// widget here — a second "saved card" is how the two drift apart.
class PropertyCard extends ConsumerStatefulWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.onSavedChanged,
    this.compact = false,
  });

  final PropertySummary property;

  /// Lets the containing list update its own copy, so the heart does not snap
  /// back when the screen rebuilds from cached data.
  final ValueChanged<bool>? onSavedChanged;
  final bool compact;

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
    } catch (error) {
      if (!mounted) return;
      setState(() => _saved = !next);
      HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.property(property.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PropertyImage(
                  mediaId: property.coverMediaId,
                  height: widget.compact ? 120 : 176,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  top: HmSpace.md,
                  right: HmSpace.md,
                  child: _SaveButton(saved: _saved, onPressed: _toggleSaved),
                ),
              ],
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
                  const SizedBox(height: HmSpace.xl),
                  Row(
                    children: [
                      Expanded(child: Text(property.priceLabel, style: HmText.price)),
                      _Facts(property: property),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onPressed});

  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.bgPrimary.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: IconButton(
          // The label says what tapping does, not what the icon looks like.
          tooltip: saved ? 'Remove from saved' : 'Save this property',
          onPressed: onPressed,
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_outline,
            color: saved ? HmColors.error : HmColors.textSecondary,
            size: 20,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (icon, label) in facts) ...[
          Icon(icon, size: 15, color: HmColors.textSecondary),
          const SizedBox(width: HmSpace.xs),
          Text(label, style: HmText.caption),
          const SizedBox(width: HmSpace.xl),
        ],
      ],
    );
  }
}
