import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_feedback.dart';
import '../../../../design/widgets/hm_key_value.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../partner_shared/presentation/partner_photo.dart';
import '../../../roles/data/app_role.dart';
import '../../data/landlord_providers.dart';
import '../../data/listing_confirmation.dart';
import 'dispute_sheet.dart';

/// LND-003, from the SMS link: the home a broker listed in this person's
/// name. "Yes, this is my home" confirms it; "Something is wrong" disputes it
/// with a reason. Someone who is not a landlord yet carries on into the
/// landlord setup once they have confirmed.
class ConfirmListingScreen extends ConsumerStatefulWidget {
  const ConfirmListingScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<ConfirmListingScreen> createState() => _ConfirmListingScreenState();
}

enum _Answer { confirmed, disputed }

class _ConfirmListingScreenState extends ConsumerState<ConfirmListingScreen> {
  _Answer? _answer;
  bool _busy = false;
  bool _isLandlord = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ref.read(confirmationsRepositoryProvider).confirm(widget.propertyId);
      // The roles decide what comes next: an active landlord goes to their
      // homes, anyone else is asked to set the landlord account up.
      final roles = ref.read(roleControllerProvider.notifier);
      await roles.refresh().catchError((_) {});
      _isLandlord = ref.read(roleControllerProvider).held(AppRole.landlord)?.isActive ?? false;
      if (mounted) setState(() => _answer = _Answer.confirmed);
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dispute() async {
    final reason = await showDisputeSheet(context);
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(confirmationsRepositoryProvider).dispute(widget.propertyId, reason: reason);
      if (mounted) setState(() => _answer = _Answer.disputed);
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the landlord role, then its home or its setup.
  Future<void> _carryOn() async {
    await ref.read(roleControllerProvider.notifier).open(AppRole.landlord);
    if (!mounted) return;
    context.go(_isLandlord ? Routes.landlordHome : Routes.partnerSetup(AppRole.landlord));
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Scaffold(
      appBar: HmTopBar(
        title: text.landlordConfirmTitle,
        backTooltip: text.back,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
      ),
      body: switch (_answer) {
        _Answer.confirmed => _Answered(
            message: text.landlordConfirmConfirmed,
            detail: _isLandlord ? null : text.landlordConfirmSetupBody,
            action: _isLandlord ? text.landlordConfirmGoHome : text.landlordConfirmContinueSetup,
            onAction: _carryOn,
          ),
        _Answer.disputed => _Answered(
            message: text.landlordConfirmDisputed,
            action: text.landlordConfirmDone,
            onAction: () => context.go('/'),
            tone: HmNoteTone.info,
          ),
        null => HmAsync<List<ListingConfirmation>>(
            value: ref.watch(listingConfirmationsProvider),
            onRetry: () => ref.invalidate(listingConfirmationsProvider),
            data: (waiting) {
              final listing = waiting.where((c) => c.propertyId == widget.propertyId).firstOrNull;
              if (listing == null) {
                return _Answered(
                  message: text.landlordConfirmNothing,
                  action: text.landlordConfirmDone,
                  onAction: () => context.go('/'),
                  tone: HmNoteTone.neutral,
                );
              }
              return _Question(listing: listing, busy: _busy, onConfirm: _confirm, onDispute: _dispute);
            },
          ),
      },
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.listing, required this.busy, required this.onConfirm, required this.onDispute});

  final ListingConfirmation listing;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(text.landlordConfirmBody, style: HmText.body),
            const SizedBox(height: HmSpace.xl),
            HmCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(HmRadius.sm),
                  child: AspectRatio(aspectRatio: 16 / 9, child: PartnerPhoto(url: listing.coverPhotoUrl, radius: 0)),
                ),
                const SizedBox(height: HmSpace.xl),
                Text(listing.title, style: HmText.heading),
                if (listing.place.isNotEmpty) Text(listing.place, style: HmText.caption),
                if (listing.brokerName != null) ...[
                  const SizedBox(height: HmSpace.md),
                  Text(text.landlordConfirmListedBy(listing.brokerName!), style: HmText.label),
                ],
              ]),
            ),
            const SizedBox(height: HmSpace.xl),
            HmCard(
              title: text.landlordConfirmTerms,
              child: Column(children: [
                HmKeyValue(label: text.landlordConfirmRent, value: HmMoney.format(listing.price, currency: listing.currency)),
                HmKeyValue(label: text.landlordConfirmDeposit, value: text.landlordConfirmMonths(_count(listing.depositMonths))),
                if (listing.minLeaseMonths != null)
                  HmKeyValue(label: text.landlordConfirmMinLease, value: text.landlordConfirmMonths(listing.minLeaseMonths!)),
                if (listing.availableFrom != null)
                  HmKeyValue(label: text.landlordConfirmAvailable, value: DateFormat('d MMM yyyy').format(listing.availableFrom!)),
              ]),
            ),
            const SizedBox(height: HmSpace.xl),
            HmNote(text: text.landlordConfirmNote, tone: HmNoteTone.success),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(HmSpace.xxl),
        decoration: const BoxDecoration(color: HmColors.bgPrimary, border: Border(top: BorderSide(color: HmColors.borderDefault))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            HmButton(label: text.landlordConfirmYes, icon: Icons.check_rounded, busy: busy, onPressed: onConfirm),
            const SizedBox(height: HmSpace.md),
            HmButton(label: text.landlordConfirmWrong, style: HmButtonStyle.dangerOutline, onPressed: busy ? null : onDispute),
          ]),
        ),
      ),
    ]);
  }

  static String _count(double months) => months == months.roundToDouble() ? '${months.round()}' : '$months';
}

/// After an answer, or when there is nothing to answer.
class _Answered extends StatelessWidget {
  const _Answered({required this.message, required this.action, required this.onAction, this.detail, this.tone = HmNoteTone.success});

  final String message;
  final String? detail;
  final String action;
  final VoidCallback onAction;
  final HmNoteTone tone;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(HmSpace.xxl),
        children: [
          HmNote(text: message, tone: tone),
          if (detail != null) ...[
            const SizedBox(height: HmSpace.xl),
            Text(detail!, style: HmText.body),
          ],
          const SizedBox(height: HmSpace.xxl),
          HmButton(label: action, onPressed: onAction),
        ],
      );
}
