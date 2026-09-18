import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../shared/property_card.dart';
import '../data/search_providers.dart';
import 'filter_sheet.dart';
import 'results_map.dart';

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
  final _queryController = TextEditingController();
  Timer? _debounce;
  bool _mapView = false;

  @override
  void initState() {
    super.initState();
    _queryController.text = ref.read(searchFiltersProvider).query ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  /// Typing should not fire a request per keystroke — on a slow connection
  /// that is a queue of answers arriving out of order.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchFiltersProvider.notifier).setQuery(value);
    });
  }

  Future<void> _openFilters() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
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
                    child: TextField(
                      key: const Key('search-field'),
                      controller: _queryController,
                      onChanged: _onQueryChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Area, title or reference',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _queryController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _queryController.clear();
                                  ref.read(searchFiltersProvider.notifier).setQuery(null);
                                  setState(() {});
                                },
                              ),
                      ),
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
                        data: (page) => page.total == 1 ? '1 home' : '${page.total} homes',
                        orElse: () => 'Searching…',
                      ),
                      style: HmText.caption,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, icon: Icon(Icons.view_list_outlined), label: Text('List')),
                      ButtonSegment(value: true, icon: Icon(Icons.map_outlined), label: Text('Map')),
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
                  title: 'Nothing matches that',
                  message: filters.activeCount > 0
                      ? 'Try widening your filters or searching a different area.'
                      : 'Try a different area or price.',
                  icon: Icons.search_off_outlined,
                  action: filters.activeCount > 0
                      ? OutlinedButton(
                          onPressed: () => ref.read(searchFiltersProvider.notifier).clear(),
                          child: const Text('Clear filters'),
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
          label: Text(count > 0 ? 'Filters ($count)' : 'Filters'),
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
