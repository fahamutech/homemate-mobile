import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/config/env.dart';
import '../../../../../design/tokens.dart';

/// A map with a pin fixed in the middle: the home is wherever the map is
/// moved to put the pin on the entrance.
class PinPicker extends StatefulWidget {
  const PinPicker({super.key, required this.center, required this.onMoved, required this.hint});

  final LatLng center;
  final ValueChanged<LatLng> onMoved;
  final String hint;

  @override
  State<PinPicker> createState() => _PinPickerState();
}

class _PinPickerState extends State<PinPicker> {
  final _map = MapController();

  @override
  void didUpdateWidget(PinPicker old) {
    super.didUpdateWidget(old);
    if (old.center != widget.center) {
      try {
        _map.move(widget.center, 16);
      } catch (_) {
        // Not laid out yet; the initial centre applies instead.
      }
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(HmRadius.md),
        child: SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: widget.center,
                  initialZoom: 16,
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) widget.onMoved(camera.center);
                  },
                ),
                children: [TileLayer(urlTemplate: Env.mapTileUrl, userAgentPackageName: Env.mapUserAgent)],
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Icon(Icons.location_on_rounded, size: 40, color: HmColors.brandPrimary),
              ),
              Positioned(
                bottom: HmSpace.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: HmSpace.xl, vertical: HmSpace.xs),
                  decoration: BoxDecoration(color: HmColors.bgPrimary, borderRadius: BorderRadius.circular(HmRadius.pill)),
                  child: Text(widget.hint, style: HmText.caption.copyWith(color: HmColors.textPrimary)),
                ),
              ),
            ],
          ),
        ),
      );
}
