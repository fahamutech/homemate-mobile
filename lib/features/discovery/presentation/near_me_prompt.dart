import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_providers.dart';
import '../../../core/location/location_service.dart';
import '../../../design/tokens.dart';
import '../../shared/catalogue_repository.dart';
import '../../shared/models.dart';
import '../data/search_providers.dart';

/// The card that stands in for a location permission dialog.
///
/// HomeMate never shows the operating system's prompt on launch. On iOS that
/// prompt can be spent exactly once, and spending it on someone who has not
/// yet seen a single listing is how an app ends up permanently unable to ask.
/// So the sequence is Airbnb's:
///
///   1. **Explain first.** This card says what location buys — listings
///      ordered nearest to furthest — before anything is requested.
///   2. **Ask only on a tap.** The OS prompt appears when the customer presses
///      the button, and never otherwise.
///   3. **Never dead-end.** A refusal that can be undone leads to Settings; a
///      refusal that cannot still leaves "Choose an area instead", so Near Me
///      works for someone who will never grant location at all.
class NearMePrompt extends ConsumerWidget {
  const NearMePrompt({super.key, required this.onChooseArea});

  /// Opens the place picker. The way out of every refusal.
  final VoidCallback onChooseArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nearMeProvider);
    if (!state.needsPrompt) return const SizedBox.shrink();

    final isBlocked = !state.canAskAgain;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HmSpace.xxl),
      decoration: BoxDecoration(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        border: Border.all(
          color: isBlocked ? HmColors.warning.withValues(alpha: 0.4) : HmColors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isBlocked ? HmColors.warning : HmColors.brandPrimary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(HmRadius.sm),
                ),
                child: Icon(
                  switch (state.availability) {
                    LocationAvailability.serviceDisabled => Icons.location_disabled_outlined,
                    LocationAvailability.deniedForever => Icons.lock_outline,
                    _ => Icons.near_me_outlined,
                  },
                  size: 18,
                  color: isBlocked ? HmColors.warning : HmColors.brandPrimary,
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Text(state.promptTitle, style: HmText.heading.copyWith(fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: HmSpace.xl),
          Text(state.promptMessage, style: HmText.caption.copyWith(fontSize: 13)),
          const SizedBox(height: HmSpace.xxl),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: state.isBusy
                      ? null
                      : () => ref.read(nearMeProvider.notifier).enable(),
                  child: state.isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HmColors.textOnBrand,
                          ),
                        )
                      : Text(state.promptAction),
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: OutlinedButton(
                  onPressed: onChooseArea,
                  child: const Text('Choose an area'),
                ),
              ),
            ],
          ),
          if (isBlocked) ...[
            const SizedBox(height: HmSpace.md),
            // Returning from Settings does not rebuild this card by itself, so
            // there has to be a way to say "I have done it" — otherwise the
            // customer grants permission and the app carries on claiming it is
            // blocked.
            TextButton(
              onPressed: () => ref.read(nearMeProvider.notifier).recheck(),
              child: const Text('I have allowed it — check again'),
            ),
          ],
        ],
      ),
    );
  }
}

/// The line above the Near You listings once we do have a position — "Sorted
/// by distance from you", or the area they picked instead, with a way to
/// change it.
class NearMeSource extends ConsumerWidget {
  const NearMeSource({super.key, required this.onChooseArea});

  final VoidCallback onChooseArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nearMeProvider);
    if (!state.canSearchNearby) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: HmSpace.xl),
      child: Row(
        children: [
          Icon(
            state.isManual ? Icons.place_outlined : Icons.my_location,
            size: 14,
            color: HmColors.brandPrimary,
          ),
          const SizedBox(width: HmSpace.md),
          Expanded(
            child: Text(
              state.isManual
                  ? 'Near ${state.manualPlaceName}'
                  : 'Sorted by distance from you',
              style: HmText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onChooseArea,
            borderRadius: BorderRadius.circular(HmRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HmSpace.md,
                vertical: HmSpace.xxs,
              ),
              child: Text(
                'Change',
                style: HmText.label.copyWith(fontSize: 12, color: HmColors.brandPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "How far away" on a listing card, once we know where the customer is.
class DistanceLabel extends StatelessWidget {
  const DistanceLabel({super.key, required this.metres});

  final double? metres;

  /// Below a kilometre people think in metres and above it in kilometres, and
  /// rounding to 100m avoids implying a precision the fix does not have.
  static String format(double metres) {
    if (metres < 950) return '${(metres / 100).round() * 100} m away';
    final km = metres / 1000;
    return '${km < 10 ? km.toStringAsFixed(1) : km.round()} km away';
  }

  @override
  Widget build(BuildContext context) {
    final value = metres;
    if (value == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.near_me_outlined, size: 12, color: HmColors.brandPrimary),
        const SizedBox(width: HmSpace.xs),
        Text(
          format(value),
          style: HmText.caption.copyWith(fontSize: 11, color: HmColors.brandPrimary),
        ),
      ],
    );
  }
}

/// The place picker behind "Choose an area".
///
/// Uses the same OpenStreetMap lookup as the search screen's location field,
/// so a customer who never grants location gets exactly the same Near Me
/// experience, centred wherever they say.
Future<void> showAreaPicker(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: HmRadius.sheet),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.huge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose an area', style: HmText.heading),
              const SizedBox(height: HmSpace.md),
              Text(
                'We will show homes near this place instead of near you.',
                style: HmText.caption,
              ),
              const SizedBox(height: HmSpace.xxl),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Masaki, Mikocheni, Arusha…',
                ),
                onChanged: (_) => (sheetContext as Element).markNeedsBuild(),
              ),
              const SizedBox(height: HmSpace.xl),
              SizedBox(
                height: 240,
                child: Consumer(
                  builder: (context, innerRef, _) {
                    final query = controller.text.trim();
                    if (query.length < 3) {
                      return Center(
                        child: Text(
                          'Type at least three letters.',
                          style: HmText.caption,
                        ),
                      );
                    }
                    final places = innerRef.watch(placeSearchProvider(query));
                    return places.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Center(
                        child: Text('Could not search places.', style: HmText.caption),
                      ),
                      data: (results) => results.isEmpty
                          ? Center(child: Text('No places found.', style: HmText.caption))
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (_, index) {
                                final place = results[index];
                                return ListTile(
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(
                                    place.displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: HmText.body,
                                  ),
                                  onTap: () {
                                    _applyArea(ref, place);
                                    Navigator.of(sheetContext).pop();
                                  },
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  controller.dispose();
}

/// Points both Near Me and the shared search filters at the chosen place, so
/// the home screen and the map agree about where "here" is.
void _applyArea(WidgetRef ref, GeoPlace place) {
  ref.read(nearMeProvider.notifier).useManualArea(
        placeName: place.displayName.split(',').first.trim(),
        latitude: place.latitude,
        longitude: place.longitude,
      );
  ref.read(searchFiltersProvider.notifier).setArea(
        latitude: place.latitude,
        longitude: place.longitude,
        radiusMetres: PropertyFilters.defaultRadiusMetres,
      );
}
