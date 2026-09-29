import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_choice.dart';
import '../../../../design/widgets/hm_segmented.dart';
import '../../../../design/widgets/hm_text_field.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_application.dart';
import '../../data/partner_providers.dart';
import '../payout_labels.dart';
import 'fee_example_card.dart';
import 'setup_frame.dart';
import 'setup_step.dart';

/// BRK-002c "Getting paid": the payout account, the example, the agreement,
/// and "Submit for review". The payout is saved even when the submit is
/// refused, so nothing typed is lost.
class PayoutStep extends ConsumerStatefulWidget {
  const PayoutStep({super.key, required this.role, required this.overview, required this.onSubmitted});

  final AppRole role;
  final ApplicationsOverview overview;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<PayoutStep> createState() => _PayoutStepState();
}

class _PayoutStepState extends ConsumerState<PayoutStep> {
  late final PayoutAccount? _existing = widget.overview.profile.payout;
  late String _method = _existing?.method ?? 'mobile_money';
  late String? _provider = _existing?.provider ?? 'mpesa';
  late final _number = TextEditingController(text: _existing?.accountNumber ?? '');
  late final _name = TextEditingController(text: _existing?.accountName ?? '');
  late bool _agreed = widget.overview.application(widget.role.name).isDone('agreement');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = context.text;
    if (_provider == null || _number.text.trim().isEmpty || _name.text.trim().isEmpty) {
      setState(() => _error = text.partnerPayoutRequired);
      return;
    }
    if (!_agreed) {
      setState(() => _error = text.partnerAgreeRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final onboarding = ref.read(onboardingRepositoryProvider);
    final role = widget.role.name;
    try {
      await onboarding.savePayout(PayoutAccount(
        method: _method,
        provider: _provider,
        accountName: _name.text.trim(),
        accountNumber: _number.text.trim(),
      ));
      final version = widget.overview.application(role).currentAgreementVersion ?? 'v1.0';
      await onboarding.acceptAgreement(role, version);
      await onboarding.submit(role);
      ref.invalidate(applicationsProvider);
      await ref.read(roleControllerProvider.notifier).refresh();
      widget.onSubmitted();
    } on ApiException catch (error) {
      final missing = error.detailList('missingSteps');
      setState(() => _error = missing.isEmpty ? error.message : text.partnerMissing(missingStepsSentence(text, missing)));
      ref.invalidate(applicationsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final reference = ref.watch(referenceDataProvider).valueOrNull;
    final mobile = _method == 'mobile_money';
    final providers = mobile
        ? [for (final code in reference?.mobileMoneyProviders ?? const ['mpesa', 'mixx_by_yas', 'airtel_money', 'halopesa']) (code, payoutProviderLabel(code))]
        : [for (final bank in reference?.banks ?? const []) (bank.code ?? bank.id, bank.name)];
    const gap = SizedBox(height: HmSpace.xxl);

    return SetupFrame(
      error: _error,
      actions: [HmButton(label: text.partnerSubmitForReview, busy: _busy, onPressed: _submit)],
      children: [
        Text(text.partnerPayoutTitle, style: HmText.title),
        gap,
        HmSegmented<String>(
          label: text.partnerPayoutPayMeBy,
          options: [('mobile_money', text.partnerPayoutMobile), ('bank', text.partnerPayoutBank)],
          value: _method,
          onChanged: (value) => setState(() {
            _method = value;
            _provider = null;
          }),
        ),
        gap,
        Text(mobile ? text.partnerPayoutProvider : text.partnerPayoutBankName, style: HmText.label.copyWith(fontSize: 14)),
        const SizedBox(height: HmSpace.sm),
        Wrap(
          spacing: HmSpace.md,
          runSpacing: HmSpace.md,
          children: [
            for (final (code, label) in providers)
              HmChoicePill(
                label: label,
                dense: true,
                showCheck: true,
                selected: _provider == code,
                onTap: () => setState(() => _provider = code),
              ),
          ],
        ),
        gap,
        HmTextField(
          fieldKey: const ValueKey('payout-number'),
          label: mobile ? text.partnerPayoutMobileNumber : text.partnerPayoutAccountNumber,
          controller: _number,
          keyboardType: mobile ? TextInputType.phone : TextInputType.number,
        ),
        gap,
        HmTextField(
          fieldKey: const ValueKey('payout-name'),
          label: text.partnerPayoutAccountName,
          controller: _name,
          hint: text.partnerPayoutAccountNameHint,
        ),
        if (widget.overview.feeExample case final example?) ...[gap, FeeExampleCard(example: example)],
        gap,
        CheckboxListTile(
          key: const ValueKey('agreement'),
          value: _agreed,
          onChanged: (value) => setState(() => _agreed = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: HmColors.brandPrimary,
          title: Text(text.partnerAgree, style: const TextStyle(fontSize: 14, color: HmColors.textBody)),
        ),
      ],
    );
  }
}
