import 'package:flutter/material.dart';

import '../../../core/i18n/app_text.dart';
import '../../partner_shared/presentation/partner_intro_screen.dart';
import '../../roles/data/app_role.dart';

/// LND-001a–c: what being a landlord on HomeMate means, before the setup.
class LandlordIntroScreen extends StatelessWidget {
  const LandlordIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return PartnerIntroScreen(
      role: AppRole.landlord,
      startLabel: text.landlordIntroStart,
      slides: [
        (icon: Icons.add_home_outlined, title: text.landlordIntro1Title, body: text.landlordIntro1Body),
        (icon: Icons.payments_outlined, title: text.landlordIntro2Title, body: text.landlordIntro2Body),
        (icon: Icons.verified_user_outlined, title: text.landlordIntro3Title, body: text.landlordIntro3Body),
      ],
    );
  }
}
