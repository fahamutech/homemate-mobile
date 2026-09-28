import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens.dart';
import '../i18n/app_text.dart';
import 'app_update_controller.dart';
import 'app_updater.dart';

/// A bar under the whole app while a newer build is on offer.
///
/// Mounted once, in `MaterialApp.builder`, so it is there on every screen
/// without any screen knowing. It sits *below* the app rather than over it —
/// covering the bottom navigation would be worse than the one-line squeeze —
/// and the tree keeps the same shape whether it shows or not, so appearing
/// never rebuilds the navigator underneath.
class AppUpdateBanner extends ConsumerStatefulWidget {
  const AppUpdateBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends ConsumerState<AppUpdateBanner> {
  /// Closing the bar hides that one offer; the next step (download finished)
  /// brings it back, because that is the step that needs the customer.
  AppUpdateStatus? _dismissed;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appUpdateProvider);
    final media = MediaQuery.of(context);
    // Behind the keyboard it could not be read, and it would throw off the
    // screen's own keyboard avoidance.
    final show = status != AppUpdateStatus.none &&
        status != _dismissed &&
        media.viewInsets.bottom == 0;

    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: show,
            child: widget.child,
          ),
        ),
        if (show)
          _Bar(
            status: status,
            onAction: () => ref.read(appUpdateProvider.notifier).apply(),
            onClose: () => setState(() => _dismissed = status),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.status, required this.onAction, required this.onClose});

  final AppUpdateStatus status;
  final VoidCallback onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final (message, action) = switch (status) {
      AppUpdateStatus.available => (text.updateAvailable, text.updateAction),
      AppUpdateStatus.downloading => (text.updateDownloading, null),
      // The same word on both platforms would be wrong: Android restarts the
      // app, the web reloads the page.
      _ => (
          text.updateReady,
          kIsWeb ? text.updateReload : text.updateRestart,
        ),
    };

    return Material(
      color: HmColors.textPrimary,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == AppUpdateStatus.downloading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: HmColors.brandPrimary,
                backgroundColor: Colors.transparent,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.md, HmSpace.xs, HmSpace.md),
              child: Row(
                children: [
                  const Icon(Icons.system_update_outlined, size: 20, color: HmColors.textOnBrand),
                  const SizedBox(width: HmSpace.xl),
                  Expanded(
                    child: Text(
                      message,
                      style: HmText.label.copyWith(color: HmColors.textOnBrand),
                    ),
                  ),
                  if (action != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(foregroundColor: HmColors.brandPrimary),
                      child: Text(action),
                    ),
                  // No tooltip: this sits above the navigator, so there is no
                  // Overlay for one to open in.
                  Semantics(
                    button: true,
                    label: text.close,
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 18, color: HmColors.textDisabled),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
