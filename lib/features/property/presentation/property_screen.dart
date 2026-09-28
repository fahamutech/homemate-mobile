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
import '../../shared/journey_providers.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../../shared/service_fee_card.dart';

/// CUS-005. One listing, in full.
///
/// The order follows the design, and the design follows the order the
/// questions actually arrive in: what does it look like, what is it, who is
/// letting it, what is in it, where is it, what will it really cost, and how
/// would I pay. The next step on the one road to renting it — enquire, then
/// pay once accepted — is pinned to the bottom, because this is a long page
/// and an action found only after scrolling past the house rules is an action
/// nobody takes.
class PropertyScreen extends ConsumerWidget {
  const PropertyScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(propertyDetailProvider(propertyId));

    return Scaffold(
      backgroundColor: HmColors.bgSecondary,
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
          backgroundColor: HmColors.bgPrimary,
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
              // Tapping a photo is the universal "show me this properly", and
              // the designs have a whole screen for it.
              onOpen: () => context.push(
                Routes.gallery(property.id, index: _photo),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          sliver: SliverList.list(
            children: [
              if ((property.propertyTypeName ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: HmSpace.md),
                  child: Text(
                    property.propertyTypeName!.toUpperCase(),
                    style: HmText.caption.copyWith(
                      color: HmColors.brandPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              Text(property.title, style: HmText.title),
              const SizedBox(height: HmSpace.md),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: HmColors.textSecondary),
                  const SizedBox(width: HmSpace.xs),
                  Expanded(
                    child: Text(
                      property.addressLine ?? property.locationLabel,
                      style: HmText.caption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HmSpace.xxl),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text(property.priceLabel, style: HmText.price)),
                  if (detail.monthlyTotal > (property.price ?? 0))
                    Text(
                      '${HmMoney.format(detail.monthlyTotal, currency: property.currency)} all in',
                      style: HmText.caption,
                    ),
                ],
              ),

              const SizedBox(height: HmSpace.huge),
              _FactStrip(property: property, detail: detail),

              const SizedBox(height: HmSpace.huge),
              _About(description: detail.description),

              const SizedBox(height: HmSpace.huge),
              _ContactCard(detail: detail),

              if (detail.amenities.isNotEmpty) ...[
                const SizedBox(height: HmSpace.huge),
                _Section(
                  title: 'Amenities',
                  child: Wrap(
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
                ),
              ],

              if (property.hasLocation) ...[
                const SizedBox(height: HmSpace.huge),
                _Section(
                  title: 'Location',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place, size: 15, color: HmColors.brandPrimary),
                          const SizedBox(width: HmSpace.xs),
                          Expanded(
                            child: Text(
                              property.addressLine ?? property.locationLabel,
                              style: HmText.caption,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: HmSpace.xl),
                      _MiniMap(latitude: property.latitude!, longitude: property.longitude!),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: HmSpace.huge),
              _PriceBreakdown(detail: detail),

              if (detail.paymentMethods.isNotEmpty) ...[
                const SizedBox(height: HmSpace.huge),
                _PaymentOptions(methods: detail.paymentMethods),
              ],

              const SizedBox(height: HmSpace.huge),
              _Terms(detail: detail),

              if ((detail.houseRules ?? '').isNotEmpty) ...[
                const SizedBox(height: HmSpace.huge),
                _Section(
                  title: 'House rules',
                  child: Text(detail.houseRules!, style: HmText.body),
                ),
              ],

              const SizedBox(height: HmSpace.huge),
              _HowItWorks(detail: detail),

              // Clears the pinned action bar so the last line is readable.
              const SizedBox(height: 96),
            ],
          ),
        ),
      ],
    );
  }
}

/// A white card with a heading — the shape every block on this page shares.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HmSpace.xxl),
        decoration: BoxDecoration(
          color: HmColors.bgPrimary,
          borderRadius: HmRadius.card,
          border: Border.all(color: HmColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: HmText.heading),
            const SizedBox(height: HmSpace.xl),
            child,
          ],
        ),
      );
}

/// "About this property", with a Read more that only appears when there is
/// more to read.
class _About extends StatefulWidget {
  const _About({required this.description});

  final String? description;

  @override
  State<_About> createState() => _AboutState();
}

