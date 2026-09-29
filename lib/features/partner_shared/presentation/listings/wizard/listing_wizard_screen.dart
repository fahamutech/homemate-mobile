import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/providers.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_async.dart';
import '../../../../../design/widgets/hm_button.dart';
import '../../../../../design/widgets/hm_feedback.dart';
import '../../../../../design/widgets/hm_step_progress.dart';
import '../../../../../design/widgets/hm_top_bar.dart';
import '../../../../../routing/routes.dart';
import '../../../../roles/data/app_role.dart';
import '../../../data/partner_listing.dart';
import '../../../data/partner_providers.dart';
import 'amenities_step.dart';
import 'basics_step.dart';
import 'landlord_step.dart';
import 'location_step.dart';
import 'photos_step.dart';
import 'review_step.dart';
import 'step_controller.dart';
import 'terms_step.dart';
import 'wizard_step.dart';

/// BRK-030a–g: add or edit a home. Every step saves the draft before moving
/// on; "Save draft" saves and closes; the review sends it (422 lists why not).
class ListingWizardScreen extends ConsumerStatefulWidget {
  const ListingWizardScreen({super.key, required this.role, this.listingId, this.initialStep = WizardStep.basics});

  final AppRole role;
  final String? listingId;
  final WizardStep initialStep;

  @override
  ConsumerState<ListingWizardScreen> createState() => _ListingWizardScreenState();
}

class _ListingWizardScreenState extends ConsumerState<ListingWizardScreen> {
  late WizardStep _step = widget.initialStep;
  PartnerListing? _listing;
  late bool _loading = widget.listingId != null;
  Object? _loadError;
  bool _busy = false;
  String? _error;
  final _controller = WizardStepController();

  List<WizardStep> get _steps => WizardStep.forRole(widget.role);
  List<WizardStep> get _counted => [for (final s in _steps) if (s != WizardStep.review) s];

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) _load();
  }

  Future<void> _load() async {
    try {
      final listing = await ref.read(listingsRepositoryProvider).get(widget.listingId!);
      setState(() {
        _listing = listing;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  /// Creates the draft on the first save, updates it after.
  Future<PartnerListing> _save(Map<String, dynamic> fields) async {
    final repository = ref.read(listingsRepositoryProvider);
    final listing = _listing == null ? await repository.create(fields) : await repository.update(_listing!.id, fields);
    if (mounted) setState(() => _listing = listing);
    ref.invalidate(partnerListingsProvider);
    return listing;
  }

  /// Saves what is on this step; false when the step is not ready.
  Future<bool> _saveStep() async {
    // Photos save as they go and the review has nothing to save.
    if (_step == WizardStep.photos || _step == WizardStep.review) return true;
    final fields = _controller.read();
    if (fields == null) return false;
    if (fields.isEmpty && _listing != null) return true;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _save(fields);
      return true;
    } on ApiException catch (error) {
      setState(() => _error = error.message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goTo(WizardStep step) => setState(() {
        _step = step;
        _error = null;
      });

  Future<void> _continue() async {
    if (!await _saveStep()) return;
    final index = _steps.indexOf(_step);
    if (index < _steps.length - 1) _goTo(_steps[index + 1]);
  }

  Future<void> _saveDraft() async {
    if (!await _saveStep()) return;
    if (!mounted) return;
    HmFeedback.success(context, context.text.wizardSaved);
    _close();
  }

  void _close() => context.canPop() ? context.pop() : context.go(Routes.partnerListings(widget.role));

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await ref.read(listingsRepositoryProvider).submit(_listing!.id);
      ref.invalidate(partnerListingsProvider);
      if (mounted) context.go(Routes.partnerListingSent(widget.role, sent.id));
    } on ApiException catch (error) {
      final reasons = [
        for (final reason in (error.details['reasons'] as List? ?? const []))
          if (reason is Map) '${reason['message']}' else '$reason',
      ];
      setState(() => _error = reasons.isEmpty ? error.message : reasons.join('\n'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _body() {
    final listing = _listing;
    if (_step == WizardStep.basics || listing == null) {
      return BasicsStep(key: const ValueKey('basics'), listing: listing, controller: _controller);
    }
    return switch (_step) {
      WizardStep.basics => const SizedBox.shrink(),
      WizardStep.location => LocationStep(key: const ValueKey('location'), listing: listing, controller: _controller),
      WizardStep.terms => TermsStep(
          key: const ValueKey('terms'),
          listing: listing,
          controller: _controller,
          autosave: (fields) async {
            try {
              await _save(fields);
            } catch (_) {
              // The preview stays as it was; Continue reports any problem.
            }
          },
        ),
      WizardStep.amenities => AmenitiesStep(key: const ValueKey('amenities'), listing: listing, controller: _controller),
      WizardStep.landlord => LandlordStep(key: const ValueKey('landlord'), listing: listing, controller: _controller),
      WizardStep.photos => PhotosStep(
          key: const ValueKey('photos'),
          listing: listing,
          onChanged: (updated) => setState(() => _listing = updated),
        ),
      WizardStep.review => ReviewStep(role: widget.role, listing: listing, onEdit: _goTo),
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final reviewing = _step == WizardStep.review;

    if (_loading || _loadError != null) {
      return Scaffold(
        appBar: HmTopBar(title: text.wizardTitle, onBack: _close, backTooltip: text.close),
        body: HmAsync<void>(
          value: _loadError == null ? const AsyncLoading() : AsyncError(_loadError!, StackTrace.current),
          onRetry: () {
            setState(() {
              _loading = true;
              _loadError = null;
            });
            _load();
          },
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final position = _counted.indexOf(_step) + 1;
    return Scaffold(
      backgroundColor: HmColors.bgSecondary,
      appBar: HmTopBar(
        title: reviewing ? text.wizardReviewTitle : text.wizardTitle,
        onBack: reviewing ? () => _goTo(_counted.last) : _close,
        backTooltip: reviewing ? text.back : text.close,
        actions: [
          if (!reviewing)
            TextButton(onPressed: _busy ? null : _saveDraft, child: Text(text.wizardSaveDraft)),
        ],
      ),
      body: Column(
        children: [
          if (!reviewing)
            Padding(
              padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, 0),
              child: HmStepProgress(
                current: position,
                total: _counted.length,
                label: text.partnerStepLabel(text.stepOf(position, _counted.length), _step.label(text)).toUpperCase(),
              ),
            ),
          Expanded(child: _body()),
          Container(
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: const BoxDecoration(
              color: HmColors.bgPrimary,
              border: Border(top: BorderSide(color: HmColors.borderDefault)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HmInlineError(_error),
                  if (reviewing) ...[
                    HmButton(
                      label: text.wizardSend,
                      icon: Icons.send_outlined,
                      busy: _busy,
                      onPressed: (_listing?.canSubmit ?? false) ? _send : null,
                    ),
                    const SizedBox(height: HmSpace.md),
                    Text(text.wizardSendNote, textAlign: TextAlign.center, style: HmText.caption),
                  ] else
                    HmButton(
                      label: _step == _counted.last ? text.wizardReview : text.continueLabel,
                      busy: _busy,
                      onPressed: _continue,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
