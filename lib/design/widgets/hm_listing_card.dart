import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hm_card_surface.dart';

/// HM/Partner/ListingCard: a home in a broker's listings or a landlord's homes.
class HmListingCard extends StatelessWidget {
  const HmListingCard({
    super.key,
    required this.title,
    required this.area,
    required this.price,
    this.photo,
    this.status,
    this.meta,
    this.listedBy,
    this.listedByIcon = Icons.real_estate_agent_rounded,
    this.onTap,
  });

  final String title;
  final String area;
  final String price;

  /// The cover photo; a grey square when there is none yet.
  final Widget? photo;

  /// Usually an [HmBadge] with the listing's status.
  final Widget? status;
  final String? meta;

  /// "Listed by Neema (broker)" on a landlord's home a broker listed.
  final String? listedBy;
  final IconData listedByIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => HmCardSurface(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(HmRadius.lg - 6),
              child: SizedBox(
                width: 80,
                height: 80,
                child: photo ?? const ColoredBox(color: HmColors.surfaceInput),
              ),
            ),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: HmColors.textPrimary),
                  ),
                  const SizedBox(height: HmSpace.xs),
                  _IconLine(icon: Icons.location_on_outlined, text: area),
                  const SizedBox(height: HmSpace.xs),
                  Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: HmColors.brandPrimary)),
                  if (status != null || meta != null) ...[
                    const SizedBox(height: HmSpace.xs),
                    Row(
                      children: [
                        if (status != null) status!,
                        if (status != null && meta != null) const SizedBox(width: HmSpace.md),
                        if (meta != null)
                          Expanded(
                            child: Text(
                              meta!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: HmColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (listedBy != null) ...[
                    const SizedBox(height: HmSpace.xs),
                    _IconLine(icon: listedByIcon, text: listedBy!),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: HmColors.textSecondary),
          const SizedBox(width: HmSpace.xs),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: HmColors.textSecondary),
            ),
          ),
        ],
      );
}
