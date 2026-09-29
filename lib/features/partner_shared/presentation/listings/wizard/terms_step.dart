import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_choice.dart';
import '../../../../../design/widgets/hm_counter.dart';
import '../../../../../design/widgets/hm_feedback.dart';
import '../../../../../design/widgets/hm_text_field.dart';
import '../../../data/partner_listing.dart';
import 'money_preview_card.dart';
import 'step_controller.dart';
import 'wizard_step.dart';

/// BRK-030c: rent and terms. Changes are saved as they are made (after a
/// short pause), so the move-in amount and "You earn" are always the
/// server's numbers for exactly what is on screen.
class TermsStep extends StatefulWidget {
  const TermsStep({super.key, required this.listing, required this.controller, required this.autosave});

  final PartnerListing listing;
  final WizardStepController controller;
  final Future<void> Function(Map<String, dynamic> fields) autosave;

  @override
  State<TermsStep> createState() => _TermsStepState();
}

class _TermsStepState extends State<TermsStep> {
  late final _rent = TextEditingController(text: widget.listing.price > 0 ? '${widget.listing.price.round()}' : '');
  late final _notice = TextEditingController(text: '${widget.listing.noticePeriodDays}');
  late final _customMonths = TextEditingController(text: '${widget.listing.customPaymentMonths ?? ''}');
  late String _frequency = widget.listing.paymentFrequency;
  late int _deposit = widget.listing.depositMonths.round();
  late int _advance = widget.listing.advanceRentMonths.round();
  late int _minLease = widget.listing.minLeaseMonths;
  late DateTime? _available = widget.listing.availableFrom;
  Timer? _debounce;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.collect = _collect;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_rent, _notice, _customMonths]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _price => double.tryParse(_rent.text.replaceAll(RegExp(r'[^0-9.]'), ''));

  Map<String, dynamic> _fields() => {
        'price': _price,
        'paymentFrequency': _frequency,
        'customPaymentMonths': _frequency == 'custom' ? int.tryParse(_customMonths.text) : null,
        'depositMonths': _deposit,
        'advanceRentMonths': _advance,
        'minLeaseMonths': _minLease,
        'noticePeriodDays': int.tryParse(_notice.text) ?? 30,
        'availableFrom': _available == null ? null : DateFormat('yyyy-MM-dd').format(_available!),
      };

  Map<String, dynamic>? _collect() {
    if ((_price ?? 0) <= 0) {
      setState(() => _error = context.text.wizardRentRequired);
      return null;
    }
    setState(() => _error = null);
    return _fields();
  }

  /// Saves what is on screen once typing pauses, for a fresh preview.
  void _changed([VoidCallback? update]) {
    if (update != null) setState(update);
    _debounce?.cancel();
    if ((_price ?? 0) <= 0) return;
    _debounce = Timer(const Duration(milliseconds: 600), () => widget.autosave(_fields()));
  }

  Future<void> _pickAvailable() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _available ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) _changed(() => _available = picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    const gap = SizedBox(height: HmSpace.xxl);
    return ListView(
      padding: const EdgeInsets.all(HmSpace.xxl),
      children: [
        HmInlineError(_error),
        HmTextField(
          fieldKey: const ValueKey('wizard-rent'),
          label: text.wizardMonthlyRent,
          controller: _rent,
          prefixText: 'TZS',
          keyboardType: TextInputType.number,
          onChanged: (_) => _changed(),
        ),
        gap,
        Text(text.wizardPaysEvery, style: HmText.label.copyWith(fontSize: 14)),
        const SizedBox(height: HmSpace.sm),
        Wrap(
          spacing: HmSpace.md,
          runSpacing: HmSpace.md,
          children: [
            for (final frequency in rentFrequencies)
              HmChoicePill(
                label: frequencyLabel(text, frequency),
                dense: true,
                showCheck: true,
                selected: _frequency == frequency,
                onTap: () => _changed(() => _frequency = frequency),
              ),
          ],
        ),
        if (_frequency == 'custom') ...[
          const SizedBox(height: HmSpace.xl),
          HmTextField(
            label: text.wizardCustomMonths,
            controller: _customMonths,
            keyboardType: TextInputType.number,
            onChanged: (_) => _changed(),
          ),
        ],
        gap,
        Row(children: [
          Expanded(child: HmCounter(label: text.wizardDepositMonths, value: _deposit, max: 12, onChanged: (v) => _changed(() => _deposit = v))),
          const SizedBox(width: HmSpace.xl),
          Expanded(child: HmCounter(label: text.wizardAdvanceMonths, value: _advance, max: 12, onChanged: (v) => _changed(() => _advance = v))),
        ]),
        gap,
        Row(children: [
          Expanded(child: HmCounter(label: text.wizardMinLease, value: _minLease, min: 1, max: 60, onChanged: (v) => _changed(() => _minLease = v))),
          const SizedBox(width: HmSpace.xl),
          Expanded(
            child: HmTextField(
              label: text.wizardNotice,
              controller: _notice,
              keyboardType: TextInputType.number,
              onChanged: (_) => _changed(),
            ),
          ),
        ]),
        gap,
        GestureDetector(
          onTap: _pickAvailable,
          child: AbsorbPointer(
            child: HmTextField(
              label: text.listingAvailableFrom,
              controller: TextEditingController(text: _available == null ? '' : DateFormat('d MMM yyyy').format(_available!)),
              trailingIcon: Icons.calendar_today_outlined,
            ),
          ),
        ),
        if (widget.listing.moneyPreview case final preview? when preview.total > 0) ...[gap, MoneyPreviewCard(preview: preview)],
      ],
    );
  }
}
