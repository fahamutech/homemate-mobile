import '../../../core/i18n/app_text.dart';
import '../../shared/journey_models.dart';

/// The chip on the right of a rental: months left while there is time, then
/// days once it is close enough to count them.
///
/// The switch to days happens at three months because "2 months" and
/// "45 days" are the same fact, and only one of them makes a tenant act.
String rentalRemaining(AppText text, Rental rental) {
  final days = rental.daysRemaining;
  final months = rental.monthsRemaining;
  if (days != null && days <= 90) return text.leaseNoticeDays(days);
  if (months != null) return text.listingMonths(months);
  return text.rentalsActive;
}
