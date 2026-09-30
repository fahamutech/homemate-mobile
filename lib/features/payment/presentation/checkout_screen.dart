import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/error_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_section.dart';
import '../../../routing/app_router.dart';
import '../../inquiry/data/inquiry_providers.dart';
import '../data/payment_providers.dart';
import '../../shared/journey_models.dart';
import '../../shared/journey_providers.dart';
import '../../shared/service_fee_card.dart';
import 'hold_banner.dart';
import '../../../core/i18n/app_text.dart';
import 'checkout_labels.dart';

/// CUS-011 and CUS-014 — reserving a home and paying for it.
///
/// The two designs are one screen here because they are one decision: the
/// customer is looking at a total, choosing how to send it, and doing so
/// against a clock. Splitting them would mean taking the hold on one screen
/// and spending its first minute on a step that shows no new information.
///
/// Three things this screen will not do:
///
///   - it never invents the total — every figure is read back from the booking
///     the server created, so what is displayed is what is owed;
///   - it never claims a payment succeeded. The provider or a finance officer
///     decides that (BR-005); the most this screen says is "we are checking";
///   - it never silently loses the hold. When the clock runs out it says so,
///     and offers to take the property back rather than leaving a dead button.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  /// The session is started once, on entry, rather than watched: starting a
  /// checkout writes a booking, and a `FutureProvider` that re-ran on a rebuild
  /// would be a reservation created by a rotation of the phone.
  late Future<CheckoutSession> _session = _start();

  Future<CheckoutSession> _start() =>
      ref.read(journeyRepositoryProvider).startCheckout(widget.propertyId);

  void _retry() => setState(() => _session = _start());

  @override
  Widget build(BuildContext context) {
    return HmScaffold(
      title: context.text.checkoutTitle,
      padded: false,
      backgroundColor: HmColors.bgSecondary,
      body: FutureBuilder<CheckoutSession>(
        future: _session,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return HmLoading(label: context.text.checkoutReserving);
          }
          if (snapshot.hasError) {
            return _CheckoutBlocked(error: snapshot.error!, onRetry: _retry);
          }
          return _Checkout(session: snapshot.data!, onRetry: _retry);
        },
      ),
    );
  }
}

/// Why the checkout could not start. A conflict here is not a failure — it is
/// somebody else's ten minutes — so it reads as a wait rather than an error.
class _CheckoutBlocked extends StatelessWidget {
  const _CheckoutBlocked({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;
    final isHeld = api?.statusCode == 409;

    return Padding(
      padding: const EdgeInsets.all(HmSpace.huge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHeld ? Icons.hourglass_top_outlined : Icons.lock_outline,
            size: 44,
            color: isHeld ? HmColors.warning : HmColors.textDisabled,
          ),
          const SizedBox(height: HmSpace.xxl),
          Text(
            isHeld ? context.text.checkoutHeld : context.text.checkoutCannotPay,
            style: HmText.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HmSpace.md),
          Text(
            errorText(context.text, error),
            style: HmText.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HmSpace.huge),
          FilledButton(onPressed: onRetry, child: Text(context.text.retry)),
          const SizedBox(height: HmSpace.md),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(context.text.checkoutKeepLooking),
          ),
        ],
      ),
    );
  }
}

class _Checkout extends ConsumerStatefulWidget {
  const _Checkout({required this.session, required this.onRetry});

  final CheckoutSession session;
  final VoidCallback onRetry;

