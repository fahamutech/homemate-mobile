import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../discovery/data/search_providers.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';

/// CUS-005. One listing, in full.
///
/// The two things a customer can do from here — ask a question, arrange a
/// viewing — are pinned to the bottom, because this is a long page and an
/// action found only after scrolling past the house rules is an action nobody
/// takes.
class PropertyScreen extends ConsumerWidget {
  const PropertyScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(propertyDetailProvider(propertyId));

    return Scaffold(
      body: HmAsync(
        value: detail,
        onRetry: () => ref.invalidate(propertyDetailProvider(propertyId)),
        data: (property) => _Loaded(detail: property),
      ),
      bottomNavigationBar: detail.maybeWhen(
        data: (property) => _Actions(detail: property),
        orElse: () => null,
      ),
    );
  }
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.detail});

  final PropertyDetail detail;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded> {
  late bool _saved = widget.detail.isSaved;
  int _photo = 0;

  Future<void> _toggleSaved() async {
    final next = !_saved;
    setState(() => _saved = next);
    try {
      final repository = ref.read(catalogueRepositoryProvider);
      final id = widget.detail.summary.id;
      next ? await repository.save(id) : await repository.unsave(id);
      ref.invalidate(activitySummaryProvider);
      ref.invalidate(savedPropertiesProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saved = !next);
      HmFeedback.failure(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final property = detail.summary;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: _CircleButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            onPressed: () => context.pop(),
          ),
          actions: [
            _CircleButton(
              icon: _saved ? Icons.favorite : Icons.favorite_outline,
              tooltip: _saved ? 'Remove from saved' : 'Save this property',
              colour: _saved ? HmColors.error : null,
              onPressed: _toggleSaved,
            ),
            const SizedBox(width: HmSpace.md),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _Gallery(
              media: detail.media,
              index: _photo,
              onChanged: (index) => setState(() => _photo = index),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          sliver: SliverList.list(
            children: [
              Text(property.title, style: HmText.title),
              const SizedBox(height: HmSpace.md),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: HmColors.textSecondary),
                  const SizedBox(width: HmSpace.xs),
                  Expanded(
                    child: Text(property.addressLine ?? property.locationLabel, style: HmText.caption),
                  ),
                ],
              ),
              const SizedBox(height: HmSpace.xxl),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text(property.priceLabel, style: HmText.price)),
                  if (property.totalMonthlyCost != null &&
                      property.totalMonthlyCost != property.price)
                    Text(
                      '${HmMoney.format(property.totalMonthlyCost, currency: property.currency)} all in',
                      style: HmText.caption,
                    ),
                ],
              ),

              const SizedBox(height: HmSpace.huge),
              _FactStrip(property: property, detail: detail),

              if (detail.description != null && detail.description!.isNotEmpty) ...[
                const SizedBox(height: HmSpace.huge),
                const Text('About this home', style: HmText.heading),
                const SizedBox(height: HmSpace.md),
                Text(detail.description!, style: HmText.body),
              ],

              if (detail.amenities.isNotEmpty) ...[
                const SizedBox(height: HmSpace.huge),
                const Text('What is included', style: HmText.heading),
                const SizedBox(height: HmSpace.xl),
                Wrap(
                  spacing: HmSpace.md,
                  runSpacing: HmSpace.md,
                  children: [
                    for (final amenity in detail.amenities)
                      Chip(
                        avatar: const Icon(Icons.check, size: 15, color: HmColors.brandPrimary),
                        label: Text(amenity.name),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: HmSpace.huge),
              _Terms(detail: detail),

              if (detail.charges.isNotEmpty) ...[
                const SizedBox(height: HmSpace.huge),
                const Text('Other charges', style: HmText.heading),
                const SizedBox(height: HmSpace.md),
                for (final charge in detail.charges)
                  _Row(
                    label: '${charge.name}${charge.isRefundable ? ' (refundable)' : ''}',
                    value: '${HmMoney.format(charge.amount)} · ${HmStatusChip.humanise(charge.frequency)}',
                  ),
              ],

              if (property.hasLocation) ...[
                const SizedBox(height: HmSpace.huge),
                const Text('Where it is', style: HmText.heading),
                const SizedBox(height: HmSpace.xl),
                _MiniMap(latitude: property.latitude!, longitude: property.longitude!),
              ],

              const SizedBox(height: HmSpace.huge),
              _Contact(detail: detail),

              if (detail.houseRules != null && detail.houseRules!.isNotEmpty) ...[
                const SizedBox(height: HmSpace.huge),
                const Text('House rules', style: HmText.heading),
                const SizedBox(height: HmSpace.md),
                Text(detail.houseRules!, style: HmText.body),
              ],

              // Clears the pinned action bar so the last line is readable.
              const SizedBox(height: 96),
            ],
          ),
        ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.media, required this.index, required this.onChanged});

  final List<PropertyMedia> media;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const PropertyImage(mediaId: null, borderRadius: BorderRadius.zero);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          onPageChanged: onChanged,
          itemCount: media.length,
          itemBuilder: (_, position) => PropertyImage(
            mediaId: media[position].id,
            thumbnail: false,
            borderRadius: BorderRadius.zero,
          ),
        ),
        if (media.length > 1)
          Positioned(
            bottom: HmSpace.xxl,
            right: HmSpace.xxl,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: HmSpace.lg, vertical: HmSpace.xs),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(HmRadius.pill),
              ),
              child: Text(
                '${index + 1} / ${media.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.colour,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? colour;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(HmSpace.md),
        child: Material(
          color: HmColors.bgPrimary.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(icon, color: colour ?? HmColors.textPrimary, size: 20),
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
      );
}

