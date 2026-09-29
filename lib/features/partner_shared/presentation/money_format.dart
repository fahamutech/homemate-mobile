/// "1.08M", "360K" — money on a small tile, where the currency sits below.
String compactMoney(double value) {
  String trim(double v) {
    final fixed = v.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  if (value.abs() >= 1000000) return '${trim(value / 1000000)}M';
  if (value.abs() >= 1000) return '${trim(value / 1000)}K';
  return trim(value);
}