class _AboutState extends State<_About> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = (widget.description ?? '').trim();

    return _Section(
      title: 'About this property',
      child: description.isEmpty
          // The heading stays even with nothing under it: a listing with no
          // description should read as "the landlord did not write one", not
          // as a section the app forgot to build.
          ? Text(
              'The landlord has not written a description yet. Ask them '
              'anything you need to know when you enquire.',
              style: HmText.body.copyWith(color: HmColors.textSecondary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.topLeft,
                  child: Text(
                    description,
                    style: HmText.body,
                    maxLines: _expanded ? null : 4,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                if (description.length > 180)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(_expanded ? 'Show less' : 'Read more'),
                  ),
              ],
            ),
    );
  }
}

/// Who is letting the place.
///
/// Shown even when we have no name, because its absence is information: a
/// listing with nobody attached is one a customer should treat differently,
/// and silently dropping the card told them nothing at all.
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.detail});

  final PropertyDetail detail;

  @override
  Widget build(BuildContext context) {
    final name = detail.contactName;

    return Container(
      padding: const EdgeInsets.all(HmSpace.xxl),
      decoration: BoxDecoration(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        border: Border.all(color: HmColors.borderDefault),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: HmColors.brandPrimarySoft,
            child: name == null
                ? const Icon(Icons.apartment, color: HmColors.brandPrimary, size: 22)
                : Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: HmColors.brandPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: HmSpace.xxl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Listed by HomeMate',
                  style: HmText.label.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: HmSpace.xxs),
                Row(
                  children: [
                    if (detail.contactVerified) ...[
                      const Icon(Icons.verified, size: 14, color: HmColors.brandPrimary),
                      const SizedBox(width: HmSpace.xs),
                    ],
                    Flexible(
                      child: Text(
                        detail.contactVerified
                            ? 'Verified ${detail.contactSubtitle}'
                            : detail.contactSubtitle,
                        style: HmText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (detail.contactActiveListings > 0) ...[
                  const SizedBox(height: HmSpace.xxs),
                  Text(
                    detail.contactActiveListings == 1
                        ? '1 active listing'
                        : '${detail.contactActiveListings} active listings',
                    style: HmText.caption,
                  ),
                ],
              ],
            ),
          ),
          // Contact details arrive with the enquiry, not before it — the
          // platform connects the parties rather than handing out numbers.
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.inquiryForm(detail.summary.id)),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Chat'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: HmSpace.xl),
              minimumSize: const Size(0, 38),
            ),
          ),
        ],
      ),
    );
  }
}

/// What it costs, line by line.
///
/// The rent alone is the number a customer remembers and the wrong one to plan
/// with: the deposit and the rent in advance are usually several times it, and
/// finding that out at signing is how a booking falls through. So both totals
/// are spelled out — what recurs monthly, and what has to be found up front.
class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({required this.detail});

  final PropertyDetail detail;

  @override
  Widget build(BuildContext context) {
    final currency = detail.summary.currency;
    String money(double value) => HmMoney.format(value, currency: currency);

    return _Section(
      title: 'Price Breakdown',
      child: Column(
        children: [
          _Row(label: 'Monthly rent', value: money(detail.summary.price ?? 0)),
          for (final charge in detail.monthlyCharges)
            _Row(label: charge.name, value: money(charge.amount)),
          if (detail.monthlyTotal > (detail.summary.price ?? 0)) ...[
            const Divider(height: HmSpace.huge),
            _Row(label: 'Monthly total', value: money(detail.monthlyTotal), emphasised: true),
          ],

          const Divider(height: HmSpace.huge),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Before you move in', style: HmText.label),
          ),
          const SizedBox(height: HmSpace.md),

          if (detail.depositAmount case final deposit?)
            _Row(
              label: 'Security deposit'
                  '${detail.depositMonths == null ? '' : ' · ${_months(detail.depositMonths!)}'}',
              value: money(deposit),
            ),
          if (detail.advanceRentAmount case final advance?)
            _Row(
              label: 'Rent in advance'
                  '${detail.advanceRentMonths == null ? '' : ' · ${_months(detail.advanceRentMonths!)}'}',
              value: money(advance),
            )
          else
            _Row(label: 'First month’s rent', value: money(detail.summary.price ?? 0)),
          for (final charge in detail.oneOffCharges)
            _Row(
              label: '${charge.name}${charge.isRefundable ? ' (refundable)' : ''}',
              value: money(charge.amount),
            ),
          if (detail.serviceFee case final fee? when fee.isCharged)
            _Row(
              label: 'HomeMate fee · ${fee.percentageLabel} of a month',
              value: money(fee.amount),
              highlighted: true,
            ),

          const Divider(height: HmSpace.huge),
          _Row(label: 'Total to move in', value: money(detail.moveInTotal), emphasised: true),
          const SizedBox(height: HmSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'An estimate from what the landlord has listed. The exact figures '
              'are shown at checkout, once the landlord accepts your enquiry.',
              style: HmText.caption,
            ),
          ),
        ],
      ),
    );
  }

  static String _months(double value) {
    final whole = value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
    return '$whole month${value == 1 ? '' : 's'}';
  }
}

