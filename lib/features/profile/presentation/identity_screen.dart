import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/error_text.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../auth/presentation/profile_setup_screen.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-008b, reached from Profile rather than from onboarding.
///
/// Verification is skippable during sign-up on purpose, so there has to be a
/// way back to it — otherwise "you can complete it later from your profile
/// settings" is a promise the app does not keep.
class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: HmColors.bgPrimary,
        appBar: AppBar(title: Text(context.text.profileIdentity), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HmSpace.huge),
            child: const IdentityStep(),
          ),
        ),
      );
}

/// The onboarding preferences step on its own, so what the customer is looking
/// for can be changed without re-running sign-up.
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final _formKey = GlobalKey<PreferencesFormState>();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _formKey.currentState!.save();
      if (!mounted) return;
      HmFeedback.success(context, context.text.prefsSaved);
      context.pop();
    } on ApiException catch (error) {
      setState(() => _error = errorText(context.text, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: HmColors.bgPrimary,
        appBar: AppBar(title: Text(context.text.prefsTitle), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(HmSpace.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HmInlineError(_error),
                PreferencesForm(key: _formKey),
                const SizedBox(height: HmSpace.section),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.text.save),
                ),
              ],
            ),
          ),
        ),
      );
}