  @override
  ConsumerState<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<_Checkout> {
  final _phoneController = TextEditingController();
  PaymentMethodOption? _method;
  PropertyHold? _hold;
  bool _busy = false;
  bool _expired = false;
  String? _error;

  CheckoutSummary get _summary => widget.session.summary;
  String get _currency => _summary.currency;

  @override
  void initState() {
    super.initState();
    _hold = widget.session.hold;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Leaving the screen gives the property back rather than making the next
  /// person wait out a window nobody is using. Fire-and-forget on purpose: the
  /// hold lapses by itself, so a failed release costs a few minutes and never
  /// blocks the customer from leaving.
  void _releaseHold() {
    final hold = _hold;
    if (hold == null || _expired) return;
    ref.read(journeyRepositoryProvider).releaseHold(hold.id, reason: 'left checkout').ignore();
  }

  Future<void> _pay() async {
    final method = _method;
    if (method == null) {
      setState(() => _error = context.text.checkoutChooseMethod);
      return;
    }
    if (method.needsPhoneNumber && _phoneController.text.trim().length < 9) {
      setState(() => _error = context.text.checkoutEnterNumber);
      return;
    }

    final payment = _summary.payable;
    if (payment == null) {
      setState(() => _error = context.text.checkoutNothingLeft);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final attempt = await ref.read(journeyRepositoryProvider).payNow(
            payment.id,
            paymentMethodId: method.id,
            payerPhone: method.needsPhoneNumber ? _phoneController.text.trim() : null,
          );

      // Everything that could be looking at this money now needs to look
      // again, on one line, so no screen is left saying "unpaid".
      ref.invalidate(paymentProvider(payment.id));
      ref.invalidate(inquiriesProvider(null));
      ref.invalidate(activitySummaryProvider);
      ref.invalidate(savedOverviewProvider);
      if (widget.session.bookingId case final bookingId?) {
        ref.invalidate(checkoutSummaryProvider(bookingId));
      }

      if (!mounted) return;
      setState(() {
        _hold = attempt.hold ?? _hold;
        _expired = false;
        _busy = false;
      });

      // The payment is open, not settled — so the next screen is the one that
      // says how to complete it, never a success page.
      context.pushReplacement(Routes.payment(attempt.payment.id));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorText(context.text, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _summary.booking;
    final methods = ref.watch(paymentMethodsProvider(widget.session.hold.propertyId));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _releaseHold();
      },
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                HmSpace.xxl,
                HmSpace.xxl,
                HmSpace.xxl,
                HmSpace.section,
              ),
              children: [
                if (_hold != null)
                  HoldBanner(
                    hold: _hold!,
                    onExpired: () {
                      if (mounted) setState(() => _expired = true);
                    },
                  ),
                if (_expired) ...[
                  const SizedBox(height: HmSpace.xl),
                  HmNotice(
                    message: context.text.checkoutExpired,
                    icon: Icons.lock_open_outlined,
                    colour: HmColors.error,
                    action: FilledButton(
                      onPressed: widget.onRetry,
                      child: Text(context.text.checkoutHoldAgain),
                    ),
                  ),
                ],
                const SizedBox(height: HmSpace.huge),

                // The total, first and largest — it is what the customer came
                // to check.
                _AmountBox(amount: _summary.totalDue, currency: _currency),
                const SizedBox(height: HmSpace.huge),

                HmCard(
                  title: context.text.checkoutReservation,
                  child: Column(
                    children: [
                      HmDetailRow(
                        label: context.text.leaseProperty,
                        value: booking.propertyTitle ?? context.text.rentalYourHome,
                      ),
                      HmDetailRow(
                        label: context.text.checkoutMoveIn,
                        value: booking.moveInDate == null
                            ? context.text.checkoutToBeAgreed
                            : DateFormat('d MMM yyyy').format(booking.moveInDate!),
                      ),
                      HmDetailRow(
                        label: context.text.checkoutLeaseDuration,
                        value: booking.leaseMonths == null
                            ? '—'
                            : context.text.listingMonths(booking.leaseMonths!),
                      ),
                      HmDetailRow(
                        label: context.text.rentalMonthlyRent,
                        value: HmMoney.format(booking.monthlyRent, currency: _currency),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: HmSpace.xl),

                HmCard(
                  title: context.text.checkoutBreakdown,
                  child: Column(
                    children: [
                      for (final line in _summary.breakdown)
                        if (line.highlight && !line.waived)
                          // The HomeMate fee is tinted so the platform's own
                          // charge is never a line the customer has to hunt for.
                          Container(
                            key: const Key('checkout-fee-line'),
                            margin: const EdgeInsets.symmetric(vertical: HmSpace.xs),
                            padding: const EdgeInsets.symmetric(horizontal: HmSpace.md),
                            decoration: BoxDecoration(
                              color: HmColors.brandPrimarySoft,
                              borderRadius: BorderRadius.circular(HmRadius.sm),
                            ),
                            child: HmDetailRow(
                              label: line.label,
                              value: line.amountLabel(_currency),
                              valueColor: HmColors.brandPrimary,
                            ),
                          )
                        else
                          HmDetailRow(
                            label: line.label,
                            value: line.amountLabel(_currency),
                            valueColor: line.waived ? HmColors.textSecondary : null,
                          ),
                      const Divider(height: HmSpace.huge),
                      HmDetailRow(
                        label: context.text.checkoutTotalDue,
                        value: _summary.totalLabel,
                        emphasise: true,
                        valueColor: HmColors.brandPrimary,
                      ),
                    ],
                  ),
                ),
                if (_summary.serviceFee case final fee? when fee.isCharged) ...[
                  const SizedBox(height: HmSpace.xl),
                  ServiceFeeCard(fee: fee, currency: _currency, inFirstPayment: true),
                ],
                const SizedBox(height: HmSpace.huge),

                HmSectionHeader(title: context.text.checkoutSelectMethod),
                HmAsync(
                  value: methods,
                  onRetry: () =>
                      ref.invalidate(paymentMethodsProvider(widget.session.hold.propertyId)),
                  emptyWhen: (list) => list.isEmpty,
                  empty: HmNotice(
                    message: context.text.checkoutNoMethods,
                    colour: HmColors.info,
                    icon: Icons.info_outline,
                  ),
                  data: (list) => Column(
                    children: [
                      for (final option in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: HmSpace.xl),
                          child: _MethodTile(
                            option: option,
                            selected: _method?.id == option.id,
                            onTap: () => setState(() {
                              _method = option;
                              _error = null;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),

                if (_method?.needsPhoneNumber ?? false) ...[
                  const SizedBox(height: HmSpace.md),
                  HmCard(
                    title: context.text.checkoutRegisteredNumber(_method!.name),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                            LengthLimitingTextInputFormatter(16),
                          ],
                          decoration: const InputDecoration(
                            prefixText: '+255 ',
                            hintText: '712 345 678',
                          ),
                        ),
                        const SizedBox(height: HmSpace.xl),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: HmColors.textSecondary),
                            const SizedBox(width: HmSpace.md),
                            Expanded(
                              child: Text(
                                context.text.checkoutPrompt(_method!.name),
                                style: HmText.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: HmSpace.huge),
                HmNotice(
                  message: context.text.checkoutSafety,
                  icon: Icons.verified_user_outlined,
                  colour: HmColors.info,
                ),

              ],
            ),
          ),

          // A pinned bar rather than a button at the end of the list: the
          // breakdown is long enough to scroll, and the action must not be
          // something the customer has to go looking for.
          Material(
            color: HmColors.bgPrimary,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(HmSpace.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Inside the pinned bar, not at the end of the list: the
                    // customer tapped a button down here, and an explanation
                    // two screens above it is one they will never see.
                    if (_error != null) HmInlineError(_error),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy || _expired ? null : _pay,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: HmColors.textOnBrand,
                                ),
                              )
                            : Text(context.text.checkoutPay(_summary.totalLabel)),
                      ),
                    ),
                    const SizedBox(height: HmSpace.md),
                    Text(
                      context.text.checkoutYoursOnceVerified,
                      style: HmText.caption.copyWith(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The figure the whole screen is about.
class _AmountBox extends StatelessWidget {
  const _AmountBox({required this.amount, required this.currency});

  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: HmSpace.huge, horizontal: HmSpace.xxl),
        decoration: BoxDecoration(
          color: HmColors.brandPrimarySoft,
          borderRadius: HmRadius.card,
        ),
        child: Column(
          children: [
            Text(
              context.text.checkoutTotalCaps,
              style: HmText.caption.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: HmColors.brandPrimaryDark,
              ),
            ),
            const SizedBox(height: HmSpace.md),
            Text(
              HmMoney.format(amount, currency: currency),
              style: HmText.display.copyWith(color: HmColors.brandPrimaryDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.option, required this.selected, required this.onTap});

  final PaymentMethodOption option;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (option.kind) {
        'mobile_money' => Icons.smartphone_outlined,
        'card' => Icons.credit_card,
        'bank_transfer' => Icons.account_balance_outlined,
        'cash' => Icons.payments_outlined,
        _ => Icons.account_balance_wallet_outlined,
      };

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: HmColors.bgPrimary,
          borderRadius: HmRadius.card,
          child: InkWell(
            onTap: onTap,
            borderRadius: HmRadius.card,
            child: Container(
              padding: const EdgeInsets.all(HmSpace.xl),
              decoration: BoxDecoration(
                borderRadius: HmRadius.card,
                border: Border.all(
                  color: selected ? HmColors.brandPrimary : HmColors.borderDefault,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: HmColors.surfaceInput,
                      borderRadius: BorderRadius.circular(HmRadius.sm),
                    ),
                    child: Icon(_icon, size: 20, color: HmColors.brandPrimary),
                  ),
                  const SizedBox(width: HmSpace.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.name, style: HmText.label.copyWith(fontSize: 14)),
                        const SizedBox(height: HmSpace.xxs),
                        Text(paymentKindLabel(context.text, option.kind), style: HmText.caption),
                      ],
                    ),
                  ),
                  // A radio rather than a tick: these are mutually exclusive,
                  // and the control should say so before it is tapped.
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? HmColors.brandPrimary : HmColors.borderStrong,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
