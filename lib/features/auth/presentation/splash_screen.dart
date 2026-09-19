import 'package:flutter/material.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/tokens.dart';

/// CUS-001a. Shown only while the stored session is being read, so it is
/// deliberately static — a spinner that appears for 80ms is worse than none.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HmColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _BrandMark(),
            const SizedBox(height: HmSpace.huge),
            Text('HomeMate', style: HmText.display),
            const SizedBox(height: HmSpace.xs),
            Text('AFRICA', style: HmText.caption),
            const SizedBox(height: HmSpace.section),
            Text(context.text.splashTagline, style: HmText.body),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: HmColors.brandPrimary,
          borderRadius: BorderRadius.circular(HmRadius.huge),
        ),
        child: const Icon(Icons.home_rounded, size: 48, color: HmColors.textOnBrand),
      );
}
