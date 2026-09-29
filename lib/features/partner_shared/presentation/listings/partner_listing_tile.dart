import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_listing_card.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_listing.dart';
import '../partner_photo.dart';
import 'listing_status.dart';

/// One of the partner's listings on the home and the listings tab.
class PartnerListingTile extends StatelessWidget {
  const PartnerListingTile({super.key, required this.role, required this.listing});

  final AppRole role;
  final PartnerListingSummary listing;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final meta = switch (listing.status) {
      'approved' when listing.openEnquiries > 0 => text.listingOpenEnquiries(listing.openEnquiries),
      'pending_review' when listing.submittedAt != null => text.listingSent(DateFormat('d MMM').format(listing.submittedAt!)),
      'changes_requested' => text.listingSeeNote,
      _ => null,
    };
    return HmListingCard(
      key: ValueKey('listing-${listing.id}'),
      photo: PartnerPhoto(url: listing.coverPhotoUrl),
      title: listing.title,
      area: listing.referenceCode ?? '',
      price: text.listingPerMonth(HmMoney.format(listing.price, currency: listing.currency)),
      status: HmBadge(label: listingStatusLabel(text, listing.status), tone: listingStatusTone(listing.status)),
      meta: meta,
      listedBy: listedByLine(text, role, listing.listedByYou, listing.listedByName),
      onTap: () => context.push(Routes.partnerListing(role, listing.id)),
    );
  }
}

/// A landlord is told who listed each home; a broker only lists their own.
String? listedByLine(AppText text, AppRole role, bool listedByYou, String? name) {
  if (role != AppRole.landlord) return listedByYou ? null : name;
  return listedByYou ? text.listingListedByYou : text.listingListedByBroker(name ?? '');
}
