import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/providers.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_button.dart';
import '../../../../../design/widgets/hm_feedback.dart';
import '../../../../../design/widgets/hm_key_value.dart';
import '../../../../../design/widgets/hm_note.dart';
import '../../../../../design/widgets/hm_section.dart';
import '../../../../../design/widgets/hm_text_field.dart';
import '../../../data/partner_listing.dart';
import 'step_controller.dart';

/// BRK-030e: who owns the home. Look the landlord up by phone; invite them by
/// name when they are not on HomeMate yet. The broker keeps the credit.
class LandlordStep extends ConsumerStatefulWidget {
  const LandlordStep({super.key, required this.listing, required this.controller});

  final PartnerListing listing;
  final WizardStepController controller;

  @override
  ConsumerState<LandlordStep> createState() => _LandlordStepState();
}

class _LandlordStepState extends ConsumerState<LandlordStep> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  late LandlordCard? _chosen = widget.listing.landlord == null
      ? null
      : LandlordCard(userId: widget.listing.landlord!.userId, name: widget.listing.landlord!.name, phone: widget.listing.landlord!.phone);
  bool _notFound = false;
  bool _invited = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.collect = _collect;
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _collect() {
    if (_chosen == null) {
      setState(() => _error = context.text.wizardLandlordRequired);
      return null;
    }
    // Only a change is sent: attaching the same landlord again is a no-op
    // the server would still have to check.
    return _chosen!.userId == widget.listing.landlord?.userId ? const {} : {'landlordUserId': _chosen!.userId};
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _find() => _run(() async {
        final found = await ref.read(listingsRepositoryProvider).lookupLandlord(_phone.text.trim());
        setState(() {
          _chosen = found;
          _notFound = found == null;
          _invited = false;
        });
      });

  Future<void> _invite() => _run(() async {
        if (_name.text.trim().isEmpty) return;
        final card = await ref.read(listingsRepositoryProvider).inviteLandlord(fullName: _name.text.trim(), phone: _phone.text.trim());
        setState(() {
          _chosen = card;
          _notFound = false;
          _invited = true;
        });
      });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final me = ref.watch(authControllerProvider).customer?.displayName ?? '';
    const gap = SizedBox(height: HmSpace.xxl);

    return ListView(
      padding: const EdgeInsets.all(HmSpace.xxl),
      children: [
        Text(text.wizardLandlordTitle, style: HmText.title),
        const SizedBox(height: HmSpace.md),
        Text(text.wizardLandlordBody, style: HmText.body),
        gap,
        HmInlineError(_error),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: HmTextField(
                fieldKey: const ValueKey('landlord-phone'),
                label: text.wizardLandlordPhone,
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: HmSpace.md),
            HmButton(label: text.wizardLandlordFind, expand: false, size: HmButtonSize.medium, busy: _busy && !_notFound, onPressed: _find),
          ],
        ),
        const SizedBox(height: HmSpace.xl),
        if (_chosen case final landlord?)
          Container(
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: BoxDecoration(
              color: HmColors.brandSubtle,
              borderRadius: BorderRadius.circular(HmRadius.md),
              border: Border.all(color: HmColors.brandPrimary, width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: HmColors.bgPrimary,
                  child: Text(_initials(landlord.name), style: HmText.label.copyWith(color: HmColors.brandPrimary)),
                ),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(landlord.name ?? '', style: HmText.label.copyWith(fontSize: 15)),
                      Text(
                        _invited ? text.wizardLandlordInvited : text.wizardLandlordOnHomeMate(landlord.homes),
                        style: HmText.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_outline_rounded, color: HmColors.brandPrimary),
              ],
            ),
          ),
        if (_notFound) ...[
          Text(text.wizardLandlordNotFound, style: HmText.caption.copyWith(fontSize: 13)),
          const SizedBox(height: HmSpace.xl),
          HmTextField(fieldKey: const ValueKey('landlord-name'), label: text.wizardLandlordName, controller: _name),
          const SizedBox(height: HmSpace.xl),
          HmButton(label: text.wizardLandlordInvite, style: HmButtonStyle.outline, busy: _busy, onPressed: _invite),
        ],
        gap,
        HmCard(
          title: text.wizardLandlordCredit,
          child: Column(
            children: [
              HmKeyValue(label: text.wizardLandlordListedBy, value: text.wizardLandlordYou(me), emphasis: HmKeyValueEmphasis.strong),
              const SizedBox(height: HmSpace.md),
              HmNote(text: text.wizardLandlordLock, icon: Icons.lock_outline_rounded),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').split(RegExp(r'[\s.]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '#';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
