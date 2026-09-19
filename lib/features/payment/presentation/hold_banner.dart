import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../../shared/journey_models.dart';

/// The ten-minute countdown that runs above a checkout.
///
/// It exists because the property really is reserved while it is on screen —
/// nobody else can start paying — and a reservation the customer cannot see is
/// a reservation they will not hurry for. The wording follows a bus booking
/// for the same reason: "we are holding this for you" is understood
/// immediately, and it explains why the screen has a clock on it at all.
///
/// The countdown is driven from the server's `secondsRemaining`, never from a
/// server timestamp compared against the phone's clock: a device an hour out
/// would otherwise show a hold that had already expired, or one that never ran
/// down.
///
/// Elapsed time is taken as the *larger* of two measures — the timer's own
/// ticks and the wall clock since the reading. The ticks are what make it move
/// smoothly and make it testable; the wall clock is what catches up after the
/// app has been backgrounded, where a periodic timer may not have fired at
/// all. Taking the larger means neither can make the hold look longer than it
/// is, which is the only direction that would cost anybody money.
class HoldBanner extends StatefulWidget {
  const HoldBanner({super.key, required this.hold, this.onExpired});

  final PropertyHold hold;

  /// Called once when the clock reaches zero, so the screen can re-check with
  /// the server rather than guessing that the hold is gone.
  final VoidCallback? onExpired;

  @override
  State<HoldBanner> createState() => _HoldBannerState();
}

class _HoldBannerState extends State<HoldBanner> {
  Timer? _timer;
  int _ticks = 0;
  bool _notified = false;

  Duration get _remaining {
    final wallClock = DateTime.now().difference(widget.hold.readAt).inSeconds;
    final elapsed = _ticks > wallClock ? _ticks : wallClock;
    final left = widget.hold.secondsRemaining - elapsed;
    return Duration(seconds: left < 0 ? 0 : left);
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(HoldBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh hold from the server resets the clock and re-arms the callback —
    // pressing pay extends the window, and the banner has to follow.
    if (oldWidget.hold.id != widget.hold.id ||
        oldWidget.hold.readAt != widget.hold.readAt) {
      _notified = false;
      _ticks = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (!widget.hold.isLive || _remaining == Duration.zero) {
      _expire();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _ticks++);
      if (_remaining == Duration.zero) _expire();
    });
  }

  void _expire() {
    _timer?.cancel();
    if (_notified) return;
    _notified = true;
    // Deferred, because this can fire from `initState` on an already-dead
    // hold and a parent cannot rebuild mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onExpired?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final expired = remaining == Duration.zero;
    final urgent = remaining.inSeconds <= 60 && !expired;
    final colour = expired || urgent ? HmColors.error : HmColors.brandPrimary;

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final label = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl, vertical: HmSpace.xl),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: HmRadius.card,
        border: Border.all(color: colour.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(expired ? Icons.lock_open_outlined : Icons.lock_clock, size: 20, color: colour),
          const SizedBox(width: HmSpace.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expired ? 'Your hold has expired' : 'This home is held for you',
                  style: HmText.label.copyWith(fontSize: 13, color: colour),
                ),
                const SizedBox(height: HmSpace.xxs),
                Text(
                  expired
                      ? 'Someone else can now start paying for it. Try again to take it back.'
                      : 'Nobody else can pay for it while the timer runs.',
                  style: HmText.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (!expired) ...[
            const SizedBox(width: HmSpace.xl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: HmSpace.xl, vertical: HmSpace.sm),
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(HmRadius.sm),
              ),
              child: Text(
                label,
                // A ticking digit read out every second is unusable with a
                // screen reader, so the live text says the minutes only.
                semanticsLabel: minutes > 0
                    ? '$minutes minutes remaining'
                    : 'Less than a minute remaining',
                style: const TextStyle(
                  color: HmColors.textOnBrand,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
