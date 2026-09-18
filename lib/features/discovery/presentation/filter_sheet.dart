import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_money.dart';
import '../../shared/catalogue_repository.dart';
import '../data/search_providers.dart';

/// CUS-002b. The filter sheet.
///
/// It edits a local copy and only publishes it on "Apply", so dragging a price
/// slider does not fire a search per pixel — and "Cancel" genuinely cancels.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late PropertyFilters _draft = ref.read(searchFiltersProvider);

  /// The price range the slider spans. Above this, the customer types a number
  /// instead — a slider that reaches 100M makes every normal rent one pixel.
  static const _maxPrice = 5000000.0;

  RangeValues get _priceRange => RangeValues(
        (_draft.minPrice ?? 0).clamp(0, _maxPrice),
        (_draft.maxPrice ?? _maxPrice).clamp(0, _maxPrice),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: HmSpace.xl),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: HmColors.borderStrong,
              borderRadius: BorderRadius.circular(HmRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Row(
              children: [
                Expanded(child: Text('Filters', style: HmText.title)),
                TextButton(
                  onPressed: () => setState(() => _draft = PropertyFilters(query: _draft.query)),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(HmSpace.xxl),
              children: [
                _Section(
                  title: 'Monthly rent',
                  subtitle: '${HmMoney.format(_priceRange.start)} — '
                      '${_priceRange.end >= _maxPrice ? 'Any' : HmMoney.format(_priceRange.end)}',
                  child: RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: _maxPrice,
                    divisions: 20,
                    labels: RangeLabels(
                      HmMoney.format(_priceRange.start),
                      _priceRange.end >= _maxPrice ? 'Any' : HmMoney.format(_priceRange.end),
                    ),
                    onChanged: (values) => setState(() {
                      _draft = _draft.copyWith(
                        minPrice: values.start == 0 ? null : values.start,
                        maxPrice: values.end >= _maxPrice ? null : values.end,
                      );
                    }),
                  ),
                ),

                _Section(
                  title: 'Bedrooms',
                  child: Wrap(
                    spacing: HmSpace.md,
                    children: [
                      for (final bedrooms in [1, 2, 3, 4, 5])
                        ChoiceChip(
                          label: Text(bedrooms == 5 ? '5+' : '$bedrooms'),
                          selected: _draft.bedrooms == bedrooms,
                          onSelected: (selected) => setState(() {
                            _draft = _draft.copyWith(bedrooms: selected ? bedrooms : null);
                          }),
                        ),
                    ],
                  ),
                ),

                _Section(
                  title: 'Furnishing',
                  child: Wrap(
                    spacing: HmSpace.md,
                    children: [
                      for (final (value, label) in const [
                        ('unfurnished', 'Unfurnished'),
                        ('semi_furnished', 'Semi furnished'),
                        ('fully_furnished', 'Fully furnished'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _draft.furnishing == value,
                          onSelected: (selected) => setState(() {
                            _draft = _draft.copyWith(furnishing: selected ? value : null);
                          }),
                        ),
                    ],
                  ),
                ),

                _Section(
                  title: 'How rent is paid',
                  child: Wrap(
                    spacing: HmSpace.md,
                    children: [
                      for (final (value, label) in const [
                        ('monthly', 'Monthly'),
                        ('quarterly', 'Quarterly'),
                        ('semi_annual', 'Every 6 months'),
                        ('annual', 'Yearly'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _draft.paymentFrequency == value,
                          onSelected: (selected) => setState(() {
                            _draft = _draft.copyWith(paymentFrequency: selected ? value : null);
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(HmSpace.xxl),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: HmSpace.xl),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(searchFiltersProvider.notifier).apply(_draft);
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        _draft.activeCount > 0 ? 'Apply (${_draft.activeCount})' : 'Apply',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HmSpace.huge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: HmText.label),
            if (subtitle != null) ...[
              const SizedBox(height: HmSpace.xxs),
              Text(subtitle!, style: HmText.caption),
            ],
            const SizedBox(height: HmSpace.md),
            child,
          ],
        ),
      );
}
