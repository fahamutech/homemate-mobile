import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../../roles/presentation/role_copy.dart';
import '../../data/partner_application.dart';
import '../../data/partner_providers.dart';
import '../payout_labels.dart';
import 'document_slot.dart';
import 'document_upload.dart';
import 'setup_frame.dart';
import 'setup_step.dart';

/// BRK-002d "We're checking your details", BRK-002e "We need one more
/// thing", and a refusal — where an application stands once it is sent.
class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final home = role == AppRole.broker ? Routes.brokerHome : Routes.landlordHome;
    return Scaffold(
      backgroundColor: HmColors.bgPrimary,
      appBar: HmTopBar(
        title: text.partnerAccount(roleLabel(text, role)),
        onBack: () => context.go(home),
        backTooltip: text.close,
      ),
      body: HmAsync(
        value: ref.watch(applicationsProvider),
        onRetry: () => ref.invalidate(applicationsProvider),
        data: (overview) {
          final application = overview.application(role.name);
          return switch (application.status) {
            'action_needed' => _ActionNeeded(role: role, overview: overview),
            'rejected' || 'suspended' => _Refused(role: role, application: application),
            'applied' || 'not_started' || 'invited' => _Unfinished(role: role, application: application),
            _ => _UnderReview(role: role, overview: overview),
          };
        },
      ),
    );
  }
}

/// A round icon over a title and a sentence — the head of each state.
class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.fill, required this.colour, required this.title, required this.body});

  final IconData icon;
  final Color fill;
  final Color colour;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: HmSpace.huge),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: colour),
          ),
          const SizedBox(height: HmSpace.xxl),
          Text(title, textAlign: TextAlign.center, style: HmText.title),
          const SizedBox(height: HmSpace.md),
          Text(body, textAlign: TextAlign.center, style: HmText.body),
          const SizedBox(height: HmSpace.huge),
        ],
      );
}

class _UnderReview extends ConsumerWidget {
  const _UnderReview({required this.role, required this.overview});

  final AppRole role;
  final ApplicationsOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final application = overview.application(role.name);
    final reference = ref.watch(referenceDataProvider).valueOrNull;
    String bankName(String code) =>
        reference?.banks.where((b) => b.code == code).map((b) => b.name).firstOrNull ?? code;

    Widget row(String label, String value, {required bool done}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: HmSpace.md),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle_outline_rounded : Icons.more_horiz_rounded,
                size: 20,
                color: done ? HmColors.success : HmColors.orangeAccent,
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(child: Text(label, style: HmText.label.copyWith(fontSize: 14))),
              Text(value, style: HmText.caption.copyWith(fontSize: 13)),
            ],
          ),
        );

    final identityVerified = overview.profile.identityVerified;
    return SetupFrame(
      actions: [
        HmButton(
          label: text.partnerReviewDraftFirst,
          icon: Icons.add_home_outlined,
          onPressed: () => context.go(role == AppRole.broker ? Routes.brokerListings : Routes.landlordHomes),
        ),
        HmButton(
          label: text.partnerReviewBackToCustomer,
          style: HmButtonStyle.outline,
          onPressed: () => ref.read(roleControllerProvider.notifier).open(AppRole.customer),
        ),
      ],
      children: [
        _Hero(
          icon: Icons.hourglass_top_rounded,
          fill: HmColors.orangeBg,
          colour: HmColors.orangeAccent,
          title: text.partnerReviewTitle,
          body: text.partnerReviewBody(roleLabel(text, role)),
        ),
        HmCard(
          child: Column(
            children: [
              row(text.partnerStepDetails, text.partnerReviewDone, done: application.isDone('details')),
              row(
                text.partnerReviewDocuments,
                identityVerified ? text.partnerDocVerified : text.partnerDocInReview,
                done: identityVerified,
              ),
              row(
                text.partnerReviewPayout,
                payoutAccountLine(overview.profile.payout, bankName: bankName),
                done: application.isDone('payout'),
              ),
              row(text.partnerReviewAgreement, text.partnerReviewAccepted, done: application.isDone('agreement')),
            ],
          ),
        ),
        const SizedBox(height: HmSpace.xxl),
        HmNote(text: text.partnerReviewDraftNote, tone: HmNoteTone.brand, icon: Icons.edit_note_rounded),
      ],
    );
  }
}

class _ActionNeeded extends ConsumerStatefulWidget {
  const _ActionNeeded({required this.role, required this.overview});

  final AppRole role;
  final ApplicationsOverview overview;

  @override
  ConsumerState<_ActionNeeded> createState() => _ActionNeededState();
}

