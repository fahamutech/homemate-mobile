import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';

/// CUS-019. The account: who you are, and the few things you can change.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(currentCustomerProvider);
    final summary = ref.watch(activitySummaryProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(HmSpace.xxl),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: HmColors.brandPrimarySoft,
                child: Text(
                  customer?.initials ?? '#',
                  style: const TextStyle(
                    color: HmColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
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
                const Text('Identity', style: HmText.caption),
                const SizedBox(width: HmSpace.md),
                HmStatusChip(customer.kycStatus, dense: true),
              ],
            ),
          ],

          const SizedBox(height: HmSpace.section),

          if (summary != null)
            Row(
              children: [
                _Stat(label: 'Favourites', value: '${summary.savedCount}'),
                _Stat(label: 'Enquiries', value: '${summary.openInquiries}'),
                _Stat(label: 'Viewings', value: '${summary.upcomingViewings}'),
                _Stat(label: 'Rentals', value: '${summary.activeBookings}'),
              ],
            ),

          const SizedBox(height: HmSpace.section),
          const Text('Account', style: HmText.label),
          const SizedBox(height: HmSpace.md),
          _Item(
            icon: Icons.person_outline,
            label: 'Edit your details',
            onTap: () => context.push(Routes.profileEdit),
          ),
          _Item(
            icon: Icons.verified_user_outlined,
            label: 'Identity verification',
            onTap: () => context.push(Routes.identity),
          ),
          _Item(
            icon: Icons.tune,
            label: 'What you are looking for',
            onTap: () => context.push(Routes.preferences),
          ),
          _Item(
            icon: Icons.lock_outline,
            label: 'Change PIN',
            onTap: () => _changePin(context, ref),
          ),
          _Item(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => context.push('${Routes.home}/notifications'),
          ),

          const SizedBox(height: HmSpace.huge),
          const Text('Support', style: HmText.label),
          const SizedBox(height: HmSpace.md),
          _Item(
            icon: Icons.help_outline,
            label: 'Help & support',
            onTap: () => HmFeedback.info(context, 'Call 0800 000 000 or email help@homemate.co.tz'),
          ),
          _Item(
            icon: Icons.description_outlined,
            label: 'Terms & privacy',
            onTap: () => HmFeedback.info(context, 'Available at homemate.co.tz/terms'),
          ),

          const SizedBox(height: HmSpace.huge),
          OutlinedButton.icon(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
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
        title: const Text('Sign out?'),
        content: const Text('You will need your PIN to sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: HmColors.error),
            child: const Text('Sign out'),
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
        title: const Text('Change your PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PinInput(controller: current, label: 'Current PIN', autofocus: true),
            const SizedBox(height: HmSpace.xxl),
            _PinInput(controller: next, label: 'New PIN'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
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
        if (context.mounted) HmFeedback.success(context, 'Your PIN has been changed');
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
