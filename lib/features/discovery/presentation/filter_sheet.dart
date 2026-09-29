import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_choice.dart';
import '../../../design/widgets/hm_money.dart';
import '../../shared/catalogue_repository.dart';
import '../../shared/models.dart';
import '../data/search_providers.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-002b. The filter sheet, as the designs draw it.
///
/// It edits a local copy and only publishes it on "Show results", so the
/// results behind it do not churn while you are still deciding — and closing
/// it genuinely cancels.
///
/// The footer's count is the one thing that does talk to the server as you go,
/// on a short pause after each change: "24 properties match" is the only
/// honest way to know whether a filter has narrowed things to nothing before
/// committing to it, and the pause is what keeps that from being a search per
/// pixel of slider drag.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late PropertyFilters _draft = ref.read(searchFiltersProvider);

  /// The draft the footer's count is for.
  ///
  /// Separate from [_draft] and updated on a pause, because a `RangeSlider`
  /// fires on every tick: counting against the live draft would be a search
  /// per pixel of drag, each one a distinct provider key the framework then
  /// has to keep.
  late PropertyFilters _counted = _draft;
  Timer? _countDebounce;

  @override
  void dispose() {
    _countDebounce?.cancel();
    super.dispose();
  }

  /// Every edit goes through here, so there is one place the count is kept in
  /// step with the draft.
  void _edit(PropertyFilters Function(PropertyFilters draft) change) {
    setState(() => _draft = change(_draft));
    _countDebounce?.cancel();
    _countDebounce = Timer(
      const Duration(milliseconds: 400),
      () => mounted ? setState(() => _counted = _draft) : null,
    );
  }

  /// The price range the slider spans. Above this the label reads "10M+" — a
  /// slider that reaches a hundred million makes every ordinary rent a pixel.
  static const _maxPrice = 10000000.0;
  static const _maxArea = 500.0;

  String _availability = 'any';

  RangeValues get _priceRange => RangeValues(
        (_draft.minPrice ?? 0).clamp(0, _maxPrice),
        (_draft.maxPrice ?? _maxPrice).clamp(0, _maxPrice),
      );

  RangeValues get _areaRange => RangeValues(
        (_draft.minSizeSqm ?? 0).clamp(0, _maxArea),
        (_draft.maxSizeSqm ?? _maxArea).clamp(0, _maxArea),
      );

  void _setAvailability(String value) {
    final today = DateTime.now();
    setState(() => _availability = value);
    _edit((draft) => draft.copyWith(
          availableBy: switch (value) {
            'immediately' => today,
            'this_month' => DateTime(today.year, today.month + 1, 0),
            _ => null,
          },
        ));
  }

  Future<void> _pickCustomDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.availableBy ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      helpText: context.text.filterAvailableBy,
    );
    if (picked == null) return;
    setState(() => _availability = 'custom');
    _edit((draft) => draft.copyWith(availableBy: picked));
  }

  void _reset() {
    setState(() => _availability = 'any');
    _edit((draft) => PropertyFilters(query: draft.query));
  }

  void _apply() {
    ref.read(searchFiltersProvider.notifier).apply(_draft);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final reference = ref.watch(referenceDataProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: HmColors.bgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(HmRadius.huge)),
        ),
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).pop(false), onReset: _reset),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  HmSpace.huge,
                  HmSpace.huge,
                  HmSpace.huge,
                  HmSpace.section,
                ),
                children: [
                  _Group(
                    title: context.text.filterSectionType,
                    child: reference.when(
                      loading: () => const _InlineLoading(),
                      error: (_, __) => const _InlineUnavailable(),
                      data: (data) => _PropertyTypes(
                        types: data.propertyTypes,
                        selected: _draft.propertyTypeId,
                        onSelected: (id) => _edit((draft) => draft.copyWith(propertyTypeId: id)),
                      ),
                    ),
                  ),

                  _Group(
                    title: context.text.filterSectionRent,
                    child: Column(
                      children: [
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: _maxPrice,
                          divisions: 20,
                          onChanged: (values) => _edit((draft) => draft.copyWith(
                                minPrice: values.start == 0 ? null : values.start,
                                maxPrice: values.end >= _maxPrice ? null : values.end,
                              )),
                        ),
                        _RangeCaption(
                          low: HmMoney.format(0),
                          middle: '${_short(_priceRange.start)} – '
                              '${_priceRange.end >= _maxPrice ? context.text.prefsAny : _short(_priceRange.end)}',
                          high: '${_short(_maxPrice)}+',
                        ),
                      ],
                    ),
                  ),

                  _Group(
                    title: context.text.filterSectionBedrooms,
                    child: HmSegmentedPills<int?>(
                      options: [
                        (null, context.text.prefsAny),
                        (0, context.text.prefsStudio),
                        (1, '1'),
                        (2, '2'),
                        (3, '3'),
                        (4, '4+'),
                      ],
                      value: _draft.bedrooms,
                      onChanged: (value) => _edit((draft) => draft.copyWith(bedrooms: value)),
                    ),
                  ),

                  _Group(
                    title: context.text.filterSectionBathrooms,
                    child: HmSegmentedPills<int?>(
                      options: [(null, context.text.prefsAny), (1, '1'), (2, '2'), (3, '3'), (4, '4+')],
                      value: _draft.bathrooms,
                      onChanged: (value) => _edit((draft) => draft.copyWith(bathrooms: value)),
                    ),
                  ),

                  _Group(
                    title: context.text.filterSectionArea,
                    child: Column(
                      children: [
                        RangeSlider(
                          values: _areaRange,
                          min: 0,
                          max: _maxArea,
                          divisions: 25,
                          onChanged: (values) => _edit((draft) => draft.copyWith(
                                minSizeSqm: values.start == 0 ? null : values.start,
                                maxSizeSqm: values.end >= _maxArea ? null : values.end,
                              )),
                        ),
                        _RangeCaption(
                          low: '0 sqm',
                          middle: '${_areaRange.start.round()} sqm – '
                              '${_areaRange.end >= _maxArea ? context.text.prefsAny : '${_areaRange.end.round()} sqm'}',
                          high: '${_maxArea.round()} sqm',
                        ),
                      ],
                    ),
                  ),

                  _Group(
                    title: context.text.filterSectionAmenities,
                    child: reference.when(
                      loading: () => const _InlineLoading(),
                      error: (_, __) => const _InlineUnavailable(),
                      data: (data) => _AmenityGrid(
                        amenities: data.amenities,
                        selected: _draft.amenityIds,
                        onChanged: (ids) => _edit((draft) => draft.copyWith(amenityIds: ids)),
                      ),
                    ),
                  ),

                  _VerifiedToggle(
                    value: _draft.verifiedOnly,
                    onChanged: (value) => _edit((draft) => draft.copyWith(verifiedOnly: value)),
                  ),

                  _Group(
                    title: context.text.filterSectionAvailability,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HmSegmentedPills<String>(
                          options: [
                            ('any', context.text.filterAnyTime),
                            ('immediately', context.text.prefsTimelineNow),
                            ('this_month', context.text.filterThisMonth),
                            ('custom', context.text.filterCustomDate),
                          ],
                          value: _availability,
                          onChanged: (value) =>
                              value == 'custom' ? _pickCustomDate() : _setAvailability(value),
                        ),
                        if (_availability == 'custom' && _draft.availableBy != null) ...[
                          const SizedBox(height: HmSpace.md),
                          Text(
                            context.text.filterAvailableOn(_formatDate(_draft.availableBy!)),
                            style: HmText.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _Footer(draft: _counted, onApply: _apply),
          ],
        ),
      ),
    );
  }

  /// "TZS 300K", "TZS 2.0M" — the designs' shorthand, because a slider label
  /// that reads "TZS 1,200,000" does not fit under a thumb.
  static String _short(double value) {
    if (value >= 1000000) return 'TZS ${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'TZS ${(value / 1000).round()}K';
    return HmMoney.format(value);
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onReset});

  final VoidCallback onClose;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(HmSpace.xl, HmSpace.xl, HmSpace.xl, HmSpace.xl),
        child: Row(
          children: [
            Material(
              color: HmColors.surfaceInput,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: context.text.filterClose,
                onPressed: onClose,
              ),
            ),
            Expanded(
              child: Text(context.text.filterTitle, style: HmText.title, textAlign: TextAlign.center),
            ),
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(foregroundColor: HmColors.error),
              child: Text(context.text.filterReset),
            ),
          ],
        ),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HmSpace.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: HmText.label.copyWith(
                color: HmColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: HmSpace.xl),
            child,
          ],
        ),
      );
}

