import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/i18n/language_picker.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_slide.dart';
import '../../../routing/app_router.dart';

/// CUS-001b/c/d — the three things the app is for, before asking for a number.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 3;

  bool get _isLast => _page == _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      context.go(Routes.signIn);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    // Built here rather than held in a `static const`: the slides are words,
    // and the words change when the language does.
    final pages = [
      HmSlide(
        icon: Icons.search_rounded,
        title: text.onboardingFindTitle,
        body: text.onboardingFindBody,
      ),
      HmSlide(
        icon: Icons.mark_chat_read_rounded,
        title: text.onboardingEnquireTitle,
        body: text.onboardingEnquireBody,
      ),
      HmSlide(
        icon: Icons.vpn_key_rounded,
        title: text.onboardingMoveInTitle,
        body: text.onboardingMoveInBody,
      ),
    ];

    return HmScaffold(
      padded: false,
      backgroundColor: HmColors.bgPrimary,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(HmSpace.md),
            child: Row(
              children: [
                // First control on the first screen: somebody who does not read
                // English must be able to change the language before being
                // asked to understand anything else.
                const LanguageButton(),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(Routes.signIn),
                  child: Text(text.skip),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (index) => setState(() => _page = index),
              children: pages,
            ),
          ),
          HmPageDots(count: _pageCount, index: _page),
          Padding(
            padding: const EdgeInsets.all(HmSpace.huge),
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_isLast ? text.getStarted : text.next),
            ),
          ),
        ],
      ),
    );
  }
}
