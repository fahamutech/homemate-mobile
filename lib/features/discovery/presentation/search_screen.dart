import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../routing/app_router.dart';
import '../../shared/property_card.dart';
import '../data/search_providers.dart';
import 'filter_sheet.dart';
import 'results_map.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-002 / CUS-003. The same search, shown as a list or on a map.
///
/// List and map are one screen rather than two routes because they are one
/// question — "what is available near here" — and splitting them would mean
/// keeping two copies of the filters in step.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _mapView = false;

  /// The bar here is a button too, for the same reason it is one on the home
  /// screen: editing a query belongs in the overlay, where there is room for
  /// suggestions, recent searches and areas. Two different search experiences
  /// on two tabs is how they drift.
  Future<void> _openSearch() async {
    final current = ref.read(searchFiltersProvider).query ?? '';
    await context.push<String>(
      current.isEmpty
          ? Routes.searchOverlay
          : '${Routes.searchOverlay}?q=${Uri.encodeComponent(current)}',
    );
  }

  Future<void> _openFilters() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterSheet(),
    );
    if (applied == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final results = ref.watch(searchResultsProvider(filters));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(HmSpace.xxl),
              child: Row(
                children: [
                  Expanded(
                    child: _QueryBar(
                      query: filters.query,
                      onTap: _openSearch,
                      onClear: () => ref.read(searchFiltersProvider.notifier).setQuery(null),
                    ),
                  ),
                  const SizedBox(width: HmSpace.xl),
                  _FilterButton(count: filters.activeCount, onPressed: _openFilters),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      results.maybeWhen(
                        data: (page) => context.text.searchHomes(page.total),
                        orElse: () => context.text.searchSearching,
                      ),
                      style: HmText.caption,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, icon: Icon(Icons.view_list_outlined), label: Text(context.text.searchList)),
                      ButtonSegment(value: true, icon: Icon(Icons.map_outlined), label: Text(context.text.searchMap)),
                    ],
                    selected: {_mapView},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) => setState(() => _mapView = values.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HmSpace.xl),

            Expanded(
              child: HmAsync(
                value: results,
                onRetry: () => ref.invalidate(searchResultsProvider(filters)),
                emptyWhen: (page) => page.isEmpty,
                empty: HmEmpty(
                  title: context.text.searchNoMatch,
                  message: filters.activeCount > 0
                      ? context.text.searchWiden
                      : context.text.searchTryDifferent,
                  icon: Icons.search_off_outlined,
                  action: filters.activeCount > 0
                      ? OutlinedButton(
                          onPressed: () => ref.read(searchFiltersProvider.notifier).clear(),
                          child: Text(context.text.searchClearFilters),
                        )
                      : null,
                ),
                data: (page) => _mapView
                    ? ResultsMap(properties: page.items)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          HmSpace.xxl,
                          0,
                          HmSpace.xxl,
                          HmSpace.section,
                        ),
                        itemCount: page.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: HmSpace.xxl),
                        itemBuilder: (_, index) => PropertyCard(
                          property: page.items[index],
                          onSavedChanged: (_) => ref.invalidate(searchResultsProvider(filters)),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The search bar as a button: it shows the current query, opens the overlay
/// on tap, and clears in place.
class _QueryBar extends StatelessWidget {
  const _QueryBar({required this.query, required this.onTap, required this.onClear});

  final String? query;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = (query ?? '').trim();

    return Semantics(
      button: true,
      label: text.isEmpty ? context.text.homeSearchSemantics : context.text.searchLabelWith(text),
      child: InkWell(
        onTap: onTap,
        borderRadius: HmRadius.card,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: HmSpace.xl),
          decoration: BoxDecoration(
            color: HmColors.surfaceInput,
            borderRadius: HmRadius.card,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: HmColors.textSecondary),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Text(
                  text.isEmpty ? context.text.searchPlaceholder : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.isEmpty
                      ? HmText.body
                      : HmText.body.copyWith(color: HmColors.textPrimary),
                ),
              ),
              if (text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: context.text.searchClear,
                  onPressed: onClear,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.tune, size: 18),
          // The number is part of the button's name, so it is announced too.
          label: Text(count > 0 ? context.text.searchFiltersCount(count) : context.text.filterTitle),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
            foregroundColor: count > 0 ? HmColors.brandPrimary : HmColors.textPrimary,
            side: BorderSide(
              color: count > 0 ? HmColors.brandPrimary : HmColors.borderDefault,
            ),
          ),
        ),
      );
}
