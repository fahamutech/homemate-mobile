import 'package:flutter/material.dart';

import '../tokens.dart';

/// The white, hairline-bordered 12pt card the partner components sit on,
/// tappable when given [onTap].
class HmCardSurface extends StatelessWidget {
  const HmCardSurface({super.key, required this.child, this.padding = const EdgeInsets.all(HmSpace.xl), this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HmRadius.md);
    final body = Padding(padding: padding, child: child);
    return Material(
      color: HmColors.bgPrimary,
      shape: RoundedRectangleBorder(borderRadius: radius, side: const BorderSide(color: HmColors.borderDefault)),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}
