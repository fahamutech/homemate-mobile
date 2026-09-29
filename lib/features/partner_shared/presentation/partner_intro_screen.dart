import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_button.dart';
import '../../../design/widgets/hm_slide.dart';
import '../../../routing/routes.dart';
import '../../roles/data/app_role.dart';

/// The partner intro has been seen (or closed) this session, so the home
/// stops sending the person back to it.
final partnerIntroSeenProvider = StateProvider<Set<AppRole>>((_) => const {});

/// One intro slide.
typedef IntroSlide = ({IconData icon, String title, String body});

/// BRK-001a–c / LND-001a–c: three slides, then the setup.
class PartnerIntroScreen extends ConsumerStatefulWidget {
  const PartnerIntroScreen({super.key, required this.role, required this.slides, required this.startLabel});

  final AppRole role;
  final List<IntroSlide> slides;
  final String startLabel;

  @override
  ConsumerState<PartnerIntroScreen> createState() => _PartnerIntroScreenState();
}

class _PartnerIntroScreenState extends ConsumerState<PartnerIntroScreen> {
  final _pages = PageController();
  int _page = 0;

  bool get _isLast => _page == widget.slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _leave(String location) {
    ref.read(partnerIntroSeenProvider.notifier).update((seen) => {...seen, widget.role});
    context.go(location);
  }

  void _next() {
    if (_isLast) {
      _leave(Routes.partnerSetup(widget.role));
    } else {
      _pages.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final home = widget.role == AppRole.broker ? Routes.brokerHome : Routes.landlordHome;
    return Scaffold(
      backgroundColor: HmColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(HmSpace.md),
              child: Row(
                children: [
                  IconButton(
                    tooltip: text.close,
                    onPressed: () => _leave(home),
                    icon: const Icon(Icons.close_rounded, color: HmColors.textPrimary),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => _leave(Routes.partnerSetup(widget.role)), child: Text(text.skip)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final slide in widget.slides) HmSlide(icon: slide.icon, title: slide.title, body: slide.body),
                ],
              ),
            ),
            HmPageDots(count: widget.slides.length, index: _page),
            Padding(
              padding: const EdgeInsets.all(HmSpace.huge),
              child: HmButton(label: _isLast ? widget.startLabel : text.next, onPressed: _next),
            ),
          ],
        ),
      ),
    );
  }
}
