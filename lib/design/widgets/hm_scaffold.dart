import 'package:flutter/material.dart';

import '../tokens.dart';
import '../../core/i18n/app_text.dart';

/// Every screen's outer shell.
///
/// It exists for one reason: the designs are drawn at 390pt, and the app also
/// runs in a desktop browser for verification. Left alone, a form would
/// stretch to 1400pt and become unreadable. Content is capped and centred
/// above the breakpoint, so one set of screens serves both without a second
/// "desktop" layout to keep in step.
class HmScaffold extends StatelessWidget {
  const HmScaffold({
    super.key,
    required this.body,
    this.title,
    this.appBar,
    this.actions,
    this.bottomBar,
    this.bottomNavigationBar,
    this.padded = true,
    this.showBack = true,
    this.backgroundColor,
    this.onBack,
  });

  final Widget body;
  final String? title;
  final PreferredSizeWidget? appBar;
  final List<Widget>? actions;

  /// A pinned action area — "Send enquiry", "I have paid" — that must stay
  /// reachable without scrolling to the end of a long page.
  final Widget? bottomBar;
  final Widget? bottomNavigationBar;
  final bool padded;
  final bool showBack;
  final Color? backgroundColor;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar ??
          (title == null
              ? null
              : AppBar(
                  title: Text(title!),
                  automaticallyImplyLeading: false,
                  leading: showBack && (canPop || onBack != null)
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: context.text.back,
                          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                        )
                      : null,
                  actions: actions,
                )),
      body: SafeArea(
        top: appBar == null && title == null,
        child: _constrained(
          padded
              ? Padding(padding: const EdgeInsets.all(HmSpace.xxl), child: body)
              : body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      persistentFooterAlignment: AlignmentDirectional.center,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomSheet: bottomBar == null
          ? null
          : Material(
              color: HmColors.bgPrimary,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: _constrained(
                  Padding(
                    padding: const EdgeInsets.all(HmSpace.xxl),
                    child: bottomBar,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _constrained(Widget child) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HmLayout.contentMaxWidth),
          child: child,
        ),
      );
}
