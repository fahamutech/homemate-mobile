import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_choice.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_money.dart';
import '../../shared/customer_avatar.dart';
import '../../shared/models.dart';

/// CUS-008a/b. "Complete your profile", in the three steps the designs draw.
///
/// It runs straight after the PIN is set, because everything that follows is
/// addressed to a person: a landlord receiving "+255712345678 would like to
/// view your flat" has been given nothing to go on.
///
/// Only the first step is compulsory. Step two makes the app useful sooner —
/// it is what "new match" notifications are matched against — and step three
/// is identity verification, which is explicitly skippable: somebody who only
/// wants to browse should not be stopped at a camera. Both can be finished
/// later from Profile.
///
/// The same widget serves Profile → Edit your details, in [ProfileEditScreen]
/// below, so the two cannot drift.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _step = 1;

  final _detailsKey = GlobalKey<ProfileDetailsFormState>();
  final _preferencesKey = GlobalKey<PreferencesFormState>();

  bool _busy = false;
  String? _error;

  static const _steps = 3;

  Future<void> _next() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      switch (_step) {
        case 1:
          if (!await _detailsKey.currentState!.save()) return;
        case 2:
          await _preferencesKey.currentState!.save();
      }
      if (!mounted) return;
      setState(() => _step += 1);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Leaving the wizard. The profile step is already saved by the time step
  /// three is on screen, so the router lets them through — what "finish" does
  /// here is stop asking.
  void _finish() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HmColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: _step == 1
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back a step',
                onPressed: _busy ? null : () => setState(() => _step -= 1),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HmSpace.huge,
                HmSpace.xxl,
                HmSpace.huge,
                HmSpace.md,
              ),
              child: HmStepHeader(step: _step, of: _steps),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: HmSpace.huge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HmInlineError(_error),
                    switch (_step) {
                      1 => ProfileDetailsForm(key: _detailsKey),
                      2 => PreferencesForm(key: _preferencesKey),
                      _ => const IdentityStep(),
                    },
                    const SizedBox(height: HmSpace.section),
                  ],
                ),
              ),
            ),
            _Footer(
              busy: _busy,
              step: _step,
              onContinue: _next,
              onFinish: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.busy,
    required this.step,
    required this.onContinue,
    required this.onFinish,
  });

  final bool busy;
  final int step;
  final Future<void> Function() onContinue;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.bgPrimary,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(HmSpace.huge),
            child: step < 3
                ? ElevatedButton(
                    onPressed: busy ? null : onContinue,
                    child: busy
                        ? const _Spinner()
                        : const Text('Continue'),
                  )
                : Column(
                    children: [
                      OutlinedButton(
                        onPressed: onFinish,
                        child: const Text('Skip for Now'),
                      ),
                      const SizedBox(height: HmSpace.xl),
                      ElevatedButton(
                        onPressed: onFinish,
                        child: const Text('Complete Profile'),
                      ),
                    ],
                  ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// Step 1 — who you are
// -----------------------------------------------------------------------------

/// Name, date of birth, gender, contact details and the profile photo.
///
/// A [GlobalKey] rather than a callback, because the wizard's footer button
/// lives outside this widget and has to be able to say "save yourself, and
/// tell me whether you managed".
class ProfileDetailsForm extends ConsumerStatefulWidget {
  const ProfileDetailsForm({super.key, this.showPhoto = true});

  final bool showPhoto;

  @override
  ConsumerState<ProfileDetailsForm> createState() => ProfileDetailsFormState();
}

class ProfileDetailsFormState extends ConsumerState<ProfileDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String _language = 'en';
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(currentCustomerProvider);
    _name.text = customer?.fullName ?? '';
    _email.text = customer?.email ?? '';
    _dateOfBirth = customer?.dateOfBirth;
    _gender = customer?.gender;
    _language = customer?.preferredLanguage ?? 'en';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Returns false when the form is not valid; throws [ApiException] when the
  /// server refuses it, so the caller can show one error in one place.
  Future<bool> save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;

    final customer = await ref.read(authRepositoryProvider).completeProfile(
          fullName: _name.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          preferredLanguage: _language,
          dateOfBirth: _dateOfBirth,
          gender: _gender,
        );
    await ref.read(authControllerProvider.notifier).applyProfile(customer);
    return true;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 28, now.month, now.day),
      // Nobody renting a home was born last week, and nobody is 120.
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Your date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Capped rather than sent at full resolution: a 12-megapixel portrait is
    // several megabytes of base64 over a mobile connection, for a 60pt circle.
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      await ref.read(identityRepositoryProvider).setPhoto(
            bytes: await picked.readAsBytes(),
            contentType: picked.mimeType ?? 'image/jpeg',
            filename: picked.name,
          );

      // The upload only changed the server. Re-read the account so the app
      // knows a photo now exists, and move the cache key past the picture it
      // replaced — without both, the avatar goes on showing initials or the
      // old face, and the customer is looking at a save that appears to have
      // done nothing.
      final customer = await ref.read(authRepositoryProvider).me();
      await ref.read(authControllerProvider.notifier).applyProfile(customer);
      ref.read(profilePhotoRevisionProvider.notifier).state++;

      if (mounted) HmFeedback.success(context, 'Photo saved');
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(currentCustomerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showPhoto) ...[
            const SizedBox(height: HmSpace.huge),
            Center(
              child: _PhotoPicker(
                busy: _uploadingPhoto,
                onTap: _uploadingPhoto ? null : _pickPhoto,
              ),
            ),
            const SizedBox(height: HmSpace.huge),
          ],

          const _FieldLabel('Full Name'),
          TextFormField(
            key: const Key('full-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            validator: (value) => (value ?? '').trim().isEmpty ? 'Please enter your name' : null,
            decoration: const InputDecoration(hintText: 'Your name as it appears on your ID'),
          ),

          const _FieldLabel('Date of Birth'),
          InkWell(
            onTap: _pickDate,
            borderRadius: HmRadius.card,
            child: InputDecorator(
              decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
              child: Text(
                _dateOfBirth == null ? 'DD / MM / YYYY' : _formatDate(_dateOfBirth!),
                style: _dateOfBirth == null
                    ? HmText.body.copyWith(color: HmColors.textDisabled)
                    : HmText.body.copyWith(color: HmColors.textPrimary),
              ),
            ),
          ),

          const _FieldLabel('Gender'),
          HmSegmentedPills<String?>(
            options: const [('male', 'Male'), ('female', 'Female'), ('other', 'Other')],
            value: _gender,
            onChanged: (value) => setState(() => _gender = _gender == value ? null : value),
          ),

          const _FieldLabel('Phone Number'),
          // Read-only: the number is what the session is built on, and
          // changing it is re-verifying a phone, not editing a field.
          TextFormField(
            enabled: false,
            initialValue: customer?.phoneNumber ?? '',
            decoration: const InputDecoration(
              helperText: 'Verified. To change it, sign in with the new number.',
            ),
          ),

          const _FieldLabel('Email Address'),
          TextFormField(
            key: const Key('email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              final email = (value ?? '').trim();
              if (email.isEmpty) return null; // optional
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                  ? null
                  : 'That does not look like an email address';
            },
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              helperText: 'Optional — for receipts and lease documents',
            ),
          ),

          const _FieldLabel('Language'),
          HmSegmentedPills<String>(
            options: const [('en', 'English'), ('sw', 'Kiswahili')],
            value: _language,
            onChanged: (value) => setState(() => _language = value),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} / '
      '${date.month.toString().padLeft(2, '0')} / ${date.year}';
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              if (busy)
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: HmColors.brandPrimarySoft,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const CustomerAvatar(radius: 44, fontSize: 28),
              Material(
                color: HmColors.brandPrimary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(HmSpace.md),
                    child: Icon(Icons.photo_camera, size: 16, color: HmColors.textOnBrand),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: HmSpace.md),
          TextButton(onPressed: onTap, child: const Text('Tap to change photo')),
        ],
      );
}

