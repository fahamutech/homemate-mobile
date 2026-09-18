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
import '../../../design/widgets/hm_prompt.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../data/viewing_providers.dart';

/// CUS-010b/c/d. One viewing: when, where, who, and how to call it off.
class ViewingDetailScreen extends ConsumerWidget {
  const ViewingDetailScreen({super.key, required this.viewingId});

  final String viewingId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await HmPrompt.show(
      context,
      title: 'Cancel this viewing?',
      message: 'Let the landlord know why, so they can offer the slot to someone else.',
      cancelLabel: 'Keep it',
      confirmLabel: 'Cancel viewing',
      destructive: true,
    );
    if (reason == null || reason.isEmpty) return;

    try {
      await ref.read(activityRepositoryProvider).cancelViewing(viewingId, reason);
      ref.invalidate(viewingProvider(viewingId));
      ref.invalidate(viewingsProvider(true));
      ref.invalidate(viewingsProvider(false));
      ref.invalidate(activitySummaryProvider);
      if (context.mounted) HmFeedback.success(context, 'Viewing cancelled');
    } catch (error) {
      if (context.mounted) HmFeedback.failure(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewing = ref.watch(viewingProvider(viewingId));

    return HmScaffold(
      title: 'Viewing',
      body: HmAsync(
        value: viewing,
        onRetry: () => ref.invalidate(viewingProvider(viewingId)),
        data: (data) => ListView(
          children: [
            Row(
              children: [
                Expanded(child: HmStatusChip(data.status)),
                Text(data.reference, style: HmText.caption),
              ],
            ),
            const SizedBox(height: HmSpace.huge),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(HmSpace.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(
                      icon: Icons.calendar_today_outlined,
                      label: 'When',
                      value: '${data.scheduledFor.day}/${data.scheduledFor.month}/'
                          '${data.scheduledFor.year} at '
                          '${data.scheduledFor.hour.toString().padLeft(2, '0')}:'
                          '${data.scheduledFor.minute.toString().padLeft(2, '0')}',
                    ),
                    if (data.propertyTitle != null)
                      _Line(
                        icon: Icons.home_outlined,
                        label: 'Property',
                        value: data.propertyTitle!,
                        onTap: data.propertyId == null
                            ? null
                            : () => context.push(Routes.property(data.propertyId!)),
                      ),
                    if (data.meetingPoint != null)
                      _Line(
                        icon: Icons.place_outlined,
                        label: 'Meet at',
                        value: data.meetingPoint!,
                      ),
                    if (data.hostName != null)
                      _Line(
                        icon: Icons.person_outline,
                        label: 'Host',
                        // The phone number appears only once the viewing is
                        // confirmed — before that there is nothing to call about.
                        value: data.status == 'confirmed' && data.hostPhone != null
                            ? '${data.hostName} · ${data.hostPhone}'
                            : data.hostName!,
                      ),
                  ],
                ),
              ),
            ),

            if (data.status == 'requested')
              const Padding(
                padding: EdgeInsets.only(top: HmSpace.huge),
                child: Text(
                  'Waiting for the landlord to confirm this time.',
                  style: HmText.caption,
                  textAlign: TextAlign.center,
                ),
              ),

            if (data.cancellationReason != null) ...[
              const SizedBox(height: HmSpace.huge),
              Container(
                padding: const EdgeInsets.all(HmSpace.xxl),
                decoration: BoxDecoration(
                  color: HmColors.error.withValues(alpha: 0.08),
                  borderRadius: HmRadius.card,
                ),
                child: Text('Cancelled: ${data.cancellationReason}', style: HmText.body),
              ),
            ],

            if (data.hasLocation) ...[
              const SizedBox(height: HmSpace.huge),
              ClipRRect(
                borderRadius: HmRadius.card,
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(data.latitude!, data.longitude!),
                      initialZoom: 15,
                      interactionOptions:
                          const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: Env.mapTileUrl,
                        userAgentPackageName: Env.mapUserAgent,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(data.latitude!, data.longitude!),
                            child: const Icon(Icons.place, color: HmColors.error, size: 36),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: HmSpace.section),
            if (data.canCancel)
              OutlinedButton(
                onPressed: () => _cancel(context, ref),
                style: OutlinedButton.styleFrom(foregroundColor: HmColors.error),
                child: const Text('Cancel viewing'),
              ),
            if (data.status == 'completed' && data.propertyId != null) ...[
              const SizedBox(height: HmSpace.xl),
              ElevatedButton(
                onPressed: () => context.push(Routes.property(data.propertyId!)),
                child: const Text('Book this property'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.value, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: HmSpace.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: HmColors.textSecondary),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: HmText.caption),
                    const SizedBox(height: HmSpace.xxs),
                    Text(value, style: HmText.label),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, size: 18, color: HmColors.textDisabled),
            ],
          ),
        ),
      );
}
