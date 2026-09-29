import '../../../../../core/i18n/app_text.dart';
import '../../../../roles/data/app_role.dart';

/// The add-a-home steps (BRK-030a–g). A landlord listing their own home has
/// no landlord step. Review is not counted in "STEP n OF m".
enum WizardStep {
  basics,
  location,
  terms,
  amenities,
  landlord,
  photos,
  review;

  static List<WizardStep> forRole(AppRole role) => [
        for (final step in values)
          if (step != landlord || role == AppRole.broker) step,
      ];

  static WizardStep? fromName(String? name) {
    for (final step in values) {
      if (step.name == name) return step;
    }
    return null;
  }

  String label(AppText text) => switch (this) {
        basics => text.wizardStepBasics,
        location => text.wizardStepLocation,
        terms => text.wizardStepTerms,
        amenities => text.wizardStepAmenities,
        landlord => text.wizardStepLandlord,
        photos => text.wizardStepPhotos,
        review => text.wizardReviewTitle,
      };
}

/// How often rent is paid, as the server names it.
const rentFrequencies = ['monthly', 'quarterly', 'semi_annual', 'annual', 'custom'];

String frequencyLabel(AppText text, String frequency, {int? customMonths}) => switch (frequency) {
      'monthly' => text.frequencyMonthly,
      'quarterly' => text.frequencyQuarterly,
      'semi_annual' => text.frequencySemiAnnual,
      'annual' => text.frequencyAnnual,
      'custom' => customMonths == null ? text.frequencyCustom : text.listingMonths(customMonths),
      _ => frequency,
    };