// -----------------------------------------------------------------------------
// Step 2 — what you are looking for
// -----------------------------------------------------------------------------

/// Where, what type, how big, how much, when, and what it must have.
///
/// Every list here comes from the backoffice's own dictionaries rather than a
/// hard-coded array, so a property type added there is offered here without a
/// release — and, more to the point, the ids saved against the customer are
/// the same ids the search filters by.
class PreferencesForm extends ConsumerStatefulWidget {
  const PreferencesForm({super.key});

  @override
  ConsumerState<PreferencesForm> createState() => PreferencesFormState();
}

class PreferencesFormState extends ConsumerState<PreferencesForm> {
  CustomerPreferences _draft = const CustomerPreferences();
  bool _loaded = false;

  /// The slider's ceiling. Above it the label reads "5M+", because a slider
  /// that reaches a hundred million makes every ordinary rent one pixel wide.
  static const _minBudget = 0.0;
  static const _maxBudget = 5000000.0;

  /// Not a stored field — it is a shorthand the customer picks and we turn
  /// into a date, which is what the API and the matching actually use.
  String _timeline = 'flexible';

  Future<void> save() async {
    await ref.read(identityRepositoryProvider).savePreferences(_draft);
    ref.invalidate(customerPreferencesProvider);
  }

  RangeValues get _budget => RangeValues(
        (_draft.budgetMin ?? _minBudget).clamp(_minBudget, _maxBudget),
        (_draft.budgetMax ?? _maxBudget).clamp(_minBudget, _maxBudget),
      );

