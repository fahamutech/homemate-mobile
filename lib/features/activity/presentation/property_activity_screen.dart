import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_section.dart';
import '../../../design/widgets/hm_timeline.dart';
import '../../../routing/app_router.dart';
import '../../discovery/data/search_providers.dart';
import '../../shared/journey_providers.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';

/// CUS-013b. Everything that has happened between this customer and one
/// property, in order.
///
/// Reached from My Activity and from a rental. It is deliberately per-property
/// rather than a single global feed: a customer's question is almost always
/// "where am I with *that* house", and a merged stream of six properties
/// answers it worse than six short ones.
class PropertyActivityScreen extends ConsumerWidget {
  const PropertyActivityScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(propertyJourneyProvider(propertyId));
    final property = ref.watch(propertyDetailProvider(propertyId));

    return HmScaffold(
      title: 'My Activity',
      padded: false,
      backgroundColor: HmColors.bgSecondary,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(propertyJourneyProvider(propertyId));
          ref.invalidate(propertyDetailProvider(propertyId));
        },
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, HmSpace.section),
          children: [
            // The property header renders from whatever has already loaded;
            // the timeline below it is the point of the screen and must not
            // wait on it.
            property.maybeWhen(
              data: (detail) => _PropertyHeader(summary: detail.summary),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: HmSpace.huge),

            const HmSectionHeader(title: 'Journey Timeline'),
            HmAsync(
              value: journey,
              onRetry: () => ref.invalidate(propertyJourneyProvider(propertyId)),
              emptyWhen: (events) => events.isEmpty,
              empty: const HmEmpty(
                title: 'Nothing here yet',
                message: 'Enquire about this home and every step — the landlord’s answer, '
                    'your payment, its verification — will be recorded here.',
                icon: Icons.timeline_outlined,
              ),
              data: (events) => HmCard(child: HmTimeline(events: events)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({required this.summary});

  final PropertySummary summary;

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        child: InkWell(
          onTap: () => context.push(Routes.property(summary.id)),
          borderRadius: HmRadius.card,
          child: Container(
            padding: const EdgeInsets.all(HmSpace.xl),
            decoration: BoxDecoration(
              borderRadius: HmRadius.card,
              border: Border.all(color: HmColors.borderDefault),
            ),
            child: Row(
              children: [
                PropertyImage(
                  mediaId: summary.coverMediaId,
                  height: 76,
                  width: 76,
                  borderRadius: BorderRadius.circular(HmRadius.sm),
                ),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        summary.title,
                        style: HmText.heading.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: HmSpace.sm),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 13, color: HmColors.textSecondary),
                          const SizedBox(width: HmSpace.xs),
                          Expanded(
                            child: Text(
                              summary.locationLabel,
                              style: HmText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: HmSpace.sm),
                      Text(
                        summary.priceLabelShort,
                        style: HmText.label.copyWith(fontSize: 14, color: HmColors.brandPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
