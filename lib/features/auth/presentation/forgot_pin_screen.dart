import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import 'phone_field.dart';

/// CUS-006d. The only route back in when the PIN is gone: prove the phone
/// again with a code.
///
/// The screen deliberately behaves identically for a registered and an
/// unregistered number — the server sends nothing for the latter, and saying
/// so here would turn this into a way to find out who has an account.
class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone.text = ref.read(authControllerProvider).lastPhoneNumber ?? '';
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phoneNumber = PhoneField.normalise(_phone.text)!;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .requestOtp(phoneNumber: phoneNumber, purpose: 'reset_pin');
      if (!mounted) return;

      if (!challenge.wasSent) {
        // No account for that number. The customer is told the same thing
        // either way, so nothing is revealed.
        HmFeedback.info(context, 'If that number has an account, a code is on its way.');
        context.go(Routes.signIn);
        return;
      }
      context.go(
        // Encoded: a raw '+' in a query string decodes as a space.
        '${Routes.otp}?phone=${Uri.encodeComponent(phoneNumber)}'
        '&challenge=${challenge.challengeId}&purpose=reset_pin',
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HmScaffold(
      title: 'Forgot PIN',
      onBack: () => context.go(Routes.signIn),
      backgroundColor: HmColors.bgPrimary,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HmSpace.huge),
              Text('Reset your PIN', style: HmText.title),
              const SizedBox(height: HmSpace.md),
              Text(
                'We will text a code to your number so you can choose a new one.',
                style: HmText.body,
              ),
              const SizedBox(height: HmSpace.section),
              HmInlineError(_error),
              PhoneField(
                controller: _phone,
                enabled: !_busy,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: HmSpace.huge),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
