import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import 'phone_field.dart';

/// CUS-006a. One screen for both people who have been here before and people
/// who have not.
///
/// A returning customer types their PIN and is in — no SMS, which is the whole
/// point of having a PIN. A new number goes to the code screen instead. The
/// app decides which by remembering the last number used on this device, and
/// the customer can always switch.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _pin = TextEditingController();

  bool _busy = false;
  String? _error;

  /// True once we believe this number already has a PIN, so the PIN field is
  /// worth showing. It starts from the remembered number rather than asking
  /// the server, which would leak whether a number is registered.
  bool _usePin = false;

  @override
  void initState() {
    super.initState();
    final remembered = ref.read(authControllerProvider).lastPhoneNumber;
    if (remembered != null) {
      _phone.text = remembered;
      _usePin = true;
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
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
      if (_usePin) {
        final session = await ref
            .read(authRepositoryProvider)
            .login(phoneNumber: phoneNumber, pin: _pin.text);
        await ref.read(authControllerProvider.notifier).adopt(session);
        // The router's redirect takes it from here.
        return;
      }

      final challenge =
          await ref.read(authRepositoryProvider).requestOtp(phoneNumber: phoneNumber);
      await ref.read(authControllerProvider.notifier).rememberPhoneNumber(phoneNumber);
      if (!mounted) return;
      context.go('${Routes.otp}?phone=$phoneNumber&challenge=${challenge.challengeId}');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = ApiException.unexpected().message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HmScaffold(
      backgroundColor: HmColors.bgPrimary,
      showBack: false,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HmSpace.section),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: HmColors.brandPrimary,
                    borderRadius: BorderRadius.circular(HmRadius.lg),
                  ),
                  child: const Icon(Icons.home_rounded, color: HmColors.textOnBrand),
                ),
              ),
              const SizedBox(height: HmSpace.huge),
              Text(
                _usePin ? 'Welcome back' : 'Sign in',
                style: HmText.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HmSpace.md),
              Text(
                _usePin
                    ? 'Enter your PIN to continue.'
                    : 'We will send a code to confirm your number.',
                style: HmText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HmSpace.section),

              HmInlineError(_error),

              PhoneField(
                controller: _phone,
                enabled: !_busy,
                autofocus: !_usePin,
                onSubmitted: (_) => _usePin ? null : _submit(),
              ),

              if (_usePin) ...[
                const SizedBox(height: HmSpace.xxl),
                TextFormField(
                  key: const Key('pin-field'),
                  controller: _pin,
                  enabled: !_busy,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) =>
                      (value ?? '').length < 4 ? 'Your PIN is at least 4 digits' : null,
                  decoration: const InputDecoration(labelText: 'PIN'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : () => context.go(Routes.forgotPin),
                    child: const Text('Forgot PIN?'),
                  ),
                ),
              ],

              const SizedBox(height: HmSpace.huge),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_usePin ? 'Sign in' : 'Send code'),
              ),
              const SizedBox(height: HmSpace.xxl),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _usePin = !_usePin;
                          _error = null;
                          _pin.clear();
                        }),
                child: Text(_usePin ? 'Use a different number' : 'I already have a PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
