import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_choice.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../routing/app_router.dart';
import '../../shared/catalogue_repository.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../data/search_providers.dart';
import 'filter_sheet.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-002a. The search overlay.
///
/// The bar on the home screen is a button, not a field — tapping it opens this,
/// full screen, with the keyboard already up. That is the difference the
/// designs are after: searching is a mode you enter, with somewhere to put
/// suggestions, recent searches and popular areas, not a text box squeezed
/// between a greeting and a carousel.
///
/// Recent searches live on the device rather than the server: they are a
/// convenience for this phone, and shipping somebody's half-typed searches to
/// a backend is a privacy cost with nothing to show for it.
class SearchOverlay extends ConsumerStatefulWidget {
  const SearchOverlay({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  Timer? _debounce;
  String _query = '';
  List<String> _recent = const [];

  static const _recentKey = 'hm.search.recent';
  static const _maxRecent = 6;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
    _query = _controller.text;
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Recents are a convenience, never a precondition. Storage can be
  /// unavailable, blocked or holding something we did not write, and none of
  /// that is a reason a customer cannot search.
  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentKey);
      if (raw == null || !mounted) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        setState(() => _recent = decoded.map((value) => '$value').toList());
      }
    } catch (_) {
      // Nothing to show under "Recent searches", which is a fine state.
    }
  }

  Future<void> _remember(String term) async {
    final next = [term, ..._recent.where((value) => value != term)].take(_maxRecent).toList();
    if (mounted) setState(() => _recent = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentKey, jsonEncode(next));
    } catch (_) {
      // See _loadRecent.
    }
  }

  Future<void> _forgetRecent() async {
    setState(() => _recent = const []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (_) {
      // See _loadRecent.
    }
  }

  /// Typing should not fire a request per keystroke — on a slow connection
  /// that is a queue of answers arriving out of order.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => mounted ? setState(() => _query = value.trim()) : null,
    );
  }

  /// Committing a search: remember it, publish it to the shared filters, and
  /// hand back to the results screen.
  void _submit(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    // Publish and leave first, remember afterwards: writing to the recents
    // list must never stand between a customer and their results.
    ref.read(searchFiltersProvider.notifier).setQuery(trimmed);
    final navigator = Navigator.of(context);
    unawaited(_remember(trimmed));
    // Only close if there is something behind us. The overlay is normally
    // pushed over a tab, but it is a real route and can be arrived at
    // directly — and popping the last page off leaves nothing on screen.
    if (navigator.canPop()) navigator.pop(trimmed);
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterSheet(),
    );
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);

    return Scaffold(
      backgroundColor: HmColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _controller,
              focusNode: _focus,
              activeFilters: filters.activeCount,
              onChanged: _onChanged,
              onSubmitted: _submit,
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
              onBack: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) navigator.pop();
              },
              onFilters: _openFilters,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: HmSpace.section),
                children: _query.isEmpty ? _browsing() : _suggesting(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- nothing typed yet -----------------------------------------------------

  List<Widget> _browsing() => [
        if (_recent.isNotEmpty) ...[
          _GroupTitle(context.text.overlayRecent),
          for (final term in _recent)
            _Suggestion(
              icon: Icons.history,
              title: term,
              onTap: () => _submit(term),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: HmSpace.huge),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _forgetRecent,
                child: Text(context.text.overlayClearRecent),
              ),
            ),
          ),
          const _GroupDivider(),
        ],
        _GroupTitle(context.text.overlayPopular),
        _PopularAreas(onSelected: _submit),
        const _GroupDivider(),
        _GroupTitle(context.text.overlayFeatured),
        const _FeaturedRow(),
      ];

  // --- something typed -------------------------------------------------------

  List<Widget> _suggesting() => [
        _GroupTitle(context.text.overlayLocations),
        _LocationMatches(query: _query, onSelected: _submit),
        const _GroupDivider(),
        _GroupTitle(context.text.overlayProperties),
        _PropertyMatches(query: _query),
      ];
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.activeFilters,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBack,
    required this.onFilters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int activeFilters;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(HmSpace.xxl),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: context.text.overlayClose,
              onPressed: onBack,
            ),
            Expanded(
              child: TextField(
                key: const Key('search-field'),
                controller: controller,
                focusNode: focusNode,
                // The keyboard is up the moment the overlay opens: this screen
                // exists to be typed into.
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  hintText: context.text.overlayHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: context.text.searchClear,
                          onPressed: onClear,
                        ),
                ),
              ),
            ),
            const SizedBox(width: HmSpace.md),
            _FilterButton(count: activeFilters, onPressed: onFilters),
          ],
        ),
      );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: count > 0 ? HmColors.brandPrimarySoft : HmColors.surfaceInput,
            borderRadius: HmRadius.card,
            child: InkWell(
              onTap: onPressed,
              borderRadius: HmRadius.card,
              child: Padding(
                padding: const EdgeInsets.all(HmSpace.xl),
                child: Icon(
                  Icons.tune,
                  size: 22,
                  // The count is announced rather than only drawn, so the dot
                  // is not the only way to know a filter is on.
                  semanticLabel: count > 0 ? context.text.overlayFiltersActive(count) : context.text.filterTitle,
                  color: count > 0 ? HmColors.brandPrimary : HmColors.textSecondary,
                ),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: HmColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
}

/// Places matching what has been typed, from the same geocoder the map uses.
class _LocationMatches extends ConsumerWidget {
  const _LocationMatches({required this.query, required this.onSelected});

  final String query;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placeSearchProvider(query));

    return places.when(
      loading: () => const _InlineLoading(),
      error: (_, __) => const SizedBox.shrink(),
      data: (results) {
        if (results.isEmpty) {
          return _Empty(context.text.overlayNoPlaces);
        }
        return Column(
          children: [
            for (final place in results.take(4))
              _Suggestion(
                icon: Icons.place_outlined,
                title: place.displayName,
                onTap: () => onSelected(place.displayName.split(',').first.trim()),
              ),
          ],
        );
      },
    );
  }
}

