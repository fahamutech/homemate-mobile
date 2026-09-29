import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design/widgets/hm_async.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_providers.dart';
import '../partner_intro_screen.dart';
import 'before_verification_home.dart';

/// A partner's Home tab, whichever the role: the intro for someone who has
/// not started, the "before verification" home while the account is checked
/// (BRK-010b / LND-010b), and [verified] once it is active.
class PartnerHomeGate extends ConsumerWidget {
  const PartnerHomeGate({super.key, required this.role, required this.verified});

  final AppRole role;
  final Widget verified;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: SafeArea(
          child: HmAsync(
            value: ref.watch(applicationsProvider),
            onRetry: () => ref.invalidate(applicationsProvider),
            data: (overview) {
              final application = overview.application(role.name);
              final introSeen = ref.watch(partnerIntroSeenProvider).contains(role);
              if (application.status == 'not_started' && !introSeen) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go(Routes.partnerIntro(role));
                });
                return const SizedBox.shrink();
              }
              if (!application.isActive) return BeforeVerificationHome(role: role, overview: overview);
              return verified;
            },
          ),
        ),
      );
}
