import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'journey_models.dart';
import 'models.dart';

/// The reads behind the Favourites screen, the checkout and the tenancies.
///
/// Every one of these is a `FutureProvider` rather than screen-local state so
/// that any screen can `invalidate` after acting and every affected screen
/// moves together — a payment made on one screen must not leave a stale
/// "awaiting payment" chip on another.

/// CUS-013a, whole, in one call.
final savedOverviewProvider = FutureProvider<SavedOverview>((ref) {
  return ref.watch(journeyRepositoryProvider).savedOverview();
});

/// "May I pay for this, and how did I get here?"
///
/// Watched by the property screen and the checkout alike, so the button and
/// the screen behind it can never disagree about who is allowed.
final checkoutEligibilityProvider =
    FutureProvider.family<CheckoutEligibility, String>((ref, propertyId) {
  return ref.watch(journeyRepositoryProvider).checkoutEligibility(propertyId);
});

final checkoutSummaryProvider = FutureProvider.family<CheckoutSummary, String>((ref, bookingId) {
  return ref.watch(journeyRepositoryProvider).checkoutSummary(bookingId);
});

final paymentMethodsProvider =
    FutureProvider.family<List<PaymentMethodOption>, String>((ref, propertyId) {
  return ref.watch(journeyRepositoryProvider).paymentMethods(propertyId);
});

/// Whatever this customer currently holds. The app bar's countdown watches
/// this, so a hold taken on one screen is visible on every other.
final myHoldsProvider = FutureProvider<List<PropertyHold>>((ref) {
  return ref.watch(journeyRepositoryProvider).myHolds();
});

final propertyJourneyProvider =
    FutureProvider.family<List<JourneyEvent>, String>((ref, propertyId) {
  return ref.watch(journeyRepositoryProvider).propertyJourney(propertyId);
});

final inquiryJourneyProvider =
    FutureProvider.family<List<JourneyEvent>, String>((ref, inquiryId) {
  return ref.watch(journeyRepositoryProvider).inquiryJourney(inquiryId);
});

final rentalsProvider = FutureProvider<Paged<Rental>>((ref) {
  return ref.watch(journeyRepositoryProvider).rentals(limit: 50);
});

final rentalProvider = FutureProvider.family<RentalDetail, String>((ref, bookingId) {
  return ref.watch(journeyRepositoryProvider).rental(bookingId);
});

final leaseProvider = FutureProvider.family<LeaseAgreement, String>((ref, bookingId) {
  return ref.watch(journeyRepositoryProvider).lease(bookingId);
});