/// Listings matching what has been typed, so the overlay can go straight to
/// the home rather than only to a results page.
class _PropertyMatches extends ConsumerWidget {
  const _PropertyMatches({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(PropertyFilters(query: query)));

    return results.when(
      loading: () => const _InlineLoading(),
      error: (_, __) => _Empty(context.text.overlayFailed),
      data: (page) {
        if (page.isEmpty) return _Empty(context.text.overlayNoHomes);
        return Column(
          children: [
            for (final property in page.items.take(5))
              _Suggestion(
                icon: Icons.home_work_outlined,
                title: property.title,
                subtitle: '${property.locationLabel} · ${property.priceLabel}',
                onTap: () => context.push(Routes.property(property.id)),
              ),
          ],
        );
      },
    );
  }
}

/// The areas people actually search for here.
///
/// A short, honest fallback: the platform has no popularity metric yet, and
/// inventing one out of listing counts would read as a ranking it is not.
class _PopularAreas extends ConsumerWidget {
  const _PopularAreas({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const _fallback = ['Masaki', 'Oyster Bay', 'Mikocheni', 'Msasani', 'Upanga'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = ref.watch(referenceDataProvider);
    // Real ward names where we have them, the known Dar neighbourhoods
    // otherwise — never an empty row.
    final areas = reference.valueOrNull?.wards.take(8).map((ward) => ward.name).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HmSpace.huge),
      child: Wrap(
        spacing: HmSpace.md,
        runSpacing: HmSpace.md,
        children: [
          for (final area in (areas == null || areas.isEmpty) ? _fallback : areas)
            HmChoicePill(
              label: area,
              dense: true,
              selected: false,
              onTap: () => onSelected(area),
            ),
        ],
      ),
    );
  }
}

class _FeaturedRow extends ConsumerWidget {
  const _FeaturedRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredPropertiesProvider);

    return featured.when(
      loading: () => const _InlineLoading(),
      error: (_, __) => const SizedBox.shrink(),
      data: (page) => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: HmSpace.huge),
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(width: HmSpace.xl),
          itemBuilder: (_, index) => _FeaturedCard(property: page.items[index]),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.property});

  final PropertySummary property;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 230,
        child: InkWell(
          onTap: () => context.push(Routes.property(property.id)),
          borderRadius: HmRadius.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PropertyImage(mediaId: property.coverMediaId, height: 130),
              const SizedBox(height: HmSpace.md),
              Text(
                HmMoney.format(property.price, currency: property.currency),
                style: HmText.heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                property.title,
                style: HmText.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(HmSpace.huge, 0, HmSpace.huge, HmSpace.md),
        child: Material(
          color: HmColors.bgSecondary,
          borderRadius: HmRadius.card,
          child: InkWell(
            onTap: onTap,
            borderRadius: HmRadius.card,
            child: Padding(
              padding: const EdgeInsets.all(HmSpace.xl),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: HmColors.textSecondary),
                  const SizedBox(width: HmSpace.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: HmText.body.copyWith(color: HmColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: HmText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(HmSpace.huge, HmSpace.xl, HmSpace.huge, HmSpace.xl),
        child: Text(
          text,
          style: HmText.label.copyWith(
            color: HmColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(HmSpace.huge, HmSpace.xl, HmSpace.huge, 0),
        child: Divider(height: 1),
      );
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: HmSpace.huge),
        child: Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.huge, vertical: HmSpace.md),
        child: Text(message, style: HmText.caption),
      );
}
