import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../data/viewing_providers.dart';

/// CUS-010a. Viewings, upcoming first.
class ViewingsScreen extends ConsumerStatefulWidget {
  const ViewingsScreen({super.key});

  @override
  ConsumerState<ViewingsScreen> createState() => _ViewingsScreenState();
}

class _ViewingsScreenState extends ConsumerState<ViewingsScreen> {
  bool _upcomingOnly = true;

  @override
  Widget build(BuildContext context) {
    final viewings = ref.watch(viewingsProvider(_upcomingOnly));

    return HmScaffold(
      title: 'My viewings',
      padded: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Upcoming')),
                ButtonSegment(value: false, label: Text('All')),
              ],
              selected: {_upcomingOnly},
              showSelectedIcon: false,
              onSelectionChanged: (values) => setState(() => _upcomingOnly = values.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(viewingsProvider(_upcomingOnly)),
              child: HmAsync(
                value: viewings,
                onRetry: () => ref.invalidate(viewingsProvider(_upcomingOnly)),
                emptyWhen: (page) => page.isEmpty,
                empty: HmEmpty(
                  title: _upcomingOnly ? 'No viewings coming up' : 'No viewings yet',
                  message: 'Find a place you like and book a time to see it.',
                  icon: Icons.event_busy_outlined,
                  action: OutlinedButton(
                    onPressed: () => context.go(Routes.search),
                    child: const Text('Find a home'),
                  ),
                ),
                data: (page) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(HmSpace.xxl, 0, HmSpace.xxl, HmSpace.section),
                  itemCount: page.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: HmSpace.xl),
                  itemBuilder: (_, index) => ViewingTile(viewing: page.items[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ViewingTile extends StatelessWidget {
  const ViewingTile({super.key, required this.viewing});

  final Viewing viewing;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: HmRadius.card,
          onTap: () => context.push(Routes.viewing(viewing.id)),
          child: Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Row(
              children: [
                _DateBlock(date: viewing.scheduledFor),
                const SizedBox(width: HmSpace.xxl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewing.propertyTitle ?? 'Property',
                        style: HmText.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: HmSpace.xs),
                      Text(
                        '${_time(viewing.scheduledFor)}'
                        '${viewing.hostName == null ? '' : ' · ${viewing.hostName}'}',
                        style: HmText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: HmSpace.md),
                      HmStatusChip(viewing.status, dense: true),
                    ],
                  ),
                ),
                PropertyImage(mediaId: viewing.coverMediaId, height: 56, width: 56),
              ],
            ),
          ),
        ),
      );

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

/// The date as a calendar block, which is how the designs show an appointment.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date});

  final DateTime date;

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: HmSpace.lg),
        decoration: BoxDecoration(
          color: HmColors.brandPrimarySoft,
          borderRadius: HmRadius.card,
        ),
        child: Column(
          children: [
            Text(
              _months[date.month - 1],
              style: HmText.caption.copyWith(
                color: HmColors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${date.day}',
              style: HmText.heading.copyWith(color: HmColors.brandPrimary),
            ),
          ],
        ),
      );
}
