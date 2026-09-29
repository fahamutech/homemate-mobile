import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import '../../discovery/data/search_providers.dart';
import '../data/inquiry_providers.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-007a. Asking the landlord a question.
///
/// The form gathers what a landlord actually needs to answer usefully — when
/// you want to move, how many of you there are, how to reach you — so the
/// reply is one message rather than four.
class InquiryFormScreen extends ConsumerStatefulWidget {
  const InquiryFormScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends ConsumerState<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  bool _messageSeeded = false;
  final _budget = TextEditingController();

  DateTime? _moveIn;
  int _occupants = 1;
  String _contactPreference = 'phone';
  bool _busy = false;
  String? _error;

  // The suggested opening line is in the customer's language, which is only
  // known once the widget sits under the app's Localizations.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messageSeeded) return;
    _messageSeeded = true;
    _message.text = context.text.inquiryFormDefaultMessage;
  }

  @override
  void dispose() {
    _message.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickMoveIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveIn ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _moveIn = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final inquiry = await ref.read(activityRepositoryProvider).createInquiry(
            propertyId: widget.propertyId,
            message: _message.text.trim(),
            moveInDate: _moveIn,
            budgetAmount: double.tryParse(_budget.text.replaceAll(RegExp(r'[^\d.]'), '')),
            occupants: _occupants,
            contactPreference: _contactPreference,
          );

      // Everything that counted this enquiry has to be told about it.
      ref.invalidate(activitySummaryProvider);
      ref.invalidate(inquiriesProvider);
      ref.invalidate(propertyDetailProvider(widget.propertyId));

      if (!mounted) return;
      HmFeedback.success(context, context.text.inquiryFormSent);
      // Replaces the form so Back does not offer to send it a second time.
      context.pushReplacement(Routes.inquiry(inquiry.id));
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HmScaffold(
      title: context.text.inquiryFormTitle,
      backgroundColor: HmColors.bgPrimary,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HmInlineError(_error),

              Text(context.text.inquiryFormMessage, style: HmText.label),
              const SizedBox(height: HmSpace.md),
              TextFormField(
                key: const Key('inquiry-message'),
                controller: _message,
                enabled: !_busy,
                maxLines: 5,
                maxLength: 1000,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? context.text.inquiryFormMessageRequired : null,
                decoration: InputDecoration(
                  hintText: context.text.inquiryFormMessageHint,
                ),
              ),

              const SizedBox(height: HmSpace.xxl),
              Text(context.text.inquiryFormMoveIn, style: HmText.label),
              const SizedBox(height: HmSpace.md),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickMoveIn,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  _moveIn == null
                      ? context.text.inquiryFormChooseDate
                      : '${_moveIn!.day}/${_moveIn!.month}/${_moveIn!.year}',
                ),
              ),

              const SizedBox(height: HmSpace.xxl),
              Text(context.text.inquiryFormPeople, style: HmText.label),
              const SizedBox(height: HmSpace.md),
              Wrap(
                spacing: HmSpace.md,
                children: [
                  for (final count in [1, 2, 3, 4, 5, 6])
                    ChoiceChip(
                      label: Text(count == 6 ? '6+' : '$count'),
                      selected: _occupants == count,
                      onSelected: _busy ? null : (_) => setState(() => _occupants = count),
                    ),
                ],
              ),

              const SizedBox(height: HmSpace.xxl),
              Text(context.text.inquiryFormBudget, style: HmText.label),
              const SizedBox(height: HmSpace.md),
              TextFormField(
                controller: _budget,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: 'TZS ', hintText: '800000'),
              ),

              const SizedBox(height: HmSpace.xxl),
              Text(context.text.inquiryFormReach, style: HmText.label),
              const SizedBox(height: HmSpace.md),
              Wrap(
                spacing: HmSpace.md,
                children: [
                  for (final (value, label) in [
                    ('phone', context.text.enquiriesCall),
                    ('sms', 'SMS'),
                    ('whatsapp', 'WhatsApp'),
                    ('in_app', context.text.inquiryFormInApp),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _contactPreference == value,
                      onSelected:
                          _busy ? null : (_) => setState(() => _contactPreference = value),
                    ),
                ],
              ),

              const SizedBox(height: HmSpace.section),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(context.text.inquiryFormSend),
              ),
              const SizedBox(height: HmSpace.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
