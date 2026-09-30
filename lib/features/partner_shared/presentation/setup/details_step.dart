import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_text_field.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_application.dart';
import '../../data/partner_providers.dart';
import 'setup_frame.dart';

/// BRK-002a / LND-002a "Your details", prefilled from the profile.
class DetailsStep extends ConsumerStatefulWidget {
  const DetailsStep({super.key, required this.role, required this.profile, required this.onDone});

  final AppRole role;
  final PartnerProfile profile;
  final VoidCallback onDone;

  @override
  ConsumerState<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends ConsumerState<DetailsStep> {
  late final _name = TextEditingController(text: widget.profile.fullName ?? '');
  late final _nida = TextEditingController(text: widget.profile.nationalIdNumber ?? '');
  late final _tin = TextEditingController(text: widget.profile.tinNumber ?? '');
  late final _address = TextEditingController(text: widget.profile.physicalAddress ?? '');
  late DateTime? _dob = widget.profile.dateOfBirth;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _nida, _tin, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _complete =>
      _name.text.trim().isNotEmpty && _dob != null && _nida.text.trim().isNotEmpty && _address.text.trim().isNotEmpty;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_complete) {
      setState(() => _error = context.text.partnerDetailsRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingRepositoryProvider).saveDetails(
            widget.role.name,
            PartnerDetails(
              fullName: _name.text.trim(),
              dateOfBirth: _dob,
              nationalIdNumber: _nida.text.trim(),
              tinNumber: _tin.text.trim().isEmpty ? null : _tin.text.trim(),
              physicalAddress: _address.text.trim(),
            ),
          );
      ref.invalidate(applicationsProvider);
      widget.onDone();
    } on ApiException catch (error) {
      setState(() => _error = errorText(context.text, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final phone = ref.watch(authControllerProvider).customer?.phoneNumber ?? '';
    const gap = SizedBox(height: HmSpace.xxl);

    return SetupFrame(
      error: _error,
      actions: [HmButton(label: text.continueLabel, busy: _busy, onPressed: _save)],
      children: [
        Text(text.partnerDetailsIntro, style: HmText.body),
        gap,
        HmTextField(label: text.partnerDetailsFullName, controller: _name, hint: text.partnerDetailsFullNameHint),
        gap,
        HmTextField(
          label: text.partnerDetailsPhone,
          controller: TextEditingController(text: phone),
          enabled: false,
          hint: text.partnerDetailsPhoneHint,
        ),
        gap,
        GestureDetector(
          onTap: _pickDob,
          child: AbsorbPointer(
            child: HmTextField(
              key: const ValueKey('details-dob'),
              label: text.partnerDetailsDob,
              controller: TextEditingController(text: _dob == null ? '' : DateFormat('dd / MM / yyyy').format(_dob!)),
              trailingIcon: Icons.calendar_today_outlined,
            ),
          ),
        ),
        gap,
        HmTextField(label: text.partnerDetailsNida, controller: _nida, keyboardType: TextInputType.number),
        gap,
        HmTextField(label: text.partnerDetailsTin, controller: _tin, optionalLabel: text.optional),
        gap,
        HmTextField(label: text.partnerDetailsAddress, controller: _address, leadingIcon: Icons.location_on_outlined),
      ],
    );
  }
}