class _ActionNeededState extends ConsumerState<_ActionNeeded> {
  bool _busy = false;
  String? _error;

  Future<void> _fix(DocumentSlot slot) async {
    setState(() => _busy = true);
    await uploadPartnerDocument(context, ref, slot);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _resubmit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingRepositoryProvider).submit(widget.role.name);
      ref.invalidate(applicationsProvider);
      await ref.read(roleControllerProvider.notifier).refresh();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final remediations = widget.overview.remediations;
    final slots = [for (final r in remediations) ?DocumentSlot.forType(r.documentType)];

    return SetupFrame(
      error: _error,
      actions: [
        for (final slot in slots.toSet())
          HmButton(
            label: slot == DocumentSlot.selfie ? text.partnerActionNewSelfie : '${text.partnerActionUpload} · ${slot.title(text)}',
            icon: slot.camera ? Icons.photo_camera_outlined : Icons.upload_rounded,
            busy: _busy,
            style: HmButtonStyle.outline,
            onPressed: () => _fix(slot),
          ),
        if (remediations.any((r) => r.documentType == null))
          HmButton(
            label: text.partnerActionEditDetails,
            style: HmButtonStyle.outline,
            onPressed: () => context.go(Routes.partnerSetup(widget.role, step: 'details')),
          ),
        HmButton(label: text.partnerActionResubmit, busy: _busy, onPressed: _resubmit),
      ],
      children: [
        _Hero(
          icon: Icons.error_outline_rounded,
          fill: HmColors.redBg,
          colour: HmColors.error,
          title: text.partnerActionTitle,
          body: text.partnerActionBody,
        ),
        for (final remediation in remediations) ...[
          Container(
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: BoxDecoration(
              color: HmColors.orangeBg,
              borderRadius: BorderRadius.circular(HmRadius.md),
              border: Border.all(color: HmColors.orangeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(DocumentSlot.forType(remediation.documentType)?.icon ?? Icons.info_outline_rounded,
                        size: 18, color: HmColors.orangeText),
                    const SizedBox(width: HmSpace.md),
                    Expanded(
                      child: Text(
                        DocumentSlot.forType(remediation.documentType)?.title(text) ?? text.partnerStepDetails,
                        style: HmText.label.copyWith(fontSize: 15, color: HmColors.orangeText),
                      ),
                    ),
                    HmBadge(label: text.roleStatusActionNeeded, tone: HmBadgeTone.warning),
                  ],
                ),
                const SizedBox(height: HmSpace.xl),
                Text(remediation.issue, style: HmText.label.copyWith(fontSize: 14)),
                const SizedBox(height: HmSpace.md),
                Text(remediation.requestedAction, style: HmText.caption.copyWith(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: HmSpace.xl),
        ],
        HmNote(text: text.partnerActionDraftsSafe),
      ],
    );
  }
}

class _Refused extends StatelessWidget {
  const _Refused({required this.role, required this.application});

  final AppRole role;
  final PartnerApplication application;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return SetupFrame(
      actions: [
        Consumer(
          builder: (context, ref, _) => HmButton(
            label: text.partnerReviewBackToCustomer,
            onPressed: () => ref.read(roleControllerProvider.notifier).open(AppRole.customer),
          ),
        ),
      ],
      children: [
        _Hero(
          icon: Icons.block_rounded,
          fill: HmColors.redBg,
          colour: HmColors.error,
          title: application.status == 'suspended'
              ? text.partnerSuspendedTitle(roleLabel(text, role))
              : text.partnerRejectedTitle,
          body: application.rejectionReason ?? '',
        ),
      ],
    );
  }
}

/// Opened before the setup was sent: straight back to where it stopped.
class _Unfinished extends StatelessWidget {
  const _Unfinished({required this.role, required this.application});

  final AppRole role;
  final PartnerApplication application;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return SetupFrame(
      actions: [
        HmButton(
          label: text.partnerHomeContinueSetup,
          onPressed: () => context.go(Routes.partnerSetup(role, step: application.nextStep == 'agreement' ? 'payout' : application.nextStep)),
        ),
      ],
      children: [
        _Hero(
          icon: Icons.edit_note_rounded,
          fill: HmColors.brandSubtle,
          colour: HmColors.brandPrimary,
          title: text.partnerHomeSetupTitle,
          body: text.partnerStatusApplied(roleLabel(text, role)),
        ),
        if (application.missingSteps.isNotEmpty)
          Text(
            text.partnerMissing(missingStepsSentence(text, application.missingSteps)),
            textAlign: TextAlign.center,
            style: HmText.caption,
          ),
      ],
    );
  }
}

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
