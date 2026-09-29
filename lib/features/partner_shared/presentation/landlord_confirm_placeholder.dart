import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_top_bar.dart';

/// Where `homemate://landlord/confirm/:propertyId` lands until T10 builds
/// LND-003 "Confirm your home".
class LandlordConfirmPlaceholder extends StatelessWidget {
  const LandlordConfirmPlaceholder({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: HmTopBar(
          title: context.text.landlordConfirmTitle,
          backTooltip: context.text.back,
          onBack: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Text(context.text.landlordConfirmBody, key: ValueKey('confirm-$propertyId'), style: HmText.body),
        ),
      );
}
