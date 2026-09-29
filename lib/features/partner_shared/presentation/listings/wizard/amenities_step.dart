import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../core/providers.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_badge.dart';
import '../../../../../design/widgets/hm_button.dart';
import '../../../../../design/widgets/hm_choice.dart';
import '../../../../../design/widgets/hm_counter.dart';
import '../../../../../design/widgets/hm_money.dart';
import '../../../../../design/widgets/hm_section.dart';
import '../../../data/partner_listing.dart';
import 'charge_sheet.dart';
import 'step_controller.dart';
import '../../../../shared/reference_name.dart';

/// BRK-030d: amenities, house rules, and charges on top of rent.
class AmenitiesStep extends ConsumerStatefulWidget {
  const AmenitiesStep({super.key, required this.listing, required this.controller});

  final PartnerListing listing;
  final WizardStepController controller;

  @override
  ConsumerState<AmenitiesStep> createState() => _AmenitiesStepState();
}

class _AmenitiesStepState extends ConsumerState<AmenitiesStep> {
  late final Set<String> _amenities = {...widget.listing.amenityIds};
  late final List<ListingCharge> _charges = [...widget.listing.charges];
  late bool _pets = widget.listing.petsAllowed;
  late bool _smoking = widget.listing.smokingAllowed;
  late int _occupants = widget.listing.maxOccupants ?? 2;

  @override
  void initState() {
    super.initState();
    widget.controller.collect = () => {
          'amenityIds': _amenities.toList(),
          'petsAllowed': _pets,
          'smokingAllowed': _smoking,
          'maxOccupants': _occupants,
          'charges': [for (final charge in _charges) charge.toJson()],
        };
  }

  Future<void> _editCharge([int? index]) async {
    final result = await showChargeSheet(context, charge: index == null ? null : _charges[index]);
    if (result == null) return;
    setState(() => index == null ? _charges.add(result) : _charges[index] = result);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final amenities = ref.watch(referenceDataProvider).valueOrNull?.amenities ?? const [];
    const gap = SizedBox(height: HmSpace.xxl);

    return ListView(
      padding: const EdgeInsets.all(HmSpace.xxl),
      children: [
        Text(text.wizardAmenities, style: HmText.label.copyWith(fontSize: 14)),
        const SizedBox(height: HmSpace.sm),
        Wrap(
          spacing: HmSpace.md,
          runSpacing: HmSpace.md,
          children: [
            for (final amenity in amenities)
              HmChoicePill(
                label: referenceName(context.text, code: amenity.code, name: amenity.name),
                dense: true,
                showCheck: true,
                selected: _amenities.contains(amenity.id),
                onTap: () => setState(() => _amenities.contains(amenity.id) ? _amenities.remove(amenity.id) : _amenities.add(amenity.id)),
              ),
          ],
        ),
        gap,
        HmCard(
          title: text.wizardHouseRules,
          child: Column(
            children: [
              SwitchListTile(
                value: _pets,
                onChanged: (v) => setState(() => _pets = v),
                contentPadding: EdgeInsets.zero,
                title: Text(text.wizardPets),
              ),
              SwitchListTile(
                value: _smoking,
                onChanged: (v) => setState(() => _smoking = v),
                contentPadding: EdgeInsets.zero,
                title: Text(text.wizardSmoking),
              ),
              HmCounter(label: text.wizardMaxOccupants, value: _occupants, min: 1, max: 30, onChanged: (v) => setState(() => _occupants = v)),
            ],
          ),
        ),
        gap,
        Text(text.wizardCharges, style: HmText.label.copyWith(fontSize: 14)),
        Text(text.wizardChargesHint, style: HmText.caption),
        const SizedBox(height: HmSpace.md),
        for (final (index, charge) in _charges.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: HmSpace.md),
            child: HmCard(
              padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl, vertical: HmSpace.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(charge.name, style: HmText.label.copyWith(fontSize: 15)),
                        Text(HmMoney.format(charge.amount), style: HmText.caption),
                      ],
                    ),
                  ),
                  if (charge.isMandatory) HmBadge(label: text.wizardChargeRequired),
                  IconButton(onPressed: () => _editCharge(index), tooltip: text.wizardEdit, icon: const Icon(Icons.edit_outlined, size: 18)),
                  IconButton(
                    onPressed: () => setState(() => _charges.removeAt(index)),
                    tooltip: text.wizardRemoveCharge,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        HmButton(label: text.wizardAddCharge, icon: Icons.add_rounded, style: HmButtonStyle.soft, onPressed: _editCharge),
      ],
    );
  }
}
