import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/env.dart';
import '../../../core/i18n/app_text.dart';
import '../../../core/location/location_providers.dart';
import '../../../design/tokens.dart';
import '../../shared/catalogue_repository.dart';
import '../../shared/models.dart';
import '../../shared/property_card.dart';
import '../data/search_providers.dart';
import 'near_me_prompt.dart';

/// CUS-003a/b. Results on an OpenStreetMap, with the selected one in a card.
///
/// OSM rather than a proprietary SDK: it needs no API key, works offline in a
/// test, and the tile server is configurable so a deployment can point at its
/// own cache instead of the public one.
///
/// Where it opens follows the same rule as the Near You section: the
/// customer's own position when they have shared it, the area they picked
/// when they picked one, and the configured city centre otherwise. The map is
/// therefore never blank and never silently centred on the wrong place — and
/// the permission is asked for here in exactly the same explained, tappable
/// way, never as a prompt that fires because a map appeared.
class ResultsMap extends ConsumerStatefulWidget {
  const ResultsMap({super.key, required this.properties});

  final List<PropertySummary> properties;

  @override
  ConsumerState<ResultsMap> createState() => _ResultsMapState();
}

class _ResultsMapState extends ConsumerState<ResultsMap> {
  PropertySummary? _selected;
  final MapController _controller = MapController();

  /// Where the map is looking now, once the customer has dragged it. Null
  /// until they do — a "Search this area" button that appears before anybody
  /// has moved anything is a control with nothing to do.
  LatLng? _pannedTo;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Re-run the search around whatever is now in the middle of the screen.
  void _searchHere() {
    final centre = _pannedTo;
    if (centre == null) return;
    ref.read(searchFiltersProvider.notifier).setArea(
          latitude: centre.latitude,
          longitude: centre.longitude,
          radiusMetres: PropertyFilters.defaultRadiusMetres,
        );
    setState(() => _pannedTo = null);
  }

  void _recentre(NearMeState state) {
    _controller.move(LatLng(state.latitude!, state.longitude!), 14);
    setState(() => _pannedTo = null);
  }

  /// Recentre on the point we already have, and only ask for location when we
  /// have none. A manually chosen area counts as a position while permission is
  /// still refused, so going through `enable()` here would answer "centre the
  /// map" by dropping the customer in the OS settings app.
  Future<void> _goToMyPlaces() async {
    final current = ref.read(nearMeProvider);
    if (current.hasPosition) {
      _recentre(current);
      return;
    }

    await ref.read(nearMeProvider.notifier).enable();
    if (!mounted) return;
    final state = ref.read(nearMeProvider);
    if (state.hasPosition) _recentre(state);
  }

  /// Only listings with coordinates can be pinned; the rest are still in the
  /// list view, so nothing is lost by leaving them off the map.
  List<PropertySummary> get _mappable =>
      widget.properties.where((property) => property.hasLocation).toList();

