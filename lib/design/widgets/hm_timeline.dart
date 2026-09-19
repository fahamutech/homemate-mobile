import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../features/shared/journey_models.dart';
import '../tokens.dart';

/// The status timeline from CUS-007d/e and CUS-013b: a column of dots joined
/// by a line, each with a title, a date and a sentence.
///
/// The state of each dot comes from the server, not from the app comparing
/// dates — which is what keeps "Under Review" from rendering as done simply
/// because its timestamp is in the past.
class HmTimeline extends StatelessWidget {
  const HmTimeline({super.key, required this.events, this.dateFormat});

  final List<JourneyEvent> events;

  /// Overridable so a test can pin the format rather than depend on a locale.
  final DateFormat? dateFormat;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final format = dateFormat ?? DateFormat('d MMM yyyy, h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < events.length; index++)
          _Step(
            event: events[index],
            format: format,
            // The connector hangs below a dot, so the last step has none —
            // a line running into empty space reads as a missing step.
            isLast: index == events.length - 1,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.event, required this.format, required this.isLast});

  final JourneyEvent event;
  final DateFormat format;
  final bool isLast;

  Color get _colour => switch (event.state) {
        'done' => HmColors.brandPrimary,
        'current' => HmColors.warning,
        'blocked' => HmColors.error,
        _ => HmColors.textDisabled,
      };

  @override
  Widget build(BuildContext context) {
    final colour = _colour;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _Dot(colour: colour, state: event.state),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: HmSpace.xs),
                      color: HmColors.borderDefault,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: HmSpace.xl),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : HmSpace.huge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: HmText.label.copyWith(
                            fontSize: 14,
                            color: event.isUpcoming ? HmColors.textSecondary : HmColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: HmSpace.md),
                      Text(
                        event.at == null
                            ? ''
                            : event.isUpcoming
                                // A future step has no time of day worth
                                // printing — "Nov 1, 2026" is the whole fact.
                                ? DateFormat('d MMM yyyy').format(event.at!)
                                : format.format(event.at!),
                        style: HmText.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  if (event.detail != null && event.detail!.isNotEmpty) ...[
                    const SizedBox(height: HmSpace.xs),
                    Text(
                      event.detail!,
                      style: HmText.caption.copyWith(fontSize: 13, color: HmColors.textBody),
                    ),
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

/// A finished step carries a tick, the step you are on is a filled ring, and
/// anything still to come is a hollow dot. That difference has to survive a
/// screenshot in greyscale, so it is a shape as well as a colour.
class _Dot extends StatelessWidget {
  const _Dot({required this.colour, required this.state});

  final Color colour;
  final String state;

  @override
  Widget build(BuildContext context) {
    if (state == 'done') {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: HmColors.textOnBrand),
      );
    }
    if (state == 'blocked') {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        child: const Icon(Icons.close, size: 14, color: HmColors.textOnBrand),
      );
    }

    final isCurrent = state == 'current';
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isCurrent ? colour.withValues(alpha: 0.18) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: isCurrent ? colour : HmColors.borderStrong, width: 2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCurrent ? colour : HmColors.borderStrong,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
