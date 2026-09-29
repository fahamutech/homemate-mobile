import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../rental/presentation/lease_details.dart';
import '../../../shared/journey_models.dart' show LeaseAgreement;
import '../../data/landlord_providers.dart';

/// LND-033: the lease behind a tenancy, as the landlord reads it — the same
/// view the tenant has, from the landlord's own endpoint.
class TenancyLeaseScreen extends ConsumerWidget {
  const TenancyLeaseScreen({super.key, required this.tenancyId});

  final String tenancyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: HmColors.bgSecondary,
        appBar: HmTopBar(title: context.text.leaseTitle),
        body: HmAsync<LeaseAgreement>(
          value: ref.watch(tenancyLeaseProvider(tenancyId)),
          onRetry: () => ref.invalidate(tenancyLeaseProvider(tenancyId)),
          data: (lease) => LeaseDetails(lease: lease),
        ),
      );
}
