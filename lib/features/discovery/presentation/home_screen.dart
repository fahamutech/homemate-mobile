import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/i18n/language_picker.dart';
import '../../../core/location/location_providers.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_choice.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../routing/app_router.dart';
import '../../shared/catalogue_repository.dart';
import '../../shared/customer_avatar.dart';
import '../../shared/models.dart';
import '../../shared/property_card.dart';
import '../../shared/property_image.dart';
import '../data/search_providers.dart';
import 'near_me_prompt.dart';

/// CUS-001. What is waiting for you, then what is available, then what is
/// close by.
///
/// The order is the design's and it is the right one: the greeting and the
/// category chips are at the top because they are how you *start*, "My
/// activity" comes next because a payment due beats any listing, "Featured"
/// scrolls sideways so it costs one screen rather than five, and "Near you" is
/// a vertical list because that is the part people actually read.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// The chip row's selection. Local rather than in the shared filters: it
  /// narrows what the home screen shows, and should not silently rewrite the
  /// search the customer left running on the Search tab.
  String? _typeId;

  /// The chips narrow the section; the position is what makes it *near*.
  ///
  /// Reading the location straight into the filters is what turns "Near You"
  /// from a heading into a fact: the server orders by distance the moment it
  /// is given a point, so this one line is the whole feature. Without a
  /// position the filters carry none, and the section falls back to the
  /// newest listings — which is honest, and is why the card above it asks.
  PropertyFilters _filtersFor(NearMeState nearMe) => PropertyFilters(
        propertyTypeId: _typeId,
        latitude: nearMe.latitude,
        longitude: nearMe.longitude,
        radiusMetres: nearMe.canSearchNearby ? PropertyFilters.defaultRadiusMetres : null,
      );

  Future<void> _openSearch() async {
    await context.push<String>(Routes.searchOverlay);
    // The overlay publishes the query into the shared filters; moving to the
    // Search tab is what shows the results.
    if (mounted && ref.read(searchFiltersProvider).query != null) {
      if (context.mounted) context.go(Routes.search);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(currentCustomerProvider);
    final summary = ref.watch(activitySummaryProvider);
    final reference = ref.watch(referenceDataProvider);
    final featured = ref.watch(featuredPropertiesProvider);
    final nearMe = ref.watch(nearMeProvider);
    final filters = _filtersFor(nearMe);
    final nearby = ref.watch(nearbyPropertiesProvider(filters));

    return Scaffold(
      backgroundColor: HmColors.bgSecondary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activitySummaryProvider);
            ref.invalidate(featuredPropertiesProvider);
            ref.invalidate(nearbyPropertiesProvider(filters));
            // A pull-to-refresh is also the moment to notice that the customer
            // has been to Settings and come back.
            ref.read(nearMeProvider.notifier).recheck();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: HmSpace.section),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HmSpace.xxl,
                  HmSpace.md,
                  HmSpace.xxl,
                  HmSpace.xxl,
                ),
                child: _Greeting(
                  name: customer?.fullName?.split(' ').first,
                  unread: summary.valueOrNull?.unreadNotifications ?? 0,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
                child: _SearchPrompt(onTap: _openSearch),
              ),
              const SizedBox(height: HmSpace.xxl),

              // The chip row sits above everything it filters, and scrolls
              // rather than wrapping: a second row of chips pushes the first
              // listing off the screen on a small phone.
              _CategoryChips(
                types: reference.valueOrNull?.propertyTypes ?? const [],
                selected: _typeId,
                onSelected: (id) => setState(() => _typeId = id),
              ),

              // Only shown when there is genuinely something to attend to —
              // a row of zeroes is noise on the screen people open most.
              summary.maybeWhen(
                data: (data) => _MyActivity(summary: data),
                orElse: () => const SizedBox.shrink(),
              ),

              _SectionHeader(
                title: context.text.featured,
                onSeeAll: () => context.go(Routes.search),
              ),
              HmAsync(
                value: featured,
                onRetry: () => ref.invalidate(featuredPropertiesProvider),
                emptyWhen: (page) => page.isEmpty,
                loading: const _RowLoading(),
                empty: HmEmpty(
                  title: context.text.homeEmptyTitle,
                  message: context.text.homeEmptyMessage,
                  icon: Icons.home_work_outlined,
                ),
                data: (page) => SizedBox(
                  height: 320,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: HmSpace.xl),
                    itemBuilder: (_, index) => SizedBox(
                      width: 280,
                      child: PropertyCard(
                        property: page.items[index],
                        fillHeight: true,
                        onSavedChanged: (_) => ref.invalidate(featuredPropertiesProvider),
                      ),
                    ),
                  ),
                ),
              ),

              _SectionHeader(
                title: context.text.nearYou,
                onSeeAll: () => context.go(Routes.search),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The explain-and-ask card, or — once we have a position —
                    // the line saying where "near" is measured from.
                    NearMePrompt(onChooseArea: () => showAreaPicker(context, ref)),
                    NearMeSource(onChooseArea: () => showAreaPicker(context, ref)),
                  ],
                ),
              ),
              if (nearMe.needsPrompt) const SizedBox(height: HmSpace.xxl),
              HmAsync(
                value: nearby,
                onRetry: () => ref.invalidate(nearbyPropertiesProvider(filters)),
                emptyWhen: (page) => page.isEmpty,
                loading: const _RowLoading(),
                empty: HmEmpty(
                  title: _typeId == null
                      ? context.text.nearbyEmptyTitle
                      : context.text.nearbyEmptyTypeTitle,
                  message: nearMe.canSearchNearby
                      ? context.text.nearbyEmptyRadius
                      : _typeId == null
                          ? context.text.nearbyEmptyMessage
                          : context.text.nearbyEmptyOtherType,
                  icon: Icons.near_me_outlined,
                ),
                data: (page) => Column(
                  children: [
                    for (final property in page.items)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          HmSpace.xxl,
                          0,
                          HmSpace.xxl,
                          HmSpace.xl,
                        ),
                        child: _NearbyCard(
                          property: property,
                          onSavedChanged: (_) =>
                              ref.invalidate(nearbyPropertiesProvider(filters)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.unread});

  final String? name;
  final int unread;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.text.greeting(name),
                  style: HmText.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: HmSpace.xxs),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: HmColors.brandPrimary),
                    const SizedBox(width: HmSpace.xs),
                    Text(context.text.country, style: HmText.caption),
                  ],
                ),
              ],
            ),
          ),
          const LanguageButton(),
          _NotificationBell(unread: unread),
          const SizedBox(width: HmSpace.md),
          InkWell(
            onTap: () => context.go(Routes.profile),
            customBorder: const CircleBorder(),
            child: const CustomerAvatar(radius: 19, fontSize: 14),
          ),
        ],
      );
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () => context.go('${Routes.home}/notifications'),
        tooltip: unread > 0
            ? context.text.unreadNotifications(unread)
            : context.text.notifications,
        icon: unread > 0
            ? Badge(
                backgroundColor: HmColors.error,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              )
            : const Icon(Icons.notifications_outlined),
      );
}

