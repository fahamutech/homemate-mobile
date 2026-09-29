import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_choice.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../data/landlord_providers.dart';
import '../../data/tenancy.dart';
import 'tenancy_copy.dart';
import 'tenancy_tile.dart';

/// LND-030: the landlord's tenants, by moving in / living here / past.
class TenantsScreen extends ConsumerStatefulWidget {
  const TenantsScreen({super.key});

  @override
  ConsumerState<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends ConsumerState<TenantsScreen> {
  TenancyStage _stage = TenancyStage.movingIn;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Scaffold(
      appBar: HmTopBar(title: text.navTenants),
      body: HmAsync<List<Tenancy>>(
        value: ref.watch(tenanciesProvider(null)),
        onRetry: () => ref.invalidate(tenanciesProvider(null)),
        data: (all) {
          final shown = [for (final t in all) if (t.stage == _stage) t];
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tenanciesProvider(null)),
            child: ListView(
              padding: const EdgeInsets.all(HmSpace.xxl),
              children: [
                HmSegmentedPills<TenancyStage>(
                  optionKey: (stage) => ValueKey('tenants-tab-${stage.name}'),
                  options: [
                    for (final stage in TenancyStage.values)
                      (stage, '${tenancyStageLabel(text, stage)} (${all.where((t) => t.stage == stage).length})'),
                  ],
                  value: _stage,
                  onChanged: (stage) => setState(() => _stage = stage),
                ),
                const SizedBox(height: HmSpace.xxl),
                if (shown.isEmpty) Text(tenancyStageEmpty(text, _stage), textAlign: TextAlign.center, style: HmText.body),
                for (final tenancy in shown) ...[
                  TenancyTile(tenancy: tenancy),
                  const SizedBox(height: HmSpace.xl),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
