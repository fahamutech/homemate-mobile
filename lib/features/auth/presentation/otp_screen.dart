import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/error_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-006c / CUS-006e. Enter the code that was texted.
///
/// The resend button is disabled on a visible countdown rather than being
/// tappable and then refused: every code costs real credit, and a customer
/// mashing "resend" is how an SMS balance disappears. The wait comes from the
/// server's own answer, so the app and the quota never disagree.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.challengeId,
    this.purpose = 'login',
  });

  final String phoneNumber;
  final String challengeId;
  final String purpose;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  late String _challengeId = widget.challengeId;

  Timer? _ticker;
  int _resendIn = 60;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown(60);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _ticker?.cancel();
    setState(() => _resendIn = seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
        return;
      }
      setState(() => _resendIn -= 1);
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = context.text.otpEnterCode);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final verification = await ref
          .read(authRepositoryProvider)
          .verifyOtp(challengeId: _challengeId, code: _code.text);
      if (!mounted) return;

      // Verifying proves the phone; it does not sign anyone in. The next step
      // is choosing (or resetting) the PIN that will.
      context.go(
        '${Routes.pinSetup}?token=${verification.verificationToken}'
        '&reset=${widget.purpose == 'reset_pin'}',
      );
    } on ApiException catch (error) {
      setState(() {
        _error = errorText(context.text, error);
        _code.clear();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .requestOtp(phoneNumber: widget.phoneNumber, purpose: widget.purpose);
      if (challenge.challengeId != null) _challengeId = challenge.challengeId!;
      _startCountdown(challenge.resendAfterSeconds);
      if (mounted) HmFeedback.success(context, context.text.otpResent);
    } on ApiException catch (error) {
      // A refusal carries how long to wait, so the countdown restarts at the
      // server's number rather than the app guessing.
      if (error.retryAfterSeconds case final seconds?) _startCountdown(seconds);
      setState(() => _error = errorText(context.text, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HmScaffold(
      title: context.text.otpTitle,
      onBack: () => context.go(Routes.signIn),
      backgroundColor: HmColors.bgPrimary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: HmSpace.huge),
            Text(context.text.otpHeading, style: HmText.title, textAlign: TextAlign.center),
            const SizedBox(height: HmSpace.md),
            Text(
              context.text.otpSentTo(widget.phoneNumber),
              style: HmText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HmSpace.section),

            HmInlineError(_error),

            TextField(
              key: const Key('otp-field'),
              controller: _code,
              enabled: !_busy,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.w700),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              // Six digits is the whole code, so there is nothing to confirm.
              onChanged: (value) => value.length == 6 ? _verify() : null,
              decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            ),

            const SizedBox(height: HmSpace.huge),
            ElevatedButton(
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(context.text.otpVerify),
            ),
            const SizedBox(height: HmSpace.xxl),
            Center(
              child: _resendIn > 0
                  ? Text(context.text.otpResendIn(_resendIn), style: HmText.caption)
                  : TextButton(
                      onPressed: _busy ? null : _resend,
                      child: Text(context.text.otpSendAnother),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
