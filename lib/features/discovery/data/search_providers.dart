import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/catalogue_repository.dart';
import '../../shared/models.dart';

/// The filters the search screen and the results share.
///
/// One notifier rather than screen-local state, because the filter sheet, the
/// results list and the map all have to be looking at the same thing — and
/// because a customer who backs out of a listing expects their search to still
/// be there.
class SearchFiltersNotifier extends StateNotifier<PropertyFilters> {
  SearchFiltersNotifier() : super(const PropertyFilters());

  void setQuery(String? query) =>
      state = state.copyWith(query: (query ?? '').trim().isEmpty ? null : query!.trim());

  void apply(PropertyFilters filters) => state = filters;

  void clear() => state = PropertyFilters(query: state.query);

  void clearAll() => state = const PropertyFilters();

  /// Used by the map when the customer drags to a new area.
  void setArea({double? latitude, double? longitude, int? radiusMetres}) => state = state.copyWith(
        latitude: latitude,
        longitude: longitude,
        radiusMetres: radiusMetres,
      );
}

final searchFiltersProvider =
    StateNotifierProvider<SearchFiltersNotifier, PropertyFilters>((ref) => SearchFiltersNotifier());

/// The current page of results.
///
/// Keyed on the filters, so changing one re-runs the search and nothing else
/// has to remember to. Riverpod disposes the old result for us.
final searchResultsProvider =
    FutureProvider.family<Paged<PropertySummary>, PropertyFilters>((ref, filters) {
  return ref.watch(catalogueRepositoryProvider).search(filters);
});

/// What the home screen shows before anyone searches: the newest listings.
final featuredPropertiesProvider = FutureProvider<Paged<PropertySummary>>((ref) {
  return ref.watch(catalogueRepositoryProvider).search(const PropertyFilters(), limit: 10);
});

/// The "Near you" list on the home screen.
///
/// Keyed on the filters so the category chips narrow it, and separate from
/// [featuredPropertiesProvider] so the two sections can hold different pages
/// of results without fighting over one cache entry.
///
/// "Near" is by listing recency until the app has the customer's location; the
/// server already orders by distance when it is given one, so this becomes
/// genuinely local the moment a position is passed in the filters.
final nearbyPropertiesProvider =
    FutureProvider.family<Paged<PropertySummary>, PropertyFilters>((ref, filters) {
  return ref.watch(catalogueRepositoryProvider).search(filters, limit: 6);
});

final savedPropertiesProvider = FutureProvider<Paged<PropertySummary>>((ref) {
  return ref.watch(catalogueRepositoryProvider).saved(limit: 50);
});

final propertyDetailProvider = FutureProvider.family<PropertyDetail, String>((ref, propertyId) {
  return ref.watch(catalogueRepositoryProvider).detail(propertyId);
});

/// Place lookups for the location picker. Empty until three characters, which
/// is what the API requires — asking sooner just earns an error.
final placeSearchProvider = FutureProvider.family<List<GeoPlace>, String>((ref, query) async {
  if (query.trim().length < 3) return const [];
  return ref.watch(catalogueRepositoryProvider).searchPlaces(query.trim());
});
