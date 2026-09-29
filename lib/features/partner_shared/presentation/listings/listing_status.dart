import '../../../../core/i18n/app_text.dart';
import '../../../../design/widgets/hm_badge.dart';

/// A listing's status, in words and colour, the same on every partner screen.
String listingStatusLabel(AppText text, String status) => switch (status) {
      'draft' => text.listingStatusDraft,
      'pending_review' => text.listingStatusPendingReview,
      'changes_requested' => text.listingStatusChangesRequested,
      'approved' => text.listingStatusApproved,
      'rejected' => text.listingStatusRejected,
      'rented' => text.listingStatusRented,
      'archived' => text.listingStatusArchived,
      _ => status,
    };

HmBadgeTone listingStatusTone(String status) => switch (status) {
      'approved' => HmBadgeTone.success,
      'pending_review' || 'rented' => HmBadgeTone.info,
      'changes_requested' => HmBadgeTone.warning,
      'rejected' => HmBadgeTone.error,
      _ => HmBadgeTone.neutral,
    };