  LatLng get _centre {
    // The customer's own position wins over the average of the pins: a map
    // that opens on "where you are" and then shows what is around you is the
    // one people expect, and the pins are visible from there anyway.
    final focus = ref.read(mapFocusProvider);
    if (focus.isPrecise) return LatLng(focus.latitude, focus.longitude);

    final mappable = _mappable;
    if (mappable.isEmpty) {
      return LatLng(focus.latitude, focus.longitude);
    }
    // The average of the pins, so every result is roughly in frame.
    final latitude =
        mappable.map((p) => p.latitude!).reduce((a, b) => a + b) / mappable.length;
    final longitude =
        mappable.map((p) => p.longitude!).reduce((a, b) => a + b) / mappable.length;
    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    final nearMe = ref.watch(nearMeProvider);
    final mappable = _mappable;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _centre,
            initialZoom: nearMe.hasPosition ? 14 : 12,
            // Tapping the map itself dismisses the card, the way the design
            // shows — there is no other way to deselect.
            onTap: (_, __) => setState(() => _selected = null),
            onPositionChanged: (position, hasGesture) {
              // Only a drag arms "Search this area"; a programmatic move —
              // ours, going to the customer's location — must not.
              if (!hasGesture) return;
              setState(() => _pannedTo = position.center);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: Env.mapTileUrl,
              userAgentPackageName: Env.mapUserAgent,
            ),
            if (nearMe.hasPosition && !nearMe.isManual)
              // A plain blue dot for "you are here", drawn under the pins so
              // it never covers a listing.
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(nearMe.latitude!, nearMe.longitude!),
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: HmColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: HmColors.bgPrimary, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final property in mappable)
                  Marker(
                    point: LatLng(property.latitude!, property.longitude!),
                    width: 92,
                    height: 40,
                    child: _PriceMarker(
                      property: property,
                      selected: _selected?.id == property.id,
                      onTap: () => setState(() => _selected = property),
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Nothing to pin is not an error — the map still shows where you are,
        // and the message sits over it rather than replacing it.
        if (mappable.isEmpty)
          Positioned(
            left: HmSpace.xxl,
            right: HmSpace.xxl,
            top: 64,
            child: _Floating(
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, size: 18, color: HmColors.textSecondary),
                  const SizedBox(width: HmSpace.xl),
                  Expanded(
                    child: Text(
                      context.text.mapNoPins,
                      style: HmText.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // The explain-and-ask card, on the map this time. Same rule as the
        // home screen: the OS is never asked until this is tapped.
        if (nearMe.needsPrompt)
          Positioned(
            left: HmSpace.xxl,
            right: HmSpace.xxl,
            bottom: _selected == null ? HmSpace.xxl : 150,
            child: _Floating(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(nearMe.promptTitle(context.text), style: HmText.label.copyWith(fontSize: 14)),
                  const SizedBox(height: HmSpace.xs),
                  Text(
                    nearMe.canAskAgain
                        ? context.text.mapCentreHint
                        : nearMe.promptMessage(context.text),
                    style: HmText.caption,
                  ),
                  const SizedBox(height: HmSpace.xl),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: nearMe.isBusy ? null : _goToMyPlaces,
                          child: Text(nearMe.promptAction(context.text)),
                        ),
                      ),
                      const SizedBox(width: HmSpace.md),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showAreaPicker(context, ref),
                          child: Text(context.text.askMe),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        if (_selected != null)
          Positioned(
            left: HmSpace.xxl,
            right: HmSpace.xxl,
            bottom: HmSpace.xxl,
            child: PropertyCard(property: _selected!, compact: true),
          ),

        // "Search this area", which appears only once the customer has moved
        // the map somewhere the current results do not describe.
        if (_pannedTo != null)
          Positioned(
            top: HmSpace.xxl,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: HmColors.bgPrimary,
                borderRadius: BorderRadius.circular(HmRadius.pill),
                elevation: 3,
                child: InkWell(
                  onTap: _searchHere,
                  borderRadius: BorderRadius.circular(HmRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: HmSpace.xxl,
                      vertical: HmSpace.lg,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 16, color: HmColors.brandPrimary),
                        const SizedBox(width: HmSpace.md),
                        Text(
                          context.text.searchThisArea,
                          style: HmText.label.copyWith(
                            fontSize: 13,
                            color: HmColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (nearMe.hasPosition)
          Positioned(
            right: HmSpace.xxl,
            bottom: _selected == null ? 72 : 160,
            child: FloatingActionButton.small(
              onPressed: _goToMyPlaces,
              tooltip: context.text.recentre,
              backgroundColor: HmColors.bgPrimary,
              foregroundColor: HmColors.brandPrimary,
              child: const Icon(Icons.my_location),
            ),
          ),

        Positioned(
          right: HmSpace.xxl,
          top: nearMe.needsPrompt || _pannedTo != null ? 60 : HmSpace.xxl,
          child: _Attribution(),
        ),
      ],
    );
  }
}

/// A panel that floats over the map without hiding it.
class _Floating extends StatelessWidget {
  const _Floating({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(HmSpace.xl),
        decoration: BoxDecoration(
          color: HmColors.bgPrimary,
          borderRadius: HmRadius.card,
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      );
}

/// The price as the pin, which is what the designs show — a generic dot makes
/// a customer tap every one to find out what it costs.
class _PriceMarker extends StatelessWidget {
  const _PriceMarker({required this.property, required this.selected, required this.onTap});

  final PropertySummary property;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = property.price;
    final label = price == null
        ? '—'
        : price >= 1000000
            ? '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M'
            : '${(price / 1000).round()}K';

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: HmSpace.xl, vertical: HmSpace.sm),
          decoration: BoxDecoration(
            color: selected ? HmColors.brandPrimary : HmColors.bgPrimary,
            borderRadius: BorderRadius.circular(HmRadius.pill),
            border: Border.all(color: HmColors.brandPrimary),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            label,
            semanticsLabel: '${property.title}, ${property.priceLabel}',
            style: HmText.caption.copyWith(
              color: selected ? HmColors.textOnBrand : HmColors.brandPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Required by the OpenStreetMap tile usage policy.
class _Attribution extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.md, vertical: HmSpace.xxs),
        decoration: BoxDecoration(
          color: HmColors.bgPrimary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(HmRadius.sm),
        ),
        child: const Text('© OpenStreetMap', style: TextStyle(fontSize: 10)),
      );
}
