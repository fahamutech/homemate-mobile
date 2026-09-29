import 'package:flutter/material.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_top_bar.dart';
import '../../roles/data/app_role.dart';
import '../../roles/presentation/role_copy.dart';

/// A partner tab T09/T10 has not built yet.
class PartnerTabPlaceholder extends StatelessWidget {
  const PartnerTabPlaceholder({super.key, required this.role, required this.title});

  final AppRole role;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: HmTopBar(title: title),
        body: Padding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Text(context.text.partnerComingSoon(roleLabel(context.text, role)), style: HmText.body),
        ),
      );
}
