import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../routing/routes.dart';
import '../../data/partner_listing.dart';
import '../contact_buttons.dart';
import '../enquiries/customer_avatar_initials.dart';

/// LND-021: on a home a broker listed, the landlord sees who the broker is,
/// can call or WhatsApp them, and — while it waits — confirm the listing.
class ListingBrokerCard extends StatelessWidget {
  const ListingBrokerCard({super.key, required this.listing});

  final PartnerListing listing;

  /// Shown only to the landlord of a home somebody else listed.
  static bool shows(PartnerListing listing) => !listing.listedByYou && listing.brokerName != null;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final name = listing.brokerName!;
    final waiting = (listing.landlord?.confirmationStatus ?? listing.landlordConfirmationStatus) == 'pending';
    return HmCard(
      title: text.landlordListingBroker,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          InitialsAvatar(name: name),
          const SizedBox(width: HmSpace.xl),
          Expanded(child: Text(name, style: HmText.label.copyWith(fontSize: 16))),
          if (listing.brokerPhone != null) ContactButtons(phone: listing.brokerPhone!),
        ]),
        const SizedBox(height: HmSpace.md),
        Text(text.landlordListingBrokerNote(name), style: HmText.caption),
        if (waiting) ...[
          const SizedBox(height: HmSpace.xl),
          HmButton(
            label: text.landlordListingConfirmNow,
            icon: Icons.fact_check_outlined,
            size: HmButtonSize.medium,
            onPressed: () => context.push(Routes.landlordConfirm(listing.id)),
          ),
        ],
      ]),
    );
  }
}
