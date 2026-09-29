import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_step_progress.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../../roles/presentation/role_copy.dart';
import '../../data/partner_providers.dart';
import 'details_step.dart';
import 'identity_step.dart';
import 'payout_step.dart';
import 'setup_step.dart';

/// BRK-002a–c / LND-002a–d: the partner setup, one step at a time. Each step
/// saves before moving on; "Submit for review" ends on the status screen.
class PartnerSetupScreen extends ConsumerStatefulWidget {
  const PartnerSetupScreen({super.key, required this.role, this.initialStep = SetupStep.details});

  final AppRole role;
  final SetupStep initialStep;

  @override
  ConsumerState<PartnerSetupScreen> createState() => _PartnerSetupScreenState();
}

class _PartnerSetupScreenState extends ConsumerState<PartnerSetupScreen> {
  late SetupStep _step = widget.initialStep;

  List<SetupStep> get _steps => SetupStep.forRole(widget.role);

  void _next() {
    final index = _steps.indexOf(_step);
    if (index < _steps.length - 1) setState(() => _step = _steps[index + 1]);
  }

  void _back() {
    final index = _steps.indexOf(_step);
    if (index > 0) {
      setState(() => _step = _steps[index - 1]);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.role == AppRole.broker ? Routes.brokerHome : Routes.landlordHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final overview = ref.watch(applicationsProvider);
    final position = _steps.indexOf(_step) + 1;

    return Scaffold(
      backgroundColor: HmColors.bgSecondary,
      appBar: HmTopBar(
        title: text.partnerSetupTitle(roleLabel(text, widget.role)),
        onBack: _back,
        backTooltip: text.back,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, 0),
            child: HmStepProgress(
              current: position,
              total: _steps.length,
              label: text.partnerStepLabel(text.stepOf(position, _steps.length), setupStepName(text, _step.name)).toUpperCase(),
            ),
          ),
          Expanded(
            child: HmAsync(
              value: overview,
              onRetry: () => ref.invalidate(applicationsProvider),
              data: (loaded) => switch (_step) {
                SetupStep.details => DetailsStep(role: widget.role, profile: loaded.profile, onDone: _next),
                SetupStep.identity => IdentityStep(onDone: _next),
                SetupStep.ownership => IdentityStep(onDone: _next, ownership: true),
                SetupStep.payout => PayoutStep(
                    role: widget.role,
                    overview: loaded,
                    onSubmitted: () => context.go(Routes.partnerApplication(widget.role)),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
