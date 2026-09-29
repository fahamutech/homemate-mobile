import '../../partner_shared/data/json_read.dart';

/// LND-003: a home a broker listed in this person's name, waiting for them
/// to say it is theirs and the terms are right.
class ListingConfirmation {
  const ListingConfirmation({
    required this.propertyId,
    required this.title,
    this.referenceCode,
    this.addressLine,
    this.regionName,
    this.coverPhotoUrl,
    this.brokerName,
    this.price = 0,
    this.currency = 'TZS',
    this.depositMonths = 0,
    this.advanceRentMonths = 0,
    this.minLeaseMonths,
    this.paymentFrequency,
    this.availableFrom,
    this.requestedAt,
  });

  final String propertyId;
  final String title;
  final String? referenceCode;
  final String? addressLine;
  final String? regionName;
  final String? coverPhotoUrl;
  final String? brokerName;
  final double price;
  final String currency;
  final double depositMonths;
  final double advanceRentMonths;
  final int? minLeaseMonths;
  final String? paymentFrequency;
  final DateTime? availableFrom;
  final DateTime? requestedAt;

  String get place => [addressLine, regionName].where((p) => (p ?? '').isNotEmpty).join(', ');

  factory ListingConfirmation.fromJson(Map<String, dynamic> json) {
    final terms = readMap(json['terms']);
    return ListingConfirmation(
      propertyId: json['propertyId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      referenceCode: json['referenceCode'] as String?,
      addressLine: json['addressLine'] as String?,
      regionName: json['regionName'] as String?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      brokerName: readMap(json['broker'])['name'] as String?,
      price: readNum(terms['price']),
      currency: terms['currency'] as String? ?? 'TZS',
      depositMonths: readNum(terms['depositMonths']),
      advanceRentMonths: readNum(terms['advanceRentMonths']),
      minLeaseMonths: terms['minLeaseMonths'] == null ? null : readInt(terms['minLeaseMonths']),
      paymentFrequency: terms['paymentFrequency'] as String?,
      availableFrom: readDate(terms['availableFrom']),
      requestedAt: readDate(json['requestedAt']),
    );
  }
}
