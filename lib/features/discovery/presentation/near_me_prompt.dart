import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
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

    final text = context.text;
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
                child: Text(state.promptTitle(text), style: HmText.heading.copyWith(fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: HmSpace.xl),
          Text(state.promptMessage(text), style: HmText.caption.copyWith(fontSize: 13)),
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
                      : Text(state.promptAction(text)),
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: OutlinedButton(
                  onPressed: onChooseArea,
                  child: Text(text.chooseArea),
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
              child: Text(text.recheckLocation),
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
                  ? context.text.nearPlace(state.manualPlaceName!)
                  : context.text.sortedByDistance,
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
                context.text.change,
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
  ///
  /// The unit is part of the translated phrase rather than appended to the
  /// number, because Kiswahili puts it in front: "mita 300", not "300 mita".
  static String format(AppText text, double metres) {
    if (metres < 950) return text.metresAway('${(metres / 100).round() * 100}');
    final km = metres / 1000;
    return text.kilometresAway(km < 10 ? km.toStringAsFixed(1) : '${km.round()}');
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
          format(context.text, value),
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
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: HmRadius.sheet),
    builder: (_) => _AreaPickerSheet(onSelected: (place) => _applyArea(ref, place)),
  );
}

/// The sheet owns its own controller so the field's lifetime matches the
/// sheet's element, not the `showModalBottomSheet` future: the sheet keeps
/// rebuilding all through its dismissal animation, which is after that future
/// completes.
class _AreaPickerSheet extends StatefulWidget {
  const _AreaPickerSheet({required this.onSelected});

  final ValueChanged<GeoPlace> onSelected;

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.huge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.areaPickerTitle, style: HmText.heading),
              const SizedBox(height: HmSpace.md),
              Text(text.areaPickerMessage, style: HmText.caption),
              const SizedBox(height: HmSpace.xxl),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: text.areaPickerHint,
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: HmSpace.xl),
              // Loose so the results give way to the keyboard rather than
              // overflowing the sheet.
              Flexible(
                child: SizedBox(
                  height: 240,
                  child: _query.length < 3
                      ? Center(child: Text(text.areaPickerMinLetters, style: HmText.caption))
                      : Consumer(
                          builder: (context, innerRef, _) {
                            final places = innerRef.watch(placeSearchProvider(_query));
                            return places.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => Center(
                                child: Text(text.areaPickerFailed, style: HmText.caption),
                              ),
                              data: (results) => results.isEmpty
                                  ? Center(child: Text(text.areaPickerNone, style: HmText.caption))
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
                                            widget.onSelected(place);
                                            Navigator.of(context).pop();
                                          },
                                        );
                                      },
                                    ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
