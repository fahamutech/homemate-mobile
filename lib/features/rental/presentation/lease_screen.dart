import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../shared/journey_providers.dart';
import 'lease_details.dart';

/// CUS-012c. The lease behind a tenancy, drawn by [LeaseDetails] (which the
/// landlord's LND-033 shares).
class LeaseScreen extends ConsumerWidget {
  const LeaseScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lease = ref.watch(leaseProvider(bookingId));

    return HmScaffold(
      title: context.text.leaseTitle,
      padded: false,
      backgroundColor: HmColors.bgSecondary,
      body: HmAsync(
        value: lease,
        onRetry: () => ref.invalidate(leaseProvider(bookingId)),
        data: (data) => LeaseDetails(lease: data),
      ),
    );
  }
}
