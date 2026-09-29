import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../shared/models.dart';

/// A document a partner may be asked for, and how it is taken.
enum DocumentSlot {
  id(['national_id', 'passport'], Icons.badge_outlined, camera: false),
  selfie(['selfie'], Icons.photo_camera_outlined, camera: true),
  tin(['tin_certificate'], Icons.description_outlined, camera: false),
  licence(['business_licence'], Icons.storefront_outlined, camera: false),
  titleDeed(['title_deed'], Icons.home_work_outlined, camera: false),
  utilityBill(['utility_bill'], Icons.receipt_long_outlined, camera: false);

  const DocumentSlot(this.types, this.icon, {required this.camera});

  /// The KYC document types that fill this slot; the first is what is sent.
  final List<String> types;
  final IconData icon;

  /// A selfie is taken with the camera; the rest come from the gallery.
  final bool camera;

  String get uploadType => types.first;

  static DocumentSlot? forType(String? type) {
    for (final slot in values) {
      if (slot.types.contains(type)) return slot;
    }
    return null;
  }

  String title(AppText text) => switch (this) {
        id => text.partnerDocIdTitle,
        selfie => text.partnerDocSelfieTitle,
        tin => text.partnerDocTinTitle,
        licence => text.partnerDocLicenceTitle,
        titleDeed => text.partnerDocTitleDeedTitle,
        utilityBill => text.partnerDocUtilityBillTitle,
      };

  String body(AppText text) => switch (this) {
        id => text.partnerDocIdBody,
        selfie => text.partnerDocSelfieBody,
        tin => text.partnerDocTinBody,
        licence => text.partnerDocLicenceBody,
        titleDeed => text.partnerDocTitleDeedBody,
        utilityBill => text.partnerDocUtilityBillBody,
      };
}

/// Where a slot stands for this person: `verified`, `pending`, `rejected`,
/// or `missing`. A verified person's ID counts as verified whatever the row.
String documentState(IdentityStatus identity, DocumentSlot slot) {
  if (slot == DocumentSlot.id && identity.isVerified) return 'verified';
  final states = [for (final document in identity.documents) if (slot.types.contains(document.documentType)) document.status];
  if (states.contains('verified')) return 'verified';
  if (states.contains('pending')) return 'pending';
  if (states.contains('rejected')) return 'rejected';
  return 'missing';
}