class _FactStrip extends StatelessWidget {
  const _FactStrip({required this.property, required this.detail});

  final PropertySummary property;
  final PropertyDetail detail;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String, String)>[
      if (property.bedrooms != null) (Icons.bed_outlined, '${property.bedrooms}', 'Bedrooms'),
      if (property.bathrooms != null) (Icons.shower_outlined, '${property.bathrooms}', 'Bathrooms'),
      if (property.sizeSqm != null) (Icons.square_foot, '${property.sizeSqm!.round()}', 'm²'),
      if (detail.parkingSpaces != null && detail.parkingSpaces! > 0)
        (Icons.local_parking_outlined, '${detail.parkingSpaces}', 'Parking'),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: HmSpace.xxl),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: HmColors.borderDefault)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (icon, value, label) in facts)
            Column(
              children: [
                Icon(icon, size: 20, color: HmColors.brandPrimary),
                const SizedBox(height: HmSpace.xs),
                Text(value, style: HmText.label),
                Text(label, style: HmText.caption),
              ],
            ),
        ],
      ),
    );
  }
}

class _Terms extends StatelessWidget {
  const _Terms({required this.detail});

  final PropertyDetail detail;

  @override
  Widget build(BuildContext context) {
    final rent = detail.summary.price ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Renting terms', style: HmText.heading),
        const SizedBox(height: HmSpace.md),
        if (detail.paymentFrequency != null)
          _Row(label: 'Rent paid', value: HmStatusChip.humanise(detail.paymentFrequency!)),
        if (detail.depositMonths != null && detail.depositMonths! > 0)
          _Row(
            label: 'Deposit',
            // Both the rule and the money, because "2 months" alone still
            // leaves the customer doing arithmetic before they can budget.
            value: '${detail.depositMonths!.toStringAsFixed(0)} months · '
                '${HmMoney.format(rent * detail.depositMonths!)}',
          ),
        if (detail.advanceRentMonths != null && detail.advanceRentMonths! > 0)
          _Row(
            label: 'Rent in advance',
            value: '${detail.advanceRentMonths!.toStringAsFixed(0)} months · '
                '${HmMoney.format(rent * detail.advanceRentMonths!)}',
          ),
        if (detail.minLeaseMonths != null)
          _Row(label: 'Minimum stay', value: '${detail.minLeaseMonths} months'),
        if (detail.noticePeriodDays != null)
          _Row(label: 'Notice period', value: '${detail.noticePeriodDays} days'),
        if (detail.availableFrom != null)
          _Row(
            label: 'Available from',
            value: '${detail.availableFrom!.day}/${detail.availableFrom!.month}/${detail.availableFrom!.year}',
          ),
        if (detail.terms != null && detail.terms!.isNotEmpty) ...[
          const SizedBox(height: HmSpace.md),
          Text(detail.terms!, style: HmText.caption),
        ],
      ],
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.detail});

  final PropertyDetail detail;

  @override
  Widget build(BuildContext context) {
    final name = detail.brokerName ?? detail.landlordName;
    if (name == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(HmSpace.xxl),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: HmColors.brandPrimarySoft,
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: HmColors.brandPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: HmSpace.xxl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: HmText.label),
                  Text(
                    detail.agencyName ?? (detail.brokerName != null ? 'Broker' : 'Landlord'),
                    style: HmText.caption,
                  ),
                ],
              ),
            ),
            // Contact details arrive with the enquiry, not before it — the
            // platform connects the parties rather than handing out numbers.
            const Icon(Icons.verified_outlined, color: HmColors.brandPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: HmRadius.card,
        child: SizedBox(
          height: 180,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 15,
              // A map inside a scrolling page that grabs the drag is a page
              // the customer cannot scroll past.
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(urlTemplate: Env.mapTileUrl, userAgentPackageName: Env.mapUserAgent),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    child: const Icon(Icons.place, color: HmColors.error, size: 36),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HmSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: HmText.caption)),
            const SizedBox(width: HmSpace.xxl),
            Expanded(
              child: Text(value, style: HmText.label, textAlign: TextAlign.right),
            ),
          ],
        ),
      );
}

/// The pinned actions. What they offer depends on where the customer already
/// is: asking twice about the same place is not a thing to invite.
class _Actions extends StatelessWidget {
  const _Actions({required this.detail});

  final PropertyDetail detail;

  @override
  Widget build(BuildContext context) {
    final propertyId = detail.summary.id;
    return Material(
      color: HmColors.bgPrimary,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(detail.hasOpenInquiry ? 'View enquiry' : 'Enquire'),
                  onPressed: () => detail.hasOpenInquiry
                      ? context.push(Routes.inquiry(detail.myInquiryId!))
                      : context.push(Routes.inquiryForm(propertyId)),
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push(Routes.scheduleViewing(propertyId)),
                  child: const Text('Book a viewing'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
