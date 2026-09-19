import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import 'phone_field.dart';
import 'pin_keypad.dart';

/// CUS-006a. One screen for both people who have been here before and people
/// who have not.
///
/// Which one you get is decided by the device, not by a guess: a device that
/// has completed OTP *and* chosen a PIN opens straight on the keypad, and
/// everything else opens on the phone-number form and an SMS. That distinction
/// matters — the app used to remember the number as soon as a code was
/// requested, so abandoning the SMS step left the next launch asking for a PIN
/// that had never been created.
///
/// From the keypad there is always a way back out: "Not you?" forgets the
/// device and re-runs the SMS, and "Forgot PIN?" re-verifies the same number.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  /// The digits typed on the keypad. Never rendered — only counted, so the
  /// dots can show progress without the PIN being on screen.
  String _pin = '';

  bool _busy = false;
  String? _error;

  /// The PIN is at most 6 digits, but 4 is what the pad submits on: anything
  /// longer is confirmed with the button, because we cannot know when a
  /// 5-digit PIN is finished.
  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    final enrolled = ref.read(authControllerProvider).pinEnrolledNumber;
    _phone.text = enrolled ?? ref.read(authControllerProvider).lastPhoneNumber ?? '';
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  // --- the two ways in -------------------------------------------------------

  Future<void> _signInWithPin(String phoneNumber) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session =
          await ref.read(authRepositoryProvider).login(phoneNumber: phoneNumber, pin: _pin);
      await ref.read(authControllerProvider.notifier).adopt(session);
      // The router's redirect takes it from here.
    } on ApiException catch (error) {
      setState(() {
        _error = error.message;
        _pin = '';
      });
    } catch (_) {
      setState(() {
        _error = ApiException.unexpected().message;
        _pin = '';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode({String? purpose}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phoneNumber = PhoneField.normalise(_phone.text)!;
    await _requestOtp(phoneNumber, purpose: purpose ?? 'login');
  }

  Future<void> _requestOtp(String phoneNumber, {String purpose = 'login'}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge =
          await ref.read(authRepositoryProvider).requestOtp(phoneNumber: phoneNumber, purpose: purpose);
      await ref.read(authControllerProvider.notifier).rememberPhoneNumber(phoneNumber);
      if (!mounted) return;
      // Encoded, not interpolated: a raw '+' in a query string decodes as a
      // space, so the verify screen greeted people as "255712345678".
      context.go(
        '${Routes.otp}?phone=${Uri.encodeComponent(phoneNumber)}'
        '&challenge=${challenge.challengeId}&purpose=$purpose',
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = ApiException.unexpected().message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Not you?" — this device stops offering the PIN and goes back to SMS.
  Future<void> _forgetDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.text.differentNumberTitle),
        content: Text(context.text.differentNumberMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.text.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.text.continueLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).forgetDevice();
    if (!mounted) return;
    setState(() {
      _pin = '';
      _error = null;
      _phone.clear();
    });
  }

  // --- keypad plumbing -------------------------------------------------------

  void _onDigit(String digit, String phoneNumber) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin = _pin + digit;
      _error = null;
    });
    if (_pin.length == _pinLength) _signInWithPin(phoneNumber);
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final enrolled = ref.watch(authControllerProvider).pinEnrolledNumber;

    return HmScaffold(
      backgroundColor: HmColors.bgPrimary,
      showBack: false,
      body: enrolled == null ? _phoneForm() : _pinPad(enrolled),
    );
  }

  // --- the SMS path ----------------------------------------------------------

  Widget _phoneForm() => SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HmSpace.section),
              const _Logo(),
              const SizedBox(height: HmSpace.huge),
              Text(context.text.signInTitle, style: HmText.title, textAlign: TextAlign.center),
              const SizedBox(height: HmSpace.md),
              Text(
                context.text.signInMessage,
                style: HmText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HmSpace.section),

              HmInlineError(_error),

              PhoneField(
                controller: _phone,
                enabled: !_busy,
                autofocus: true,
                onSubmitted: (_) => _sendCode(),
              ),

              const SizedBox(height: HmSpace.huge),
              ElevatedButton(
                onPressed: _busy ? null : () => _sendCode(),
                child: _busy ? const _ButtonSpinner() : Text(context.text.sendCode),
              ),
              const SizedBox(height: HmSpace.xxl),
              Text(
                context.text.signInPinHint,
                style: HmText.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  // --- the PIN path ----------------------------------------------------------

  Widget _pinPad(String phoneNumber) => Column(
        children: [
          // The greeting scrolls and the keypad does not: on a short screen
          // (or with the text scaled up) it is the welcome that should give
          // way, never the keys someone is trying to reach.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: HmSpace.huge),
                  const _Logo(),
                  const SizedBox(height: HmSpace.huge),
                  Text(context.text.welcomeBack, style: HmText.title, textAlign: TextAlign.center),
                  const SizedBox(height: HmSpace.xs),
                  Text(phoneNumber, style: HmText.caption, textAlign: TextAlign.center),
                  const SizedBox(height: HmSpace.section),

                  PinDots(length: _pin.length, of: _pinLength, error: _error != null),
                  const SizedBox(height: HmSpace.xxl),

                  SizedBox(
                    height: 40,
                    child: _busy
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Center(
                            child: Text(
                              _error ?? 'Enter your PIN',
                              style: _error == null
                                  ? HmText.caption
                                  : HmText.caption.copyWith(color: HmColors.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          PinKeypad(
            enabled: !_busy,
            onDigit: (digit) => _onDigit(digit, phoneNumber),
            onBackspace: _onBackspace,
            // A PIN nobody can remember must not be a dead end: the same
            // number re-verified by SMS gets a new one.
            actionIcon: Icons.help_outline,
            actionLabel: 'Forgot your PIN',
            onAction: () => _requestOtp(phoneNumber, purpose: 'reset_pin'),
          ),
          const SizedBox(height: HmSpace.md),

          if (_pin.length > _pinLength)
            ElevatedButton(
              onPressed: _busy ? null : () => _signInWithPin(phoneNumber),
              child: _busy ? const _ButtonSpinner() : Text(context.text.signInTitle),
            ),

          TextButton(
            onPressed: _busy ? null : _forgetDevice,
            child: Text(context.text.notYou),
          ),
          const SizedBox(height: HmSpace.md),
        ],
      );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: HmColors.brandPrimary,
            borderRadius: BorderRadius.circular(HmRadius.lg),
          ),
          child: const Icon(Icons.home_rounded, color: HmColors.textOnBrand),
        ),
      );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
