import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_prompt.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../inquiry/data/inquiry_providers.dart';
import '../../shared/journey_providers.dart';
import '../data/payment_providers.dart';
import '../../shared/models.dart';

/// CUS-014 / CUS-015. Paying for a booking.
///
/// HomeMate does not take the money — it tells the customer where to send it
/// and then a person checks that it arrived. So this screen is deliberately
/// honest about that: it shows the exact account details an operator entered,
/// gives a way to say "I have sent it", and then says plainly that someone is
/// checking rather than pretending to be confirmed.
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = ref.watch(paymentProvider(paymentId));

    return HmScaffold(
      title: 'Payment',
      body: HmAsync(
        value: payment,
        onRetry: () => ref.invalidate(paymentProvider(paymentId)),
        data: (data) => _Loaded(payment: data),
      ),
    );
  }
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.payment});

  final CustomerPayment payment;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded> {
  bool _busy = false;

  Future<void> _declarePaid() async {
    final reference = await _askForReference();
    if (reference == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(activityRepositoryProvider).declarePaid(
            widget.payment.id,
            reference: reference.isEmpty ? null : reference,
          );
      ref.invalidate(paymentProvider(widget.payment.id));
      // The enquiry that led here now reads "payment being verified".
      ref.invalidate(inquiriesProvider(null));
      ref.invalidate(savedOverviewProvider);
      ref.invalidate(activitySummaryProvider);

      if (mounted) HmFeedback.success(context, 'Thank you — we are checking your payment');
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The provider's own confirmation code. Optional, but it is what lets
  /// finance match the payment in minutes rather than hours.
  Future<String?> _askForReference() => HmPrompt.show(
        context,
        title: 'Confirm your payment',
        message: 'If you have the confirmation code from your payment message, '
            'entering it helps us check much faster.',
        fieldLabel: 'Confirmation code (optional)',
        hintText: 'e.g. QJ12KL9MN',
        cancelLabel: 'Not yet',
        confirmLabel: 'I have paid',
        capitalise: TextCapitalization.characters,
        required: false,
      );

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;

    return ListView(
      children: [
        Center(
          child: Column(
            children: [
              Text(payment.amountLabel, style: HmText.display),
              const SizedBox(height: HmSpace.md),
              Text(
                '${HmStatusChip.humanise(payment.purpose)}'
                '${payment.propertyTitle == null ? '' : ' · ${payment.propertyTitle}'}',
                style: HmText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HmSpace.xl),
              HmStatusChip(payment.customerState),
            ],
          ),
        ),
        const SizedBox(height: HmSpace.section),

        switch (payment.customerState) {
          'awaiting_instructions' => const _Waiting(),
          'awaiting_verification' => _BeingChecked(payment: payment),
          'paid' => _Paid(payment: payment),
          'failed' => _Failed(payment: payment),
          _ => _HowToPay(payment: payment),
        },

        if (payment.canDeclare) ...[
          const SizedBox(height: HmSpace.section),
          ElevatedButton(
            onPressed: _busy ? null : _declarePaid,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('I have paid'),
          ),
          const SizedBox(height: HmSpace.md),
          const Text(
            'Only tap this once you have actually sent the money.',
            style: HmText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// The account details, shown exactly as an operator entered them.
class _HowToPay extends StatelessWidget {
  const _HowToPay({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) {
    if (!payment.hasInstructions) return const _Waiting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How to pay', style: HmText.heading),
        const SizedBox(height: HmSpace.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Column(
              children: [
                _CopyRow(label: 'Pay to', value: payment.payToName ?? ''),
                if (payment.payToAccountName != null)
                  _CopyRow(label: 'Account name', value: payment.payToAccountName!),
                _CopyRow(
                  label: payment.paymentMethodKindLabel,
                  value: payment.payToAccountNumber!,
                  emphasise: true,
                ),
                _CopyRow(label: 'Reference', value: payment.payReference!, emphasise: true),
                _CopyRow(label: 'Amount', value: payment.amountLabel, emphasise: true),
              ],
            ),
          ),
        ),
        if (payment.payInstructions != null) ...[
          const SizedBox(height: HmSpace.xxl),
          Container(
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: BoxDecoration(
              color: HmColors.brandPrimarySoft,
              borderRadius: HmRadius.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: HmColors.brandPrimary),
                const SizedBox(width: HmSpace.xl),
                Expanded(child: Text(payment.payInstructions!, style: HmText.body)),
              ],
            ),
          ),
        ],
        const SizedBox(height: HmSpace.xxl),
        const Text(
          'Always quote the reference. Without it we cannot match your payment to '
          'your booking.',
          style: HmText.caption,
        ),
      ],
    );
  }
}

/// A value worth copying rather than retyping — a mistyped till number is how
/// money goes to a stranger.
class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value, this.emphasise = false});

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HmSpace.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: HmText.caption),
                  const SizedBox(height: HmSpace.xxs),
                  SelectableText(
                    value,
                    style: emphasise
                        ? HmText.heading.copyWith(letterSpacing: 0.5)
                        : HmText.label,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy $label',
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) HmFeedback.success(context, '$label copied');
              },
            ),
          ],
        ),
      );
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) => const HmEmpty(
        title: 'Payment details are being prepared',
        message: 'We will notify you the moment they are ready — usually within a few minutes.',
        icon: Icons.hourglass_empty_rounded,
      );
}

