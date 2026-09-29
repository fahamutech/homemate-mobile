import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Partner/MoneyRow: one earning or payment — the home, what it was, the
/// amount and where it stands.
class HmMoneyRow extends StatelessWidget {
  const HmMoneyRow({
    super.key,
    required this.title,
    required this.detail,
    required this.amount,
    this.leading,
    this.status,
    this.onTap,
  });

  final String title;
  final String detail;
  final String amount;

  /// The home's photo; a grey square when there is none.
  final Widget? leading;
  final Widget? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.xl),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(HmRadius.sm),
                child: SizedBox(width: 40, height: 40, child: leading ?? const ColoredBox(color: HmColors.surfaceInput)),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HmColors.textPrimary)),
                    const SizedBox(height: HmSpace.xxs),
                    Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: HmColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HmColors.textPrimary)),
                  if (status != null) ...[const SizedBox(height: HmSpace.xs), status!],
                ],
              ),
            ],
          ),
        ),
      );
}
