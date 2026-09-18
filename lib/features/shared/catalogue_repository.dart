import '../../core/network/api_client.dart';
import 'models.dart';

/// The filters a search carries, as one value.
///
/// Passing a dozen named arguments through three layers is how a filter gets
/// silently dropped; one immutable object means the search screen, the map and
/// the results list are provably looking at the same thing.
class PropertyFilters {
  const PropertyFilters({
    this.query,
    this.propertyTypeId,
    this.regionId,
    this.districtId,
    this.wardId,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.furnishing,
    this.paymentFrequency,
    this.amenityIds = const [],
    this.latitude,
    this.longitude,
    this.radiusMetres,
  });

  final String? query;
  final String? propertyTypeId;
  final String? regionId;
  final String? districtId;
  final String? wardId;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final String? furnishing;
  final String? paymentFrequency;
  final List<String> amenityIds;
  final double? latitude;
  final double? longitude;
  final int? radiusMetres;

  /// How many filters are on, for the "Filters (3)" badge on CUS-002.
  int get activeCount => [
        propertyTypeId,
        regionId,
        districtId,
        wardId,
        minPrice,
        maxPrice,
        bedrooms,
        furnishing,
        paymentFrequency,
        radiusMetres,
      ].where((value) => value != null).length +
      (amenityIds.isEmpty ? 0 : 1);

  bool get isEmpty => activeCount == 0 && (query == null || query!.isEmpty);

  PropertyFilters copyWith({
    Object? query = _unset,
    Object? propertyTypeId = _unset,
    Object? regionId = _unset,
    Object? districtId = _unset,
    Object? wardId = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    Object? bedrooms = _unset,
    Object? furnishing = _unset,
    Object? paymentFrequency = _unset,
    List<String>? amenityIds,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? radiusMetres = _unset,
  }) =>
      PropertyFilters(
        // A sentinel rather than `??`, so a filter can actually be cleared —
        // `copyWith(regionId: null)` has to mean "remove it", not "keep it".
        query: query == _unset ? this.query : query as String?,
        propertyTypeId: propertyTypeId == _unset ? this.propertyTypeId : propertyTypeId as String?,
        regionId: regionId == _unset ? this.regionId : regionId as String?,
        districtId: districtId == _unset ? this.districtId : districtId as String?,
        wardId: wardId == _unset ? this.wardId : wardId as String?,
        minPrice: minPrice == _unset ? this.minPrice : minPrice as double?,
        maxPrice: maxPrice == _unset ? this.maxPrice : maxPrice as double?,
        bedrooms: bedrooms == _unset ? this.bedrooms : bedrooms as int?,
        furnishing: furnishing == _unset ? this.furnishing : furnishing as String?,
        paymentFrequency:
            paymentFrequency == _unset ? this.paymentFrequency : paymentFrequency as String?,
        amenityIds: amenityIds ?? this.amenityIds,
        latitude: latitude == _unset ? this.latitude : latitude as double?,
        longitude: longitude == _unset ? this.longitude : longitude as double?,
        radiusMetres: radiusMetres == _unset ? this.radiusMetres : radiusMetres as int?,
      );

  static const Object _unset = Object();

  Map<String, dynamic> toQuery({int limit = 20, int offset = 0}) => {
        'query': query,
        'propertyTypeId': propertyTypeId,
        'regionId': regionId,
        'districtId': districtId,
        'wardId': wardId,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'bedrooms': bedrooms,
        'furnishing': furnishing,
        'paymentFrequency': paymentFrequency,
        'amenityIds': amenityIds.isEmpty ? null : amenityIds,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMetres': radiusMetres,
        'limit': limit,
        'offset': offset,
      };

  @override
  bool operator ==(Object other) =>
      other is PropertyFilters &&
      other.query == query &&
      other.propertyTypeId == propertyTypeId &&
      other.regionId == regionId &&
      other.districtId == districtId &&
      other.wardId == wardId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.bedrooms == bedrooms &&
      other.furnishing == furnishing &&
      other.paymentFrequency == paymentFrequency &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusMetres == radiusMetres &&
      _sameList(other.amenityIds, amenityIds);

  @override
  int get hashCode => Object.hash(
        query,
        propertyTypeId,
        regionId,
        districtId,
        wardId,
        minPrice,
        maxPrice,
        bedrooms,
        furnishing,
        paymentFrequency,
        Object.hashAll(amenityIds),
        latitude,
        longitude,
        radiusMetres,
      );

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Finding places to live: search, one listing, saving, and the map's geocoder.
abstract class CatalogueRepository {
  Future<Paged<PropertySummary>> search(PropertyFilters filters, {int limit, int offset});
  Future<PropertyDetail> detail(String propertyId);
  Future<Paged<PropertySummary>> saved({int limit, int offset});
  Future<void> save(String propertyId, {String? note});
  Future<void> unsave(String propertyId);
  Future<List<GeoPlace>> searchPlaces(String query);

  /// The URL an image widget can load; the API streams the bytes with the
  /// session attached, so the app never holds storage credentials.
  String imageUrl(String mediaId, {bool thumbnail});
}

class HttpCatalogueRepository implements CatalogueRepository {
  HttpCatalogueRepository(this._api, {required String baseUrl}) : _baseUrl = baseUrl;

  final ApiClient _api;
  final String _baseUrl;

  @override
  Future<Paged<PropertySummary>> search(
    PropertyFilters filters, {
    int limit = 20,
    int offset = 0,
  }) async =>
      Paged.fromJson(
        await _api.get('/app/properties', query: filters.toQuery(limit: limit, offset: offset)),
        PropertySummary.fromJson,
      );

  @override
  Future<PropertyDetail> detail(String propertyId) async =>
      PropertyDetail.fromJson(await _api.get('/app/properties/$propertyId'));

  @override
  Future<Paged<PropertySummary>> saved({int limit = 20, int offset = 0}) async => Paged.fromJson(
        await _api.get('/app/saved', query: {'limit': limit, 'offset': offset}),
        PropertySummary.fromJson,
      );

  @override
  Future<void> save(String propertyId, {String? note}) async {
    await _api.put('/app/saved/$propertyId', body: {'note': note});
  }

  @override
  Future<void> unsave(String propertyId) async {
    await _api.delete('/app/saved/$propertyId');
  }

  @override
  Future<List<GeoPlace>> searchPlaces(String query) async {
    final response = await _api.get('/app/geocode', query: {'q': query});
    return (response['items'] as List? ?? const [])
        .map((row) => GeoPlace.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  String imageUrl(String mediaId, {bool thumbnail = false}) =>
      '$_baseUrl/app/media/$mediaId/raw${thumbnail ? '?thumbnail=1' : ''}';
}
