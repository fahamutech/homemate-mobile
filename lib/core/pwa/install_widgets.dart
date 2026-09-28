import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens.dart';
import '../../design/widgets/hm_feedback.dart';
import '../i18n/app_text.dart';
import 'install_controller.dart';
import 'install_prompt.dart';

/// Installs the web app the only way this browser allows: its own dialog
/// where there is one, otherwise the steps for the customer to follow.
Future<void> startInstall(BuildContext context, WidgetRef ref) async {
  final method = ref.read(installProvider).method;
  switch (method) {
    case InstallMethod.prompt:
      final accepted = await ref.read(installProvider.notifier).prompt();
      if (accepted && context.mounted) HmFeedback.success(context, context.text.installInstalled);
    case InstallMethod.iosShareSheet || InstallMethod.browserMenu:
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        // Three steps and a title outgrow the default half-height sheet on a
        // small phone; let it take what it needs and scroll past that.
        isScrollControlled: true,
        builder: (_) => InstallStepsSheet(method: method),
      );
    case InstallMethod.none:
      break;
  }
}

/// CUS-001 addition: the home screen's invitation to install the PWA. Absent
/// in the native apps, in an installed PWA, and for a fortnight after "Not now".
class InstallAppCard extends ConsumerWidget {
  const InstallAppCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(installProvider);
    if (!state.showCard) return const SizedBox.shrink();
    final text = context.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HmSpace.xxl),
      decoration: BoxDecoration(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        border: Border.all(color: HmColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: HmColors.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(HmRadius.sm),
                ),
                child: const Icon(Icons.install_mobile, size: 18, color: HmColors.brandPrimary),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Text(text.installCardTitle, style: HmText.heading.copyWith(fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: HmSpace.xl),
          Text(text.installCardBody, style: HmText.caption.copyWith(fontSize: 13)),
          const SizedBox(height: HmSpace.xxl),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => startInstall(context, ref),
                  child: Text(text.installAction),
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(installProvider.notifier).dismiss(),
                  child: Text(text.installNotNow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The numbered steps for a browser that cannot show an install dialog.
class InstallStepsSheet extends StatelessWidget {
  const InstallStepsSheet({super.key, required this.method});

  final InstallMethod method;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final isIos = method == InstallMethod.iosShareSheet;
    final steps = isIos ? text.installIosSteps : text.installMenuSteps;
    final icons = isIos
        ? const [Icons.ios_share, Icons.add_box_outlined, Icons.check_circle_outline]
        : const [Icons.more_vert, Icons.install_mobile, Icons.check_circle_outline];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(HmSpace.huge, 0, HmSpace.huge, HmSpace.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isIos ? text.installIosTitle : text.installMenuTitle, style: HmText.title),
            const SizedBox(height: HmSpace.huge),
            for (var i = 0; i < steps.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: HmColors.brandPrimarySoft,
                    child: Icon(icons[i], size: 18, color: HmColors.brandPrimary),
                  ),
                  const SizedBox(width: HmSpace.xl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: HmSpace.sm),
                      child: Text('${i + 1}. ${steps[i]}', style: HmText.body),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HmSpace.xxl),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(text.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