/// context.text.listingsAll plus one pill per type. context.text.listingsAll is not a type — it is the absence of
/// the filter — so selecting it clears rather than sets.
class _PropertyTypes extends StatelessWidget {
  const _PropertyTypes({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<ReferenceItem> types;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: HmSpace.md,
        runSpacing: HmSpace.md,
        children: [
          HmChoicePill(
            label: context.text.listingsAll,
            dense: true,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final type in types)
            HmChoicePill(
              label: type.name,
              dense: true,
              selected: selected == type.id,
              onTap: () => onSelected(selected == type.id ? null : type.id),
            ),
        ],
      );
}

class _AmenityGrid extends StatelessWidget {
  const _AmenityGrid({
    required this.amenities,
    required this.selected,
    required this.onChanged,
  });

  final List<ReferenceItem> amenities;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return Text(context.text.filterNoAmenities, style: HmText.caption);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 3 : 2;
        final width = (constraints.maxWidth - HmSpace.md * (columns - 1)) / columns;

        return Wrap(
          spacing: HmSpace.md,
          runSpacing: HmSpace.md,
          children: [
            for (final amenity in amenities)
              SizedBox(
                width: width,
                child: HmCheckTile(
                  label: amenity.name,
                  checked: selected.contains(amenity.id),
                  onChanged: (checked) {
                    final next = [...selected];
                    checked ? next.add(amenity.id) : next.remove(amenity.id);
                    onChanged(next);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VerifiedToggle extends StatelessWidget {
  const _VerifiedToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HmSpace.section),
        child: Container(
          padding: const EdgeInsets.all(HmSpace.xxl),
          decoration: BoxDecoration(
            color: HmColors.bgPrimary,
            borderRadius: HmRadius.card,
            border: Border.all(color: HmColors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.text.filterVerifiedOnly, style: HmText.heading),
                    const SizedBox(height: HmSpace.xs),
                    Text(
                      context.text.filterVerifiedOnlyHelp,
                      style: HmText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      );
}

/// "24 properties match" and the button.
///
/// The count runs the *draft* rather than the applied filters, which is the
/// whole point: it tells you what "Show results" would give you before you
/// commit, so narrowing to nothing is something you find out here rather than
/// on an empty results page.
class _Footer extends ConsumerWidget {
  const _Footer({required this.draft, required this.onApply});

  final PropertyFilters draft;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(searchResultsProvider(draft));

    return Material(
      color: HmColors.bgPrimary,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.huge),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.maybeWhen(
                        data: (page) => context.text.filterMatches(page.total),
                        orElse: () => context.text.filterCounting,
                      ),
                      style: HmText.heading,
                    ),
                    const SizedBox(height: HmSpace.xxs),
                    Text(context.text.filterBasedOn, style: HmText.caption),
                  ],
                ),
              ),
              const SizedBox(width: HmSpace.xl),
              ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: HmSpace.huge),
                  // The theme's `Size.fromHeight(52)` means a minimum width of
                  // infinity, which is right for a full-bleed button and fatal
                  // beside a flexible child: the Row offers unbounded width and
                  // the button demands all of it. Keep the height, drop the
                  // width floor.
                  minimumSize: const Size(0, 52),
                ),
                child: Text(context.text.filterShow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeCaption extends StatelessWidget {
  const _RangeCaption({required this.low, required this.middle, required this.high});

  final String low;
  final String middle;
  final String high;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(low, style: HmText.caption)),
          Text(
            middle,
            style: HmText.label.copyWith(color: HmColors.brandPrimary),
          ),
          Expanded(
            child: Text(high, style: HmText.caption, textAlign: TextAlign.right),
          ),
        ],
      );
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: HmSpace.xl),
        child: Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

class _InlineUnavailable extends StatelessWidget {
  const _InlineUnavailable();

  @override
  Widget build(BuildContext context) => Text(
        context.text.filterOptionsFailed,
        style: HmText.caption,
      );
}