  void _setTimeline(String value) {
    final today = DateTime.now();
    setState(() {
      _timeline = value;
      _draft = _draft.copyWith(
        moveInFrom: switch (value) {
          'immediately' => today,
          'two_weeks' => today.add(const Duration(days: 14)),
          'one_month' => DateTime(today.year, today.month + 1, today.day),
          _ => null,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reference = ref.watch(referenceDataProvider);
    final existing = ref.watch(customerPreferencesProvider);

    // Seed the draft once from whatever is already saved, then leave it alone
    // — re-seeding on every rebuild would undo the customer's edits.
    if (!_loaded && existing.hasValue) {
      _draft = existing.value!;
      _loaded = true;
    }

    return reference.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: HmSpace.section),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HmSpace.section),
        child: Column(
          children: [
            Text(
              'We could not load the options just now. You can set these later '
              'from your profile.',
              style: HmText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HmSpace.md),
            TextButton(
              onPressed: () => ref.invalidate(referenceDataProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Preferred Location'),
          DropdownButtonFormField<String?>(
            initialValue: _draft.preferredRegionId,
            isExpanded: true,
            hint: const Text('Anywhere in Tanzania'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Anywhere in Tanzania'),
              ),
              for (final region in data.regions)
                DropdownMenuItem<String?>(value: region.id, child: Text(region.name)),
            ],
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(preferredRegionId: value),
            ),
          ),

          const _FieldLabel('Preferred Property Type'),
          Wrap(
            spacing: HmSpace.md,
            runSpacing: HmSpace.md,
            children: [
              for (final type in data.propertyTypes)
                HmChoicePill(
                  label: type.name,
                  dense: true,
                  selected: _draft.propertyTypeIds.contains(type.id),
                  onTap: () => setState(() {
                    final next = [..._draft.propertyTypeIds];
                    next.contains(type.id) ? next.remove(type.id) : next.add(type.id);
                    _draft = _draft.copyWith(propertyTypeIds: next);
                  }),
                ),
            ],
          ),

          const _FieldLabel('Number of Bedrooms'),
          HmSegmentedPills<int?>(
            options: const [(0, 'Studio'), (1, '1'), (2, '2'), (3, '3'), (4, '4+')],
            value: _draft.bedroomsMin,
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(
                bedroomsMin: _draft.bedroomsMin == value ? null : value,
              ),
            ),
          ),

          const SizedBox(height: HmSpace.huge),
          Row(
            children: [
              Expanded(child: Text('Monthly Budget Range', style: HmText.label)),
              Text(_budgetLabel(), style: HmText.label.copyWith(color: HmColors.brandPrimary)),
            ],
          ),
          RangeSlider(
            values: _budget,
            min: _minBudget,
            max: _maxBudget,
            divisions: 20,
            labels: RangeLabels(HmMoney.format(_budget.start), _budgetCeiling()),
            onChanged: (values) => setState(() {
              _draft = _draft.copyWith(
                budgetMin: values.start <= _minBudget ? null : values.start,
                budgetMax: values.end >= _maxBudget ? null : values.end,
              );
            }),
          ),
          Row(
            children: [
              Expanded(child: Text(HmMoney.format(_minBudget), style: HmText.caption)),
              Text('${HmMoney.format(_maxBudget)}+', style: HmText.caption),
            ],
          ),

          const _FieldLabel('Move-in Timeline'),
          HmSegmentedPills<String>(
            options: const [
              ('immediately', 'Immediately'),
              ('two_weeks', '1-2 Weeks'),
              ('one_month', '1 Month'),
              ('flexible', 'Flexible'),
            ],
            value: _timeline,
            onChanged: _setTimeline,
          ),

          const _FieldLabel('Must-have Amenities'),
          _AmenityGrid(
            amenities: data.amenities,
            selected: _draft.amenityIds,
            onChanged: (ids) => setState(() => _draft = _draft.copyWith(amenityIds: ids)),
          ),
        ],
      ),
    );
  }

