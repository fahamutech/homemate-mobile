import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/i18n/app_text.dart';
import '../../../core/pwa/install_controller.dart';
import '../../../core/pwa/install_widgets.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/customer_avatar.dart';
import '../../roles/presentation/work_with_homemate_section.dart';

/// CUS-019. The account: who you are, and the few things you can change.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(currentCustomerProvider);
    final summary = ref.watch(activitySummaryProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(context.text.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(HmSpace.xxl),
        children: [
          Row(
            children: [
              const CustomerAvatar(radius: 30, fontSize: 20),
              const SizedBox(width: HmSpace.xxl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.displayName ?? '',
                      style: HmText.heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: HmSpace.xxs),
                    Text(customer?.phoneNumber ?? '', style: HmText.caption),
                  ],
                ),
              ),
            ],
          ),

          if (customer != null && customer.kycStatus != 'not_started') ...[
            const SizedBox(height: HmSpace.huge),
            Row(
              children: [
                Text(context.text.partnerStepIdentity, style: HmText.caption),
                const SizedBox(width: HmSpace.md),
                HmStatusChip(customer.kycStatus, dense: true),
              ],
            ),
          ],

          const SizedBox(height: HmSpace.section),

          if (summary != null)
            Row(
              children: [
                _Stat(label: context.text.customerProfileFavourites, value: '${summary.savedCount}'),
                _Stat(label: context.text.navEnquiries, value: '${summary.openInquiries}'),
                _Stat(label: context.text.customerProfileRentals, value: '${summary.activeBookings}'),
              ],
            ),

          const SizedBox(height: HmSpace.section),
          const WorkWithHomeMateSection(),
          Text(context.text.customerProfileAccount, style: HmText.label),
          const SizedBox(height: HmSpace.md),
          _Item(
            icon: Icons.person_outline,
            label: context.text.partnerActionEditDetails,
            onTap: () => context.push(Routes.profileEdit),
          ),
          _Item(
            icon: Icons.verified_user_outlined,
            label: context.text.profileIdentity,
            onTap: () => context.push(Routes.identity),
          ),
          _Item(
            icon: Icons.tune,
            label: context.text.prefsTitle,
            onTap: () => context.push(Routes.preferences),
          ),
          _Item(
            icon: Icons.lock_outline,
            label: context.text.customerProfileChangePin,
            onTap: () => _changePin(context, ref),
          ),
          _Item(
            icon: Icons.notifications_outlined,
            label: context.text.notifications,
            onTap: () => context.push('${Routes.home}/notifications'),
          ),
          // Stays after "Not now" on the home card: this is where to find it later.
          if (ref.watch(installProvider).canInstall)
            _Item(
              icon: Icons.install_mobile,
              label: context.text.installProfileItem,
              onTap: () => startInstall(context, ref),
            ),

          const SizedBox(height: HmSpace.huge),
          Text(context.text.customerProfileSupport, style: HmText.label),
          const SizedBox(height: HmSpace.md),
          _Item(
            icon: Icons.help_outline,
            label: context.text.profileHelp,
            onTap: () => HmFeedback.info(context, context.text.profileHelpBody),
          ),
          _Item(
            icon: Icons.description_outlined,
            label: context.text.customerProfileTerms,
            onTap: () => HmFeedback.info(context, context.text.customerProfileTermsAt),
          ),

          const SizedBox(height: HmSpace.huge),
          OutlinedButton.icon(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(context.text.partnerSignOut),
            style: OutlinedButton.styleFrom(foregroundColor: HmColors.error),
          ),

          const SizedBox(height: HmSpace.huge),
          Center(
            child: Text(
              // Useful when someone reports "it is not working" from a build
              // nobody can identify.
              'HomeMate Africa · ${Uri.parse(Env.apiBaseUrl).host}',
              style: HmText.caption,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.text.customerProfileSignOutQ),
        content: Text(context.text.customerProfileSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.text.customerProfileStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: HmColors.error),
            child: Text(context.text.partnerSignOut),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final current = TextEditingController();
    final next = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.text.customerProfileChangePinTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PinInput(controller: current, label: context.text.customerProfileCurrentPin, autofocus: true),
            const SizedBox(height: HmSpace.xxl),
            _PinInput(controller: next, label: context.text.pinSetupNewPin),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.text.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.text.save),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        await ref.read(authRepositoryProvider).changePin(
              currentPin: current.text,
              pin: next.text,
              confirmPin: next.text,
            );
        if (context.mounted) HmFeedback.success(context, context.text.customerProfilePinChanged);
      } on ApiException catch (error) {
        if (context.mounted) HmFeedback.failure(context, error);
      }
    }
    current.dispose();
    next.dispose();
  }
}

class _PinInput extends StatelessWidget {
  const _PinInput({required this.controller, required this.label, this.autofocus = false});

  final TextEditingController controller;
  final String label;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(labelText: label),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: HmText.heading),
            const SizedBox(height: HmSpace.xxs),
            Text(label, style: HmText.caption),
          ],
        ),
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 20, color: HmColors.textSecondary),
        title: Text(label, style: HmText.body),
        trailing: const Icon(Icons.chevron_right, size: 18, color: HmColors.textDisabled),
        onTap: onTap,
      );
}
