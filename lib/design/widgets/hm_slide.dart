import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Onboarding/Slide's middle: the art, a title and a sentence. The
/// customer intro and the broker and landlord intros are pages of these.
class HmSlide extends StatelessWidget {
  const HmSlide({super.key, required this.icon, required this.title, required this.body});

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

/// The page dots under a run of slides; the current one is drawn long.
class HmPageDots extends StatelessWidget {
  const HmPageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: HmSpace.xs),
              constraints: BoxConstraints.tightFor(width: i == index ? 22 : 8, height: 8),
              decoration: BoxDecoration(
                color: i == index ? HmColors.brandPrimary : HmColors.borderStrong,
                borderRadius: BorderRadius.circular(HmRadius.pill),
              ),
            ),
        ],
      );
}