  String _budgetLabel() =>
      '${HmMoney.format(_budget.start)} – ${_budgetCeiling()}';

  String _budgetCeiling() =>
      _budget.end >= _maxBudget ? 'Any' : HmMoney.format(_budget.end);
}

/// Two columns of checkboxes, as the designs draw them.
class _AmenityGrid extends StatelessWidget {
  const _AmenityGrid({
    required this.amenities,
    required this.selected,
    required this.onChanged,
  });

  final List<ReferenceItem> amenities;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two per row on a phone, more when there is room; a fixed count would
        // either crowd a narrow screen or waste a wide one.
        final columns = constraints.maxWidth > 520 ? 3 : 2;
        final width = (constraints.maxWidth - HmSpace.md * (columns - 1)) / columns;

        return Wrap(
          spacing: HmSpace.md,
          runSpacing: HmSpace.md,
          children: [
            for (final amenity in amenities)
              SizedBox(
                width: width,
                child: HmCheckTile(
                  label: amenity.name,
                  checked: selected.contains(amenity.id),
                  onChanged: (checked) {
                    final next = [...selected];
                    checked ? next.add(amenity.id) : next.remove(amenity.id);
                    onChanged(next);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Step 3 — proving who you are
// -----------------------------------------------------------------------------

/// The ID and the selfie.
///
/// Explicitly skippable, and the screen says so: verification unlocks booking
/// and paying, but browsing, saving and enquiring do not need it, and an app
/// that demands a passport before it will show you a flat is an app people
/// delete.
class IdentityStep extends ConsumerStatefulWidget {
  const IdentityStep({super.key});

  @override
  ConsumerState<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<IdentityStep> {
  String? _uploading;
  bool _agreed = true;

  Future<void> _upload(String documentType, ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 88,
    );
    if (picked == null) return;

    setState(() => _uploading = documentType);
    try {
      await ref.read(identityRepositoryProvider).uploadDocument(
            documentType: documentType,
            bytes: await picked.readAsBytes(),
            contentType: picked.mimeType ?? 'image/jpeg',
            filename: picked.name,
          );
      ref.invalidate(identityStatusProvider);
      if (mounted) HmFeedback.success(context, 'Sent for verification');
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _chooseIdSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Photograph your ID'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose an existing photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _upload('national_id', source);
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(identityStatusProvider);
    final status = identity.valueOrNull ?? const IdentityStatus();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: HmSpace.section),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: HmColors.brandPrimarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 30, color: HmColors.brandPrimary),
          ),
        ),
        const SizedBox(height: HmSpace.xxl),
        Text('Almost Done!', style: HmText.title, textAlign: TextAlign.center),
        const SizedBox(height: HmSpace.md),
        Text(
          'Verify your identity to unlock all features',
          style: HmText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: HmSpace.huge),

        _EvidenceCard(
          icon: Icons.badge_outlined,
          title: 'National ID or Passport',
          subtitle: 'Upload government-issued ID',
          status: status.statusOf('national_id'),
          actionLabel: 'Upload Document',
          actionIcon: Icons.file_upload_outlined,
          busy: _uploading == 'national_id',
          onPressed: _chooseIdSource,
        ),
        const SizedBox(height: HmSpace.xxl),
        _EvidenceCard(
          icon: Icons.photo_camera_outlined,
          title: 'Take a Selfie',
          subtitle: 'We will match it with your ID',
          status: status.statusOf('selfie'),
          actionLabel: 'Take Photo',
          actionIcon: Icons.camera_alt_outlined,
          busy: _uploading == 'selfie',
          onPressed: () => _upload('selfie', ImageSource.camera),
        ),

        const SizedBox(height: HmSpace.huge),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: HmColors.textSecondary),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Text(
                'You can skip verification now and complete it later from your '
                'profile settings.',
                style: HmText.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: HmSpace.xxl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
            ),
            Expanded(
              child: Text(
                'I agree to the Terms of Service and Privacy Policy',
                style: HmText.body,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.actionLabel,
    required this.actionIcon,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final String actionLabel;
  final IconData actionIcon;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (badge, badgeColour) = switch (status) {
      'verified' => ('VERIFIED', HmColors.success),
      'pending' => ('IN REVIEW', HmColors.info),
      'rejected' => ('REJECTED', HmColors.error),
      _ => ('NOT VERIFIED', HmColors.warning),
    };

    return Container(
      padding: const EdgeInsets.all(HmSpace.xxl),
      decoration: BoxDecoration(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        border: Border.all(color: HmColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HmColors.surfaceInput,
                  borderRadius: BorderRadius.circular(HmRadius.sm),
                ),
                child: Icon(icon, size: 20, color: HmColors.brandPrimary),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: HmText.label),
                    const SizedBox(height: HmSpace.xxs),
                    Text(subtitle, style: HmText.caption),
                  ],
                ),
              ),
              const SizedBox(width: HmSpace.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HmSpace.md,
                  vertical: HmSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: badgeColour.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(HmRadius.pill),
                ),
                child: Text(
                  badge,
                  style: HmText.caption.copyWith(
                    color: badgeColour,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: HmSpace.xxl),
          OutlinedButton.icon(
            onPressed: busy ? null : onPressed,
            icon: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(actionIcon, size: 18),
            label: Text(status == 'not_started' ? actionLabel : 'Replace'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Profile → Edit your details
// -----------------------------------------------------------------------------

/// The same first step, reached from the profile screen rather than from
/// onboarding.
///
/// It is a route of its own rather than a re-entry into `/complete-profile`:
/// that path is where the router *holds* people whose profile is outstanding,
/// so a customer who has already finished was bounced straight back to the
/// home screen the moment they tapped "Edit your details".
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _detailsKey = GlobalKey<ProfileDetailsFormState>();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _detailsKey.currentState!.save()) return;
      if (!mounted) return;
      HmFeedback.success(context, 'Your details are saved');
      context.pop();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: HmColors.bgPrimary,
        appBar: AppBar(title: const Text('Edit your details'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HmSpace.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HmInlineError(_error),
                ProfileDetailsForm(key: _detailsKey),
                const SizedBox(height: HmSpace.section),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: _busy ? const _Spinner() : const Text('Save changes'),
                ),
              ],
            ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: HmSpace.huge, bottom: HmSpace.md),
        child: Text(text, style: HmText.label),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
