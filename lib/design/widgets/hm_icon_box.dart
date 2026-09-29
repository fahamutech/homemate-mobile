import 'package:flutter/material.dart';

import '../tokens.dart';

/// The rounded tinted square an icon sits in on list tiles, attention rows
/// and document cards.
class HmIconBox extends StatelessWidget {
  const HmIconBox({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize = 20,
    this.fill = HmColors.brandSubtle,
    this.colour = HmColors.brandPrimary,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color fill;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(HmRadius.lg - 6)),
        child: Icon(icon, size: iconSize, color: colour),
      );
}
