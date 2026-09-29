import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../core/location/location_providers.dart';
import '../../../../../core/providers.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_badge.dart';
import '../../../../../design/widgets/hm_button.dart';
import '../../../../../design/widgets/hm_feedback.dart';
import '../../../../../design/widgets/hm_note.dart';
import '../../../../../design/widgets/hm_text_field.dart';
import '../../../../shared/models.dart';
import '../../../data/partner_listing.dart';
import 'pin_picker.dart';
import 'step_controller.dart';

/// BRK-030b: region → district → ward, the street, and the pin.
class LocationStep extends ConsumerStatefulWidget {
  const LocationStep({super.key, required this.listing, required this.controller});

  final PartnerListing listing;
  final WizardStepController controller;

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> {
  late String? _region = widget.listing.regionId;
  late String? _district = widget.listing.districtId;
  late String? _ward = widget.listing.wardId;
  late final _street = TextEditingController(text: widget.listing.addressLine ?? '');
  late LatLng? _pin = widget.listing.hasPin ? LatLng(widget.listing.latitude!, widget.listing.longitude!) : null;
  bool _locating = false;

  /// Dar es Salaam, where the map opens when there is no pin yet.
  static const _dar = LatLng(-6.7924, 39.2083);

  @override
  void initState() {
    super.initState();
    widget.controller.collect = () => {
          'regionId': _region,
          'districtId': _district,
          'wardId': _ward,
          'addressLine': _street.text.trim().isEmpty ? null : _street.text.trim(),
          if (_pin != null) 'latitude': _pin!.latitude,
          if (_pin != null) 'longitude': _pin!.longitude,
        };
  }

  @override
  void dispose() {
    _street.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final result = await ref.read(locationServiceProvider).request();
      if (result.hasPosition) {
        setState(() => _pin = LatLng(result.latitude!, result.longitude!));
      }
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Widget _picker(String label, List<ReferenceItem> items, String? value, ValueChanged<String?> onChanged, String key) =>
      DropdownButtonFormField<String>(
        key: ValueKey(key),
        initialValue: items.any((i) => i.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [for (final item in items) DropdownMenuItem(value: item.id, child: Text(item.name))],
        onChanged: onChanged,
      );

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final reference = ref.watch(referenceDataProvider).valueOrNull ?? const ReferenceData();
    const gap = SizedBox(height: HmSpace.xxl);

    return ListView(
      padding: const EdgeInsets.all(HmSpace.xxl),
      children: [
        _picker(text.wizardRegion, reference.regions, _region, (v) => setState(() {
              _region = v;
              _district = null;
              _ward = null;
            }), 'wizard-region'),
        gap,
        Row(children: [
          Expanded(
            child: _picker(text.wizardDistrict, reference.districtsIn(_region), _district, (v) => setState(() {
                  _district = v;
                  _ward = null;
                }), 'wizard-district'),
          ),
          const SizedBox(width: HmSpace.xl),
          Expanded(child: _picker(text.wizardWard, reference.wardsIn(_district), _ward, (v) => setState(() => _ward = v), 'wizard-ward')),
        ]),
        gap,
        HmTextField(
          fieldKey: const ValueKey('wizard-street'),
          label: text.wizardStreet,
          controller: _street,
          leadingIcon: Icons.signpost_outlined,
        ),
        gap,
        PinPicker(center: _pin ?? _dar, hint: text.wizardPinHint, onMoved: (point) => setState(() => _pin = point)),
        const SizedBox(height: HmSpace.xl),
        if (_pin != null) ...[
          Align(alignment: Alignment.centerLeft, child: HmBadge(label: text.wizardPinSet, tone: HmBadgeTone.success, icon: Icons.check_rounded)),
          const SizedBox(height: HmSpace.xl),
        ],
        HmButton(
          label: text.wizardUseLocation,
          icon: Icons.my_location_rounded,
          style: HmButtonStyle.outline,
          busy: _locating,
          onPressed: _useMyLocation,
        ),
        const SizedBox(height: HmSpace.xl),
        HmNote(text: text.wizardPinNote),
      ],
    );
  }
}
