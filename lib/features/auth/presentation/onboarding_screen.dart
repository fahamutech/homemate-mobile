import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_scaffold.dart';
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

  static const _pages = [
    _Slide(
      icon: Icons.search_rounded,
      title: 'Find your home',
      body: 'Browse verified listings across Tanzania, with real photos and honest prices.',
    ),
    _Slide(
      icon: Icons.event_available_rounded,
      title: 'Schedule viewings',
      body: 'Ask the landlord a question and arrange to see the place, all in one app.',
    ),
    _Slide(
      icon: Icons.vpn_key_rounded,
      title: 'Move in',
      body: 'Book it, pay securely, and keep every receipt and document in one place.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

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
    return HmScaffold(
      padded: false,
      backgroundColor: HmColors.bgPrimary,
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(HmSpace.md),
              child: TextButton(
                onPressed: () => context.go(Routes.signIn),
                child: const Text('Skip'),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (index) => setState(() => _page = index),
              children: _pages,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: HmSpace.xs),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? HmColors.brandPrimary : HmColors.borderStrong,
                    borderRadius: BorderRadius.circular(HmRadius.pill),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(HmSpace.huge),
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_isLast ? 'Get started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.section),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: HmColors.brandPrimarySoft,
                borderRadius: BorderRadius.circular(HmRadius.huge),
              ),
              child: Icon(icon, size: 56, color: HmColors.brandPrimary),
            ),
            const SizedBox(height: HmSpace.section),
            Text(title, style: HmText.title, textAlign: TextAlign.center),
            const SizedBox(height: HmSpace.xxl),
            Text(body, style: HmText.body, textAlign: TextAlign.center),
          ],
        ),
      );
}