/// A button dressed as a search field.
///
/// It is deliberately not a `TextField`: typing here would mean a keyboard
/// over a scrolling home screen with nowhere to put suggestions. Tapping it
/// opens the full-screen overlay, which is where searching actually happens.
class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: context.text.homeSearchSemantics,
        child: InkWell(
          onTap: onTap,
          borderRadius: HmRadius.card,
          child: Container(
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: BoxDecoration(
              color: HmColors.bgPrimary,
              borderRadius: HmRadius.card,
              border: Border.all(color: HmColors.borderDefault),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: HmColors.textSecondary),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: Text(context.text.homeSearchPrompt, style: HmText.body),
                ),
                Container(
                  padding: const EdgeInsets.all(HmSpace.md),
                  decoration: BoxDecoration(
                    color: HmColors.brandPrimarySoft,
                    borderRadius: BorderRadius.circular(HmRadius.sm),
                  ),
                  child: const Icon(Icons.tune, size: 18, color: HmColors.brandPrimary),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<ReferenceItem> types;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    // Nothing to choose between until the dictionaries arrive; an "All" chip
    // on its own is a control that does nothing.
    if (types.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: HmSpace.xxl),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
          itemCount: types.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: HmSpace.md),
          itemBuilder: (_, index) {
            if (index == 0) {
              return HmChoicePill(
                label: 'All',
                dense: true,
                selected: selected == null,
                onTap: () => onSelected(null),
              );
            }
            final type = types[index - 1];
            return HmChoicePill(
              label: type.name,
              dense: true,
              selected: selected == type.id,
              onTap: () => onSelected(selected == type.id ? null : type.id),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xl, HmSpace.md, HmSpace.md),
        child: Row(
          children: [
            Expanded(child: Text(title, style: HmText.title.copyWith(fontSize: 19))),
            TextButton(onPressed: onSeeAll, child: Text(context.text.seeAll)),
          ],
        ),
      );
}

/// The wide, short card the "Near you" list uses — image left, facts right.
class _NearbyCard extends ConsumerStatefulWidget {
  const _NearbyCard({required this.property, required this.onSavedChanged});

  final PropertySummary property;
  final ValueChanged<bool> onSavedChanged;

  @override
  ConsumerState<_NearbyCard> createState() => _NearbyCardState();
}

