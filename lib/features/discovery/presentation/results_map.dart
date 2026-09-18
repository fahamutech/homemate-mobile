import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/env.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../shared/models.dart';
import '../../shared/property_card.dart';

/// CUS-003a/b. Results on an OpenStreetMap, with the selected one in a card.
///
/// OSM rather than a proprietary SDK: it needs no API key, works offline in a
/// test, and the tile server is configurable so a deployment can point at its
/// own cache instead of the public one.
class ResultsMap extends StatefulWidget {
  const ResultsMap({super.key, required this.properties});

  final List<PropertySummary> properties;

  @override
  State<ResultsMap> createState() => _ResultsMapState();
}

class _ResultsMapState extends State<ResultsMap> {
  PropertySummary? _selected;

  /// Only listings with coordinates can be pinned; the rest are still in the
  /// list view, so nothing is lost by leaving them off the map.
  List<PropertySummary> get _mappable =>
      widget.properties.where((property) => property.hasLocation).toList();

  LatLng get _centre {
    final mappable = _mappable;
    if (mappable.isEmpty) {
      return LatLng(Env.defaultLatitude, Env.defaultLongitude);
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
    final mappable = _mappable;
    if (mappable.isEmpty) {
      return const HmEmpty(
        title: 'No pins to show',
        message: 'These listings have no map location yet. Try the list view.',
        icon: Icons.map_outlined,
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _centre,
            initialZoom: 12,
            // Tapping the map itself dismisses the card, the way the design
            // shows — there is no other way to deselect.
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: Env.mapTileUrl,
              userAgentPackageName: Env.mapUserAgent,
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
        if (_selected != null)
          Positioned(
            left: HmSpace.xxl,
            right: HmSpace.xxl,
            bottom: HmSpace.xxl,
            child: PropertyCard(property: _selected!, compact: true),
          ),
        Positioned(
          right: HmSpace.xxl,
          top: HmSpace.xxl,
          child: _Attribution(),
        ),
      ],
    );
  }
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
