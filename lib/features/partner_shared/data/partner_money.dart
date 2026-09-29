import 'json_read.dart';

/// One share of a payment to this partner (BRK-050 / LND-040).
class Earning {
  const Earning({
    required this.id,
    required this.amount,
    required this.state,
    this.currency = 'TZS',
    this.purpose,
    this.holdReason,
    this.paymentReference,
    this.paymentConfirmedAt,
    this.propertyTitle,
    this.coverPhotoUrl,
    this.tenantName,
    this.payoutReference,
    this.payoutPaidAt,
  });

  final String id;
  final double amount;

  /// `being_checked`, `ready`, `in_payout`, `paid`, `on_hold`, `reversed`, `failed`.
  final String state;
  final String currency;

  /// `fee_share`, `rent_and_deposit`, `rent`, `deposit`, `other`.
  final String? purpose;
  final String? holdReason;
  final String? paymentReference;
  final DateTime? paymentConfirmedAt;
  final String? propertyTitle;
  final String? coverPhotoUrl;
  final String? tenantName;
  final String? payoutReference;
  final DateTime? payoutPaidAt;

  factory Earning.fromJson(Map<String, dynamic> json) => Earning(
        id: json['id'] as String? ?? '',
        amount: readNum(json['amount']),
        state: json['state'] as String? ?? 'being_checked',
        currency: json['currency'] as String? ?? 'TZS',
        purpose: json['purpose'] as String?,
        holdReason: json['holdReason'] as String?,
        paymentReference: json['paymentReference'] as String?,
        paymentConfirmedAt: readDate(json['paymentConfirmedAt']),
        propertyTitle: json['propertyTitle'] as String?,
        coverPhotoUrl: json['coverPhotoUrl'] as String?,
        tenantName: json['tenantName'] as String?,
        payoutReference: json['payoutReference'] as String?,
        payoutPaidAt: readDate(json['payoutPaidAt']),
      );
}

class EarningsOverview {
  const EarningsOverview({this.totals = const {}, this.paidThisYear = 0, this.items = const []});

  final Map<String, double> totals;
  final double paidThisYear;
  final List<Earning> items;

  double total(String state) => totals[state] ?? 0;

  factory EarningsOverview.fromJson(Map<String, dynamic> json) => EarningsOverview(
        totals: {for (final e in readMap(json['totals']).entries) e.key: readNum(e.value)},
        paidThisYear: readNum(json['paidThisYear']),
        items: readList(json['items'], Earning.fromJson),
      );
}

class SplitLine {
  const SplitLine({required this.beneficiary, required this.amount, this.purpose, this.you = false});

  final String beneficiary;
  final double amount;
  final String? purpose;
  final bool you;

  factory SplitLine.fromJson(Map<String, dynamic> json) => SplitLine(
        beneficiary: json['beneficiary'] as String? ?? '',
        amount: readNum(json['amount']),
        purpose: json['purpose'] as String?,
        you: json['you'] as bool? ?? false,
      );
}

class TimelinePoint {
  const TimelinePoint({required this.key, this.at, this.done = false});

  final String key;
  final DateTime? at;
  final bool done;

  factory TimelinePoint.fromJson(Map<String, dynamic> json) => TimelinePoint(
        key: json['key'] as String? ?? '',
        at: readDate(json['at']),
        done: json['done'] as bool? ?? false,
      );
}

/// BRK-051: the earning, how it was worked out (from the booking's own fee
/// snapshot), where the rest went, and its timeline.
class EarningDetail {
  const EarningDetail({
    required this.earning,
    this.split = const [],
    this.monthlyRent,
    this.feePercentage,
    this.feeAmount,
    this.platformPercentage,
    this.platformAmount,
    this.yourShare,
    this.timeline = const [],
  });

  final Earning earning;
  final List<SplitLine> split;
  final double? monthlyRent;
  final double? feePercentage;
  final double? feeAmount;
  final double? platformPercentage;
  final double? platformAmount;
  final double? yourShare;
  final List<TimelinePoint> timeline;

