import '../../../../core/i18n/app_text.dart';
import '../../../roles/data/app_role.dart';

/// The screens of a partner setup. Landlords add proof of ownership.
enum SetupStep {
  details,
  identity,
  ownership,
  payout;

  static List<SetupStep> forRole(AppRole role) => [
        details,
        identity,
        if (role == AppRole.landlord) ownership,
        payout,
      ];

  static SetupStep? fromName(String? name) {
    for (final step in values) {
      if (step.name == name) return step;
    }
    return null;
  }
}

/// A step's name, for the progress label and "Finish these steps first".
/// Takes the server's step codes too (`agreement` is part of getting paid).
String setupStepName(AppText text, String code) => switch (code) {
      'details' => text.partnerStepDetails,
      'identity' => text.partnerStepIdentity,
      'ownership' => text.partnerStepOwnership,
      'payout' || 'agreement' => text.partnerStepPayout,
      _ => code,
    };

/// "Identity, Getting paid" — the server's missing steps, once each, in words.
String missingStepsSentence(AppText text, List<String> codes) =>
    codes.map((code) => setupStepName(text, code)).toSet().join(', ');
