import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../core/i18n/app_text.dart';

/// Choosing the PIN the customer will sign in with from now on.
///
/// This is the step that replaces an SMS on every login. It runs straight
/// after a verified code, and the same screen serves a reset — only the words
/// change, because the act is identical.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, required this.verificationToken, this.isReset = false});

  final String verificationToken;
  final bool isReset;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      final session = widget.isReset
          ? await repository.resetPin(
              verificationToken: widget.verificationToken,
              pin: _pin.text,
              confirmPin: _confirm.text,
            )
          : await repository.setPin(
              verificationToken: widget.verificationToken,
              pin: _pin.text,
              confirmPin: _confirm.text,
            );
      await ref.read(authControllerProvider.notifier).adopt(session);
      // The router redirects onward — to the profile step, or straight home.
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
              const Icon(Icons.lock_outline_rounded, size: 44, color: HmColors.brandPrimary),
              const SizedBox(height: HmSpace.huge),
              Text(
                widget.isReset ? context.text.pinSetupTitleReset : context.text.pinSetupTitle,
                style: HmText.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HmSpace.md),
              Text(
                context.text.pinSetupBody,
                style: HmText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HmSpace.section),

              HmInlineError(_error),

              _PinField(
                key: const Key('new-pin'),
                controller: _pin,
                label: context.text.pinSetupNewPin,
                enabled: !_busy,
                autofocus: true,
                validator: _validatePin,
              ),
              const SizedBox(height: HmSpace.xxl),
              _PinField(
                key: const Key('confirm-pin'),
                controller: _confirm,
                label: context.text.pinSetupConfirmPin,
                enabled: !_busy,
                onSubmitted: (_) => _submit(),
                validator: (value) => value == _pin.text ? null : context.text.pinSetupMismatch,
              ),

              const SizedBox(height: HmSpace.xxl),
              Text(
                context.text.pinSetupHint,
                style: HmText.caption,
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
                    : Text(widget.isReset ? context.text.pinSetupSaveNew : context.text.pinSetupCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mirrors the server's rule so the customer is told before a round trip.
  /// The server still enforces it — this is a courtesy, not the guard.
  String? _validatePin(String? value) {
    final pin = value ?? '';
    if (pin.length < 4 || pin.length > 6) return context.text.pinSetupLength;
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return context.text.pinSetupPredictable;
    if (const {'1234', '4321', '123456', '654321', '2580'}.contains(pin)) {
      return context.text.pinSetupPredictable;
    }
    return null;
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        enabled: enabled,
        autofocus: autofocus,
        obscureText: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        onFieldSubmitted: onSubmitted,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      );
}
