import '../data/partner_application.dart';

/// Mobile money brands are the same in every language.
String payoutProviderLabel(String? code) => switch (code) {
      'mpesa' => 'M-Pesa',
      'mixx_by_yas' => 'Mixx by Yas',
      'airtel_money' => 'Airtel Money',
      'halopesa' => 'HaloPesa',
      null => '',
      _ => code,
    };

/// "M-Pesa •••• 678": recognisable, not usable.
String payoutAccountLine(PayoutAccount? account, {String Function(String code)? bankName}) {
  if (account == null) return '';
  final digits = (account.accountNumber ?? '').replaceAll(RegExp(r'\D'), '');
  final tail = digits.length > 3 ? digits.substring(digits.length - 3) : digits;
  final name = account.method == 'bank'
      ? (bankName?.call(account.provider ?? '') ?? account.provider ?? '')
      : payoutProviderLabel(account.provider);
  return '$name •••• $tail'.trim();
}

/// "M-Pesa •••• 5678" from what the payouts screen gets: the number is
/// already masked by the server.
String maskedAccountLine({String? method, String? provider, String? masked, String Function(String code)? bankName}) {
  final name = method == 'bank'
      ? (bankName?.call(provider ?? '') ?? provider ?? '')
      : payoutProviderLabel(provider);
  return '$name ${masked ?? ''}'.trim();
}