/// The honest state: the customer has said they paid, and a person is checking.
class _BeingChecked extends StatelessWidget {
  const _BeingChecked({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(HmSpace.huge),
            decoration: BoxDecoration(
              color: HmColors.warning.withValues(alpha: 0.08),
              borderRadius: HmRadius.card,
            ),
            child: Column(
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 36, color: HmColors.warning),
                const SizedBox(height: HmSpace.xxl),
                const Text('We are checking your payment', style: HmText.heading),
                const SizedBox(height: HmSpace.md),
                const Text(
                  'Someone from our team is confirming it against the account. '
                  'You will be notified as soon as it clears.',
                  style: HmText.body,
                  textAlign: TextAlign.center,
                ),
                if (payment.declaredReference != null) ...[
                  const SizedBox(height: HmSpace.xxl),
                  Text('Your code: ${payment.declaredReference}', style: HmText.caption),
                ],
              ],
            ),
          ),
          const SizedBox(height: HmSpace.xxl),
          if (payment.hasInstructions) _HowToPay(payment: payment),
        ],
      );
}

class _Paid extends StatelessWidget {
  const _Paid({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(HmSpace.huge),
        decoration: BoxDecoration(
          color: HmColors.success.withValues(alpha: 0.08),
          borderRadius: HmRadius.card,
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 40, color: HmColors.success),
            const SizedBox(height: HmSpace.xxl),
            const Text('Payment received', style: HmText.heading),
            const SizedBox(height: HmSpace.md),
            Text(
              'We confirmed ${payment.amountLabel}'
              '${payment.confirmedAt == null ? '' : ' on ${payment.confirmedAt!.day}/${payment.confirmedAt!.month}/${payment.confirmedAt!.year}'}.',
              style: HmText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HmSpace.xxl),
            Text('Receipt ${payment.reference}', style: HmText.caption),
          ],
        ),
      );
}

class _Failed extends StatelessWidget {
  const _Failed({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(HmSpace.huge),
        decoration: BoxDecoration(
          color: HmColors.error.withValues(alpha: 0.08),
          borderRadius: HmRadius.card,
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: HmColors.error),
            const SizedBox(height: HmSpace.xxl),
            const Text('This payment did not go through', style: HmText.heading),
            const SizedBox(height: HmSpace.md),
            Text(
              payment.failureReason ?? 'Please contact support so we can sort it out.',
              style: HmText.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

extension on CustomerPayment {
  /// "Lipa Namba" means something to a Tanzanian customer; "Account number"
  /// is what a bank transfer needs. The method decides the wording.
  String get paymentMethodKindLabel => switch (paymentMethodName?.toLowerCase()) {
        final name? when name.contains('pesa') || name.contains('mix') || name.contains('airtel') =>
          'Lipa Namba',
        final name? when name.contains('bank') => 'Account number',
        _ => 'Pay to number',
      };
}
