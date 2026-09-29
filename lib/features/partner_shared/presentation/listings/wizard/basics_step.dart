import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../core/providers.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_choice.dart';
import '../../../../../design/widgets/hm_counter.dart';
import '../../../../../design/widgets/hm_feedback.dart';
import '../../../../../design/widgets/hm_segmented.dart';
import '../../../../../design/widgets/hm_text_field.dart';
import '../../../data/partner_listing.dart';
import 'step_controller.dart';

/// BRK-030a: what the home is.
class BasicsStep extends ConsumerStatefulWidget {
  const BasicsStep({super.key, required this.listing, required this.controller});

  final PartnerListing? listing;
  final WizardStepController controller;

  @override
  ConsumerState<BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends ConsumerState<BasicsStep> {
  late final _title = TextEditingController(text: widget.listing?.title ?? '');
  late final _description = TextEditingController(text: widget.listing?.description ?? '');
  late final _size = TextEditingController(text: widget.listing?.sizeSqm == null ? '' : '${widget.listing!.sizeSqm!.round()}');
  late String? _type = widget.listing?.propertyTypeId;
  late int _bedrooms = widget.listing?.bedrooms ?? 0;
  late int _bathrooms = widget.listing?.bathrooms ?? 1;
  late String _furnishing = widget.listing?.furnishing ?? 'unfurnished';
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.collect = _collect;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _size.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _collect() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = context.text.wizardTitleRequired);
      return null;
    }
    setState(() => _error = null);
    return {
      'title': _title.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'propertyTypeId': _type,
      'bedrooms': _bedrooms,
      'bathrooms': _bathrooms,
      'sizeSqm': double.tryParse(_size.text.trim()),
      'furnishing': _furnishing,
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final types = ref.watch(referenceDataProvider).valueOrNull?.propertyTypes ?? const [];
    const gap = SizedBox(height: HmSpace.xxl);

    return ListView(
      padding: const EdgeInsets.all(HmSpace.xxl),
      children: [
        HmInlineError(_error),
        HmTextField(fieldKey: const ValueKey('wizard-title'), label: text.wizardTitleField, controller: _title, hint: text.wizardTitleHint),
        gap,
        HmTextField(label: text.wizardDescription, controller: _description, maxLines: 4),
        gap,
        Text(text.wizardPropertyType, style: HmText.label.copyWith(fontSize: 14)),
        const SizedBox(height: HmSpace.sm),
        Wrap(
          spacing: HmSpace.md,
          runSpacing: HmSpace.md,
          children: [
            for (final type in types)
              HmChoicePill(
                label: type.name,
                dense: true,
                showCheck: true,
                selected: _type == type.id,
                onTap: () => setState(() => _type = type.id),
              ),
          ],
        ),
        gap,
        Row(children: [
          Expanded(child: HmCounter(label: text.wizardBedrooms, value: _bedrooms, max: 20, onChanged: (v) => setState(() => _bedrooms = v))),
          const SizedBox(width: HmSpace.xl),
          Expanded(child: HmCounter(label: text.wizardBathrooms, value: _bathrooms, max: 20, onChanged: (v) => setState(() => _bathrooms = v))),
        ]),
        gap,
        HmTextField(
          label: text.wizardSize,
          controller: _size,
          hint: text.wizardSizeHint,
          keyboardType: TextInputType.number,
          trailingIcon: Icons.square_foot_rounded,
        ),
        gap,
        HmSegmented<String>(
          label: text.wizardFurnishing,
          options: [
            ('unfurnished', text.wizardFurnishingNone),
            ('semi_furnished', text.wizardFurnishingSemi),
            ('fully_furnished', text.wizardFurnishingFully),
          ],
          value: _furnishing,
          onChanged: (value) => setState(() => _furnishing = value),
        ),
      ],
    );
  }
}