/// How the rent may be paid — the methods the landlord has actually enabled,
/// not a generic list of everything the platform supports.
class _PaymentOptions extends StatelessWidget {
  const _PaymentOptions({required this.methods});

  final List<NamedItem> methods;

  @override
  Widget build(BuildContext context) => _Section(
        title: 'Payment Options',
        child: Wrap(
          spacing: HmSpace.md,
          runSpacing: HmSpace.md,
          children: [
            for (final method in methods)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HmSpace.xl,
                  vertical: HmSpace.xl,
                ),
                decoration: BoxDecoration(
                  color: HmColors.bgSecondary,
                  borderRadius: HmRadius.card,
                  border: Border.all(color: HmColors.borderDefault),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(method.code), size: 17, color: HmColors.brandPrimary),
                    const SizedBox(width: HmSpace.md),
                    Text(method.name, style: HmText.label),
                  ],
                ),
              ),
          ],
        ),
      );

  /// A best guess from the method's code, falling back to a neutral wallet —
  /// a new payment method added in the backoffice must not render as a broken
  /// icon here.
  static IconData _iconFor(String? code) {
    final value = (code ?? '').toLowerCase();
    if (value.contains('bank')) return Icons.account_balance_outlined;
    if (value.contains('card')) return Icons.credit_card;
    if (value.contains('cash')) return Icons.payments_outlined;
    if (value.contains('pesa') || value.contains('mobile') || value.contains('momo')) {
      return Icons.smartphone_outlined;
    }
    return Icons.account_balance_wallet_outlined;
  }
}

/// Where the customer is on the one road to this home — enquire, be
/// accepted, pay, be verified — and the fee that road costs, highlighted with
/// what it saves against the usual month's agent fee.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.detail});

  final PropertyDetail detail;

  @override
  Widget build(BuildContext context) {
    final step = detail.isAccepted ? 2 : (detail.hasOpenInquiry ? 1 : 0);
    const steps = ['Enquire', 'Landlord accepts', 'Pay', 'Payment verified'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.serviceFee case final fee? when fee.isCharged) ...[
          ServiceFeeCard(fee: fee, currency: detail.summary.currency),
          const SizedBox(height: HmSpace.huge),
        ],
        _Section(
          title: 'How to rent it',
          child: Column(
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: HmSpace.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < step ? HmColors.brandPrimary : HmColors.bgPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i <= step ? HmColors.brandPrimary : HmColors.borderStrong,
                            width: 2,
                          ),
                        ),
                        child: i < step
                            ? const Icon(Icons.check, size: 14, color: HmColors.textOnBrand)
                            : Text(
                                '${i + 1}',
                                style: HmText.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: i == step ? HmColors.brandPrimary : HmColors.textSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: HmSpace.xl),
                      Expanded(
                        child: Text(
                          steps[i],
                          style: i == step
                              ? HmText.label.copyWith(color: HmColors.brandPrimary)
                              : HmText.body,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.media,
    required this.index,
    required this.onChanged,
    required this.onOpen,
  });

  final List<PropertyMedia> media;
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onOpen;

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
          itemBuilder: (_, position) => GestureDetector(
            onTap: onOpen,
            child: PropertyImage(
              mediaId: media[position].id,
              thumbnail: false,
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        Positioned(
          bottom: HmSpace.xxl,
          left: HmSpace.xxl,
          child: _Counter(index: index, total: media.length, onTap: onOpen),
        ),
        if (media.length > 1)
          Positioned(
            bottom: HmSpace.xxl + 4,
            right: 0,
            left: 0,
            child: _Dots(index: index, total: media.length),
          ),
      ],
    );
  }
}

/// "1 / 5" — also the affordance that says the photos open, for anyone who
/// does not think to tap the picture itself.
class _Counter extends StatelessWidget {
  const _Counter({required this.index, required this.total, required this.onTap});

