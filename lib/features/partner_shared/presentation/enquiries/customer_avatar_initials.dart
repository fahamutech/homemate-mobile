import 'package:flutter/material.dart';

import '../../../../design/tokens.dart';

/// A customer's initials in a tinted circle.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '#';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: HmColors.brandSubtle,
        child: Text(initials(name), style: HmText.label.copyWith(color: HmColors.brandPrimary, fontSize: radius * 0.75)),
      );
}
