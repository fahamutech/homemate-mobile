import 'package:flutter/material.dart';

import '../../../core/i18n/app_text.dart';
import '../data/app_role.dart';

/// How a role is named, drawn and described — the same on every screen.
IconData roleIcon(AppRole role) => switch (role) {
      AppRole.customer => Icons.search_rounded,
      AppRole.broker => Icons.real_estate_agent_rounded,
      AppRole.landlord => Icons.key_rounded,
    };

String roleLabel(AppText text, AppRole role) => switch (role) {
      AppRole.customer => text.roleCustomer,
      AppRole.broker => text.roleBroker,
      AppRole.landlord => text.roleLandlord,
    };

String roleSummary(AppText text, AppRole role) => switch (role) {
      AppRole.customer => text.roleCustomerSummary,
      AppRole.broker => text.roleBrokerSummary,
      AppRole.landlord => text.roleLandlordSummary,
    };

/// A partner role that is not active yet says where it stands; null otherwise.
String? roleStatusLabel(AppText text, String? status) => switch (status) {
      'applied' => text.roleStatusApplied,
      'pending_review' => text.roleStatusPendingReview,
      'action_needed' => text.roleStatusActionNeeded,
      _ => null,
    };