  final int index;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HmRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HmSpace.xl,
              vertical: HmSpace.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                const SizedBox(width: HmSpace.md),
                Text(
                  '${index + 1} / $total',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  semanticsLabel: 'Photo ${index + 1} of $total. Open all photos',
                ),
              ],
            ),
          ),
        ),
      );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Past a handful the dots stop being countable and start being
          // clutter; the counter already says where you are.
          if (total <= 6)
            for (var position = 0; position < total; position++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: position == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: position == index ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(HmRadius.pill),
                ),
              ),
        ],
      );
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
      if (property.bedrooms != null) (Icons.bed_outlined, '${property.bedrooms}', 'Beds'),
      if (property.bathrooms != null) (Icons.shower_outlined, '${property.bathrooms}', 'Baths'),
      if (property.sizeSqm != null) (Icons.square_foot, '${property.sizeSqm!.round()}', 'sqm'),
      if ((detail.parkingSpaces ?? 0) > 0)
        (Icons.local_parking_outlined, '${detail.parkingSpaces}', 'Parking'),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: HmSpace.xxl),
      decoration: BoxDecoration(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        border: Border.all(color: HmColors.borderDefault),
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
    final rows = <Widget>[
      if (detail.paymentFrequency != null)
        _Row(label: 'Rent paid', value: HmStatusChip.humanise(detail.paymentFrequency!)),
      if (detail.minLeaseMonths != null)
        _Row(label: 'Minimum stay', value: '${detail.minLeaseMonths} months'),
      if (detail.noticePeriodDays != null)
        _Row(label: 'Notice period', value: '${detail.noticePeriodDays} days'),
      if (detail.petsAllowed != null)
        _Row(label: 'Pets', value: detail.petsAllowed! ? 'Allowed' : 'Not allowed'),
      if (detail.availableFrom != null)
        _Row(
          label: 'Available from',
          value: '${detail.availableFrom!.day}/${detail.availableFrom!.month}'
              '/${detail.availableFrom!.year}',
        ),
    ];
    if (rows.isEmpty && (detail.terms ?? '').isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Renting terms',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows,
          if ((detail.terms ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.md),
            Text(detail.terms!, style: HmText.caption),
          ],
        ],
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
  const _Row({
    required this.label,
    required this.value,
    this.emphasised = false,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  /// The HomeMate fee line: tinted, so the platform's own charge is never a
  /// line the customer has to go looking for.
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        margin: highlighted ? const EdgeInsets.symmetric(vertical: HmSpace.xs) : null,
        padding: highlighted
            ? const EdgeInsets.symmetric(vertical: HmSpace.sm, horizontal: HmSpace.md)
            : const EdgeInsets.symmetric(vertical: HmSpace.sm),
        decoration: highlighted
            ? BoxDecoration(color: HmColors.brandPrimarySoft, borderRadius: BorderRadius.circular(HmRadius.sm))
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: emphasised ? HmText.label : HmText.caption,
              ),
            ),
            const SizedBox(width: HmSpace.xxl),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: emphasised
                    ? HmText.label.copyWith(fontSize: 15, color: HmColors.brandPrimary)
                    : HmText.label,
              ),
            ),
          ],
        ),
      );
}

/// The pinned actions. There is one road to this home: enquire, and once the
/// landlord accepts, pay. So the bar offers exactly the next step — "Enquire"
/// before anything has been asked, "View enquiry" while the landlord decides,
/// and "Pay to secure it" once they have said yes. Whether the customer may
/// pay is the server's answer ([checkoutEligibilityProvider]), never the
/// app's guess.
class _Actions extends ConsumerWidget {
  const _Actions({required this.detail});

  final PropertyDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyId = detail.summary.id;
    final eligibility = ref.watch(checkoutEligibilityProvider(propertyId)).valueOrNull;
    final canPay = eligibility?.canPay ?? false;
    final blocked = eligibility?.isBlockedByHold ?? false;

    return Material(
      color: HmColors.bgPrimary,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canPay) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // Disabled rather than hidden while somebody else is
                    // mid-payment: the customer should see that the option
                    // exists and is momentarily taken, not watch a button
                    // appear and vanish between refreshes.
                    onPressed:
                        blocked ? null : () => context.push(Routes.checkout(propertyId)),
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: Text(
                      blocked
                          ? 'Someone is paying for this'
                          : eligibility!.hasStarted
                              ? 'Continue payment'
                              : 'Pay to secure it',
                    ),
                  ),
                ),
                const SizedBox(height: HmSpace.xl),
              ],
              SizedBox(
                width: double.infinity,
                child: detail.myInquiryId != null
                    ? OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('View enquiry'),
                        onPressed: () => context.push(Routes.inquiry(detail.myInquiryId!)),
                      )
                    : FilledButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Enquire'),
                        onPressed: () => context.push(Routes.inquiryForm(propertyId)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
