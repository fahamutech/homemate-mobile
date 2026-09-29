import 'package:flutter/material.dart';

import '../../../core/i18n/app_text.dart';
import '../../partner_shared/presentation/partner_intro_screen.dart';
import '../../roles/data/app_role.dart';

/// BRK-001a–c: what being a broker on HomeMate means, before the setup.
class BrokerIntroScreen extends StatelessWidget {
  const BrokerIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return PartnerIntroScreen(
      role: AppRole.broker,
      startLabel: text.brokerIntroStart,
      slides: [
        (icon: Icons.add_home_outlined, title: text.brokerIntro1Title, body: text.brokerIntro1Body),
        (icon: Icons.forum_outlined, title: text.brokerIntro2Title, body: text.brokerIntro2Body),
        (icon: Icons.payments_outlined, title: text.brokerIntro3Title, body: text.brokerIntro3Body),
      ],
    );
  }
}
