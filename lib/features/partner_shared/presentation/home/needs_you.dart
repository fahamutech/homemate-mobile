import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/widgets/hm_attention_row.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';

/// How a "Needs you" item from the home summary is drawn and where it goes.

({HmAttentionTone tone, IconData icon}) needsYouStyle(String kind) => switch (kind) {
      'enquiry' => (tone: HmAttentionTone.orange, icon: Icons.forum_outlined),
      'listing_changes' => (tone: HmAttentionTone.red, icon: Icons.edit_note_rounded),
      'confirm_listing' => (tone: HmAttentionTone.blue, icon: Icons.fact_check_outlined),
      'move_in' => (tone: HmAttentionTone.green, icon: Icons.key_outlined),
      'payment_checking' => (tone: HmAttentionTone.blue, icon: Icons.hourglass_top_rounded),
      'payment_verified' => (tone: HmAttentionTone.green, icon: Icons.payments_outlined),
      _ => (tone: HmAttentionTone.blue, icon: Icons.notifications_none_rounded),
    };

/// The server writes the title in English; the app says it in the person's
/// language, falling back to the server's words for a kind it does not know.
String needsYouTitle(AppText text, String kind, {String fallback = ''}) => switch (kind) {
      'enquiry' => text.partnerNeedsEnquiry,
      'listing_changes' => text.partnerNeedsListingChanges,
      'confirm_listing' => text.partnerNeedsConfirmListing,
      'move_in' => text.partnerNeedsMoveIn,
      'payment_checking' => text.partnerNeedsPaymentChecking,
      'payment_verified' => text.partnerNeedsPaymentVerified,
      _ => fallback,
    };

String? needsYouTarget(AppRole role, String kind, String? id) {
  if (id == null) return null;
  final root = '/${role.name}';
  return switch (kind) {
    'enquiry' => '$root/enquiries/$id',
    'listing_changes' => role == AppRole.broker ? '$root/listings/$id' : '$root/homes/$id',
    'confirm_listing' => Routes.landlordConfirm(id),
    'move_in' => '$root/tenants/$id',
    'payment_checking' || 'payment_verified' => role == AppRole.broker ? '$root/earnings/$id' : '$root/money/$id',
    _ => null,
  };
}