class _NearbyCardState extends ConsumerState<_NearbyCard> {
  late bool _saved = widget.property.isSaved;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final next = !_saved;
    setState(() {
      _saved = next;
      _busy = true;
    });
    try {
      final repository = ref.read(catalogueRepositoryProvider);
      next
          ? await repository.save(widget.property.id)
          : await repository.unsave(widget.property.id);
      ref.invalidate(activitySummaryProvider);
      ref.invalidate(savedPropertiesProvider);
      widget.onSavedChanged(next);
    } catch (_) {
      if (mounted) setState(() => _saved = !next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;

    return Material(
      color: HmColors.bgPrimary,
      borderRadius: HmRadius.card,
      child: InkWell(
        onTap: () => context.push(Routes.property(property.id)),
        borderRadius: HmRadius.card,
        child: Container(
          padding: const EdgeInsets.all(HmSpace.xl),
          decoration: BoxDecoration(
            borderRadius: HmRadius.card,
            border: Border.all(color: HmColors.borderDefault),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                height: 88,
                child: PropertyImage(mediaId: property.coverMediaId, height: 88, width: 96),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: HmText.label.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: HmSpace.xxs),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 13, color: HmColors.brandPrimary),
                        const SizedBox(width: HmSpace.xs),
                        Expanded(
                          child: Text(
                            property.locationLabel,
                            style: HmText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HmSpace.md),
                    Row(
                      children: [
                        Flexible(child: Text(_facts(property), style: HmText.caption)),
                        if (property.distanceMetres != null) ...[
                          const SizedBox(width: HmSpace.md),
                          DistanceLabel(metres: property.distanceMetres),
                        ],
                      ],
                    ),
                    const SizedBox(height: HmSpace.md),
                    Text(
                      HmMoney.perMonth(property.price, currency: property.currency)
                          .replaceAll('/month', '/mo'),
                      style: HmText.price.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggle,
                tooltip: _saved ? 'Remove from saved' : 'Save this property',
                icon: Icon(
                  _saved ? Icons.favorite : Icons.favorite_outline,
                  size: 20,
                  color: _saved ? HmColors.error : HmColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _facts(PropertySummary property) => [
        if (property.bedrooms != null) '${property.bedrooms} Bed',
        if (property.bathrooms != null) '${property.bathrooms} Bath',
        if (property.sizeSqm != null) '${property.sizeSqm!.round()} sqm',
      ].join(' • ');
}

/// The short list of things that need the customer, with the money first.
class _MyActivity extends StatelessWidget {
  const _MyActivity({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (summary.amountOutstanding > 0)
        _ActivityTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'To pay',
          value: HmMoney.format(summary.amountOutstanding),
          accent: HmColors.warning,
          onTap: () => context.go(Routes.bookings),
        ),
      if (summary.paymentsAwaitingVerification > 0)
        _ActivityTile(
          icon: Icons.hourglass_top_outlined,
          label: 'Being checked',
          value: '${summary.paymentsAwaitingVerification}',
          accent: HmColors.info,
          onTap: () => context.go(Routes.bookings),
        ),
      if (summary.upcomingViewings > 0)
        _ActivityTile(
          icon: Icons.event_available_outlined,
          label: 'Viewings',
          value: '${summary.upcomingViewings}',
          accent: HmColors.brandPrimary,
          onTap: () => context.go(Routes.viewings),
        ),
      if (summary.openInquiries > 0)
        _ActivityTile(
          icon: Icons.question_answer_outlined,
          label: 'Enquiries',
          value: '${summary.openInquiries}',
          accent: HmColors.brandPrimary,
          onTap: () => context.go(Routes.inquiries),
        ),
    ];

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(HmSpace.xxl, 0, HmSpace.md, HmSpace.md),
          child: Row(
            children: [
              Expanded(child: Text('My Activity', style: HmText.title.copyWith(fontSize: 19))),
              TextButton(
                onPressed: () => context.go(Routes.bookings),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
            itemCount: tiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: HmSpace.xl),
            itemBuilder: (_, index) => tiles[index],
          ),
        ),
        const SizedBox(height: HmSpace.md),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: HmRadius.card,
        child: Container(
          width: 170,
          // The accent is a strip drawn inside a clipped box, not a coloured
          // top border: `BoxDecoration` asserts that a border with a
          // borderRadius has uniform colours, so the obvious spelling of this
          // throws at paint time and leaves the tile blank.
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: HmColors.bgPrimary,
            borderRadius: HmRadius.card,
            border: Border.all(color: HmColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 3, color: accent),
              Padding(
                padding: const EdgeInsets.all(HmSpace.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 20),
                    const SizedBox(height: HmSpace.md),
                    Text(
                      label,
                      style: HmText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: HmSpace.xxs),
                    Text(
                      value,
                      style: HmText.heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _RowLoading extends StatelessWidget {
  const _RowLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: HmSpace.section),
        child: HmLoading(),
      );
}