  bool get hasFee => feeAmount != null;

  factory EarningDetail.fromJson(Map<String, dynamic> json) {
    final fee = json['fee'] is Map<String, dynamic> ? json['fee'] as Map<String, dynamic> : null;
    return EarningDetail(
      earning: Earning.fromJson(json),
      split: readList(json['split'], SplitLine.fromJson),
      monthlyRent: fee == null ? null : readNum(fee['monthlyRent']),
      feePercentage: fee == null ? null : readNum(fee['feePercentage']),
      feeAmount: fee == null ? null : readNum(fee['feeAmount']),
      platformPercentage: fee == null ? null : readNum(fee['platformPercentage']),
      platformAmount: fee == null ? null : readNum(fee['platformAmount']),
      yourShare: fee == null ? null : readNum(fee['yourShare']),
      timeline: readList(json['timeline'], TimelinePoint.fromJson),
    );
  }
}

class Payout {
  const Payout({
    required this.id,
    required this.amount,
    required this.status,
    this.reference,
    this.currency = 'TZS',
    this.holdReason,
    this.failureReason,
    this.providerReference,
    this.destination,
    this.scheduledFor,
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final double amount;

  /// `scheduled`, `processing`, `paid`, `on_hold`, `failed`, `cancelled`.
  final String status;
  final String? reference;
  final String currency;
  final String? holdReason;
  final String? failureReason;
  final String? providerReference;
  final String? destination;
  final DateTime? scheduledFor;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory Payout.fromJson(Map<String, dynamic> json) => Payout(
        id: json['id'] as String? ?? '',
        amount: readNum(json['amount']),
        status: json['status'] as String? ?? 'scheduled',
        reference: json['reference'] as String?,
        currency: json['currency'] as String? ?? 'TZS',
        holdReason: json['holdReason'] as String?,
        failureReason: json['failureReason'] as String?,
        providerReference: json['providerReference'] as String?,
        destination: json['destination'] as String?,
        scheduledFor: readDate(json['scheduledFor']),
        paidAt: readDate(json['paidAt']),
        createdAt: readDate(json['createdAt']),
      );
}

class PayoutsOverview {
  const PayoutsOverview({this.accountMethod, this.accountProvider, this.accountName, this.accountNumber, this.items = const []});

  final String? accountMethod;
  final String? accountProvider;
  final String? accountName;

  /// Masked: "•••• 5678".
  final String? accountNumber;
  final List<Payout> items;

  bool get hasAccount => accountNumber != null;

  factory PayoutsOverview.fromJson(Map<String, dynamic> json) {
    final account = readMap(json['account']);
    return PayoutsOverview(
      accountMethod: account['method'] as String?,
      accountProvider: account['provider'] as String?,
      accountName: account['accountName'] as String?,
      accountNumber: account['accountNumber'] as String?,
      items: readList(json['items'], Payout.fromJson),
    );
  }
}

/// An item of a partner home's "Needs you" list.
class NeedsYouItem {
  const NeedsYouItem({required this.kind, required this.title, this.subtitle = '', this.targetId});

  /// `enquiry`, `listing_changes`, `confirm_listing`, `move_in`,
  /// `payment_checking`, `payment_verified`.
  final String kind;
  final String title;
  final String subtitle;
  final String? targetId;

  factory NeedsYouItem.fromJson(Map<String, dynamic> json) => NeedsYouItem(
        kind: json['kind'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        targetId: json['targetId'] as String?,
      );
}

/// BRK-010 / LND-010: the counts and the "Needs you" list.
class PartnerSummary {
  const PartnerSummary({this.counts = const {}, this.needsYou = const []});

  final Map<String, double> counts;
  final List<NeedsYouItem> needsYou;

  double count(String key) => counts[key] ?? 0;

  factory PartnerSummary.fromJson(Map<String, dynamic> json) => PartnerSummary(
        counts: {for (final e in readMap(json['counts']).entries) e.key: readNum(e.value)},
        needsYou: readList(json['needsYou'], NeedsYouItem.fromJson),
      );
}
