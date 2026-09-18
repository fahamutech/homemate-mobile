import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';

/// CUS-008a. The last step of onboarding: who are you.
///
/// It is required rather than skippable because every enquiry and booking that
/// follows is addressed to a person — a landlord receiving "+255712345678
/// would like to view your flat" has been given nothing to go on.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  String _language = 'en';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(currentCustomerProvider);
    _name.text = customer?.fullName ?? '';
    _email.text = customer?.email ?? '';
    _language = customer?.preferredLanguage ?? 'en';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final customer = await ref.read(authRepositoryProvider).completeProfile(
            fullName: _name.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            preferredLanguage: _language,
          );
      await ref.read(authControllerProvider.notifier).applyProfile(customer);
      // The router lets them through to the home screen now.
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HmScaffold(
      showBack: false,
      backgroundColor: HmColors.bgPrimary,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HmSpace.section),
              Text('Tell us about you', style: HmText.title),
              const SizedBox(height: HmSpace.md),
              Text(
                'Landlords see your name when you enquire or book a viewing.',
                style: HmText.body,
              ),
              const SizedBox(height: HmSpace.section),

              HmInlineError(_error),

              TextFormField(
                key: const Key('full-name'),
                controller: _name,
                enabled: !_busy,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Please enter your name' : null,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: HmSpace.xxl),
              TextFormField(
                key: const Key('email'),
                controller: _email,
                enabled: !_busy,
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
                  labelText: 'Email (optional)',
                  helperText: 'For receipts and lease documents',
                ),
              ),

              const SizedBox(height: HmSpace.huge),
              const Text('Language', style: HmText.label),
              const SizedBox(height: HmSpace.md),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                ],
                selected: {_language},
                onSelectionChanged:
                    _busy ? null : (values) => setState(() => _language = values.first),
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
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
