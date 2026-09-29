import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../core/providers.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_money.dart';
import '../../../../../design/widgets/hm_note.dart';
import '../../../../../design/widgets/hm_section.dart';
import '../../../../roles/data/app_role.dart';
import '../../../data/partner_listing.dart';
import '../../partner_photo.dart';
import 'wizard_step.dart';
import '../../../../shared/reference_name.dart';

/// BRK-030g: every step at a glance with an Edit link, what stops it being
/// sent (in the server's words), and what the partner earns.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key, required this.role, required this.listing, required this.onEdit});

  final AppRole role;
  final PartnerListing listing;
  final ValueChanged<WizardStep> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final reference = ref.watch(referenceDataProvider).valueOrNull;
    String name(List items, String? id) => items.where((i) => i.id == id).map((i) => i.name as String).firstOrNull ?? '';
    final type = referenceName(text, name: name(reference?.propertyTypes ?? const [], listing.propertyTypeId));
    final place = [
      name(reference?.wards ?? const [], listing.wardId),
      name(reference?.districts ?? const [], listing.districtId),
      listing.regionName ?? name(reference?.regions ?? const [], listing.regionId),
    ].where((p) => p.isNotEmpty).join(', ');

    final rows = <(WizardStep, String, bool)>[
      (WizardStep.basics, text.wizardReviewBasics(type, listing.bedrooms ?? 0, listing.bathrooms ?? 0), listing.title.isNotEmpty),
      (
        WizardStep.location,
        '${listing.addressLine ?? place} · ${listing.hasPin ? text.wizardReviewPinSet : text.wizardReviewNoPin}',
        listing.hasPin,
      ),
      (
        WizardStep.terms,
        text.wizardReviewTerms(frequencyLabel(text, listing.paymentFrequency, customMonths: listing.customPaymentMonths), listing.depositMonths.round()),
        listing.price > 0,
      ),
      (WizardStep.amenities, text.wizardReviewAmenities(listing.amenityIds.length, listing.charges.length), true),
      if (role == AppRole.broker)
        (WizardStep.landlord, listing.landlord?.name ?? text.wizardReviewMissing, listing.landlord != null),
      (WizardStep.photos, text.wizardReviewPhotos(listing.photos.length), listing.photos.isNotEmpty),
    ];
    final preview = listing.moneyPreview;

    return ListView(
      padding: const EdgeInsets.all(HmSpace.xxl),
      children: [
        if (listing.photos.isNotEmpty)
          SizedBox(height: 180, child: PartnerPhoto(url: listing.photos.first.url ?? '/app/media/${listing.photos.first.id}/raw', radius: HmRadius.md)),
        const SizedBox(height: HmSpace.xxl),
        Text(listing.title, style: HmText.title),
        if (place.isNotEmpty) Text(place, style: HmText.caption.copyWith(fontSize: 13)),
        const SizedBox(height: HmSpace.xs),
        Text(text.listingPerMonth(HmMoney.format(listing.price)), style: HmText.price.copyWith(fontSize: 17)),
        const SizedBox(height: HmSpace.xxl),
        HmCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, (step, summary, done)) in rows.indexed) ...[
                if (index > 0) const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    done ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
                    color: done ? HmColors.success : HmColors.textTertiary,
                  ),
                  title: Text(step.label(text), style: HmText.label.copyWith(fontSize: 15)),
                  subtitle: Text(summary, style: HmText.caption),
                  trailing: TextButton(key: ValueKey('edit-${step.name}'), onPressed: () => onEdit(step), child: Text(text.wizardEdit)),
                ),
              ],
            ],
          ),
        ),
        if (listing.submitBlockers.isNotEmpty) ...[
          const SizedBox(height: HmSpace.xxl),
          Text(text.wizardCannotSend, style: HmText.label.copyWith(fontSize: 14)),
          const SizedBox(height: HmSpace.md),
          for (final blocker in listing.submitBlockers) ...[
            HmNote(text: blocker.message, tone: HmNoteTone.warning),
            const SizedBox(height: HmSpace.md),
          ],
        ],
        if (preview != null && preview.youEarn > 0) ...[
          const SizedBox(height: HmSpace.xxl),
          Container(
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: BoxDecoration(color: HmColors.greenBg, borderRadius: BorderRadius.circular(HmRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.wizardReviewWhenLet, style: HmText.caption.copyWith(color: HmColors.greenText)),
                const SizedBox(height: HmSpace.xs),
                Text(text.wizardReviewYouEarn(HmMoney.format(preview.youEarn)), style: HmText.title.copyWith(color: HmColors.greenText)),
                const SizedBox(height: HmSpace.xs),
                Text(
                  role == AppRole.broker
                      ? text.wizardReviewFeeLine(HmMoney.format(preview.tenantFee))
                      : text.wizardReviewRentLine,
                  style: HmText.caption.copyWith(color: HmColors.greenText),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
