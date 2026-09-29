import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_button.dart';
import '../../../../../design/widgets/hm_text_field.dart';
import '../../../data/partner_listing.dart';

/// Adds or edits one "other charge" (BRK-030d).
Future<ListingCharge?> showChargeSheet(BuildContext context, {ListingCharge? charge}) =>
    showModalBottomSheet<ListingCharge>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChargeSheet(charge: charge),
    );

class _ChargeSheet extends StatefulWidget {
  const _ChargeSheet({this.charge});

  final ListingCharge? charge;

  @override
  State<_ChargeSheet> createState() => _ChargeSheetState();
}

class _ChargeSheetState extends State<_ChargeSheet> {
  late final _name = TextEditingController(text: widget.charge?.name ?? '');
  late final _amount = TextEditingController(text: widget.charge == null ? '' : '${widget.charge!.amount.round()}');
  late bool _required = widget.charge?.isMandatory ?? true;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (_name.text.trim().isEmpty || amount == null || amount <= 0) return;
    Navigator.of(context).pop(ListingCharge(name: _name.text.trim(), amount: amount, isMandatory: _required));
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: EdgeInsets.fromLTRB(HmSpace.xxl, 0, HmSpace.xxl, MediaQuery.viewInsetsOf(context).bottom + HmSpace.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text.wizardAddCharge, style: HmText.heading),
          const SizedBox(height: HmSpace.xxl),
          HmTextField(fieldKey: const ValueKey('charge-name'), label: text.wizardChargeName, controller: _name),
          const SizedBox(height: HmSpace.xl),
          HmTextField(
            fieldKey: const ValueKey('charge-amount'),
            label: text.wizardChargeAmount,
            controller: _amount,
            prefixText: 'TZS',
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            value: _required,
            onChanged: (value) => setState(() => _required = value),
            contentPadding: EdgeInsets.zero,
            title: Text(text.wizardChargeRequired),
          ),
          const SizedBox(height: HmSpace.md),
          HmButton(label: text.save, onPressed: _save),
        ],
      ),
    );
  }
}
