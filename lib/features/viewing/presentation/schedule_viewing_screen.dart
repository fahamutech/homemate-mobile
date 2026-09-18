import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import '../data/viewing_providers.dart';

/// CUS-009a / CUS-307. Choosing when to see the place.
///
/// The date and time are two taps rather than a free-text field: "sometime
/// Saturday afternoon" is not something a landlord can confirm.
class ScheduleViewingScreen extends ConsumerStatefulWidget {
  const ScheduleViewingScreen({super.key, required this.propertyId, this.inquiryId});

  final String propertyId;
  final String? inquiryId;

  @override
  ConsumerState<ScheduleViewingScreen> createState() => _ScheduleViewingScreenState();
}

class _ScheduleViewingScreenState extends ConsumerState<ScheduleViewingScreen> {
  final _note = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  bool _busy = false;
  String? _error;

  /// The slots landlords actually offer — a viewing at 3am is not a real
  /// choice, and offering it only invites a rejection.
  static const _slots = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 30),
    TimeOfDay(hour: 17, minute: 0),
  ];

  /// The next seven days, offered as chips.
  List<DateTime> get _days {
    final today = DateTime.now();
    return List.generate(7, (index) => DateTime(today.year, today.month, today.day + index));
  }

  DateTime? get _scheduledFor {
    if (_date == null || _time == null) return null;
    return DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final when = _scheduledFor;
    if (when == null) {
      setState(() => _error = 'Choose a day and a time');
      return;
    }
    if (when.isBefore(DateTime.now())) {
      // The server refuses this too; catching it here saves a round trip and
      // explains it in the same breath.
      setState(() => _error = 'That time has already passed — pick a later one');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final viewing = await ref.read(activityRepositoryProvider).requestViewing(
            propertyId: widget.propertyId,
            scheduledFor: when,
            inquiryId: widget.inquiryId,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      ref.invalidate(activitySummaryProvider);
      ref.invalidate(viewingsProvider(true));
      ref.invalidate(viewingsProvider(false));

      if (!mounted) return;
      HmFeedback.success(context, 'Viewing requested');
      context.pushReplacement(Routes.viewing(viewing.id));
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HmScaffold(
      title: 'Book a viewing',
      backgroundColor: HmColors.bgPrimary,
      body: ListView(
        children: [
          HmInlineError(_error),

          const Text('Pick a day', style: HmText.label),
          const SizedBox(height: HmSpace.md),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: HmSpace.md),
              itemBuilder: (_, index) {
                final day = _days[index];
                final selected = _date != null &&
                    _date!.day == day.day &&
                    _date!.month == day.month;
                return _DayChip(
                  day: day,
                  selected: selected,
                  isToday: index == 0,
                  onTap: _busy ? null : () => setState(() => _date = day),
                );
              },
            ),
          ),

          const SizedBox(height: HmSpace.huge),
          const Text('Pick a time', style: HmText.label),
          const SizedBox(height: HmSpace.md),
          Wrap(
            spacing: HmSpace.md,
            runSpacing: HmSpace.md,
            children: [
              for (final slot in _slots)
                ChoiceChip(
                  label: Text(slot.format(context)),
                  selected: _time == slot,
                  onSelected: _busy ? null : (_) => setState(() => _time = slot),
                ),
            ],
          ),

          const SizedBox(height: HmSpace.huge),
          const Text('Anything to add? (optional)', style: HmText.label),
          const SizedBox(height: HmSpace.md),
          TextField(
            controller: _note,
            enabled: !_busy,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'I will come with my partner, we may be 10 minutes late',
            ),
          ),

          const SizedBox(height: HmSpace.section),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Request viewing'),
          ),
          const SizedBox(height: HmSpace.md),
          const Text(
            'The landlord confirms the time. You will be notified either way.',
            style: HmText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final VoidCallback? onTap;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: HmRadius.card,
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: HmSpace.xl),
          decoration: BoxDecoration(
            color: selected ? HmColors.brandPrimary : HmColors.surfaceInput,
            borderRadius: HmRadius.card,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isToday ? 'Today' : _weekdays[day.weekday - 1],
                style: HmText.caption.copyWith(
                  color: selected ? HmColors.textOnBrand : HmColors.textSecondary,
                ),
              ),
              const SizedBox(height: HmSpace.xs),
              Text(
                '${day.day}',
                style: HmText.heading.copyWith(
                  color: selected ? HmColors.textOnBrand : HmColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
}
