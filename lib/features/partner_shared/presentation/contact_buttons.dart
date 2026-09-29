import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_button.dart';

/// Call and WhatsApp a person: the customer who enquired, the tenant, the
/// broker who listed a landlord's home.
class ContactButtons extends ConsumerWidget {
  const ContactButtons({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final contact = ref.read(contactLauncherProvider);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      HmButton(
        label: text.enquiriesCall,
        icon: Icons.call_outlined,
        iconOnly: true,
        size: HmButtonSize.medium,
        style: HmButtonStyle.neutral,
        onPressed: () => contact.call(phone),
      ),
      const SizedBox(width: HmSpace.md),
      HmButton(
        label: text.enquiriesWhatsapp,
        icon: Icons.chat_outlined,
        iconOnly: true,
        size: HmButtonSize.medium,
        style: HmButtonStyle.neutral,
        onPressed: () => contact.whatsApp(phone),
      ),
    ]);
  }
}
