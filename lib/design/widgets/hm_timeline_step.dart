import 'package:flutter/material.dart';

import '../tokens.dart';

/// Where a step of a journey stands. The server decides; the app only draws.
enum HmStepState {
  done,
  current,
  upcoming,
  blocked;

  static HmStepState fromServer(String value) => switch (value) {
        'done' => done,
        'current' => current,
        'blocked' => blocked,
        _ => upcoming,
      };
}

/// HM/Workflow/TimelineStep: one step of an enquiry, rental, listing or
/// earning journey — a dot on a rail, a title, a date and a sentence.
///
/// [HmTimeline] (hm_timeline.dart) is the customer journey's list of steps
/// and keeps its own look.
class HmTimelineStep extends StatelessWidget {
  const HmTimelineStep({
    super.key,
    required this.title,
    required this.state,
    this.date,
    this.description,
    this.isLast = false,
  });

  final String title;
  final HmStepState state;
  final String? date;
  final String? description;

  /// The last step has no line hanging below it.
  final bool isLast;

  (Color fill, Color mark, IconData? icon) get _dot => switch (state) {
        HmStepState.done => (HmColors.greenBg, HmColors.greenText, Icons.check_rounded),
        HmStepState.current => (HmColors.orangeBg, HmColors.orangeText, Icons.schedule_rounded),
        HmStepState.blocked => (HmColors.redBg, HmColors.redText, Icons.close_rounded),
        HmStepState.upcoming => (HmColors.surfaceInput, HmColors.textTertiary, null),
      };

  @override
  Widget build(BuildContext context) {
    final (fill, mark, icon) = _dot;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: fill,
                    shape: BoxShape.circle,
                    border: icon == null ? Border.all(color: HmColors.borderStrong, width: 2) : null,
                  ),
                  child: icon == null ? null : Icon(icon, size: 14, color: mark),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(key: const ValueKey('timeline-line'), width: 2, color: HmColors.borderDefault),
                  ),
              ],
            ),
          ),
          const SizedBox(width: HmSpace.xl),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : HmSpace.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: state == HmStepState.upcoming ? HmColors.textSecondary : HmColors.textPrimary,
                          ),
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(width: HmSpace.md),
                        Text(
                          date!,
                          style: TextStyle(
                            fontSize: 12,
                            color: state == HmStepState.current ? HmColors.orangeText : HmColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: HmSpace.xs),
                    Text(description!, style: const TextStyle(fontSize: 13, height: 18 / 13, color: HmColors.textBody)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
