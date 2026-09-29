import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_text.dart';
import '../../core/i18n/language_picker.dart';
import '../../design/tokens.dart';
import '../../design/widgets/hm_top_bar.dart';
import 'catalogue_sections.dart';

/// Every shared widget in every state (`/dev/widgets`, debug builds only).
///
/// The language button switches the whole page, so the Kiswahili build can
/// be checked for overflow as easily as the English one.
class WidgetCatalogueScreen extends StatelessWidget {
  const WidgetCatalogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Scaffold(
      backgroundColor: HmColors.bgSecondary,
      appBar: HmTopBar(
        title: text.devWidgetsTitle,
        onBack: context.canPop() ? () => context.pop() : null,
        backTooltip: text.back,
        actions: const [LanguageButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(HmSpace.xxl),
        children: [
          CatalogueSection(title: text.devWidgetsButtons, children: buttonSamples(text)),
          CatalogueSection(title: text.devWidgetsBadges, children: badgeSamples(text)),
          CatalogueSection(title: text.devWidgetsForms, children: const [FormSamples()]),
          CatalogueSection(title: text.devWidgetsFeedback, children: noteSamples(text)),
          CatalogueSection(title: text.devWidgetsData, children: dataSamples(text)),
          CatalogueSection(title: text.devWidgetsPartner, children: partnerSamples(text)),
          CatalogueSection(title: text.devWidgetsTimeline, children: timelineSamples(text)),
          CatalogueSection(title: text.devWidgetsNavigation, children: navigationSamples(text)),
          CatalogueSection(title: text.devWidgetsOnboarding, children: onboardingSamples(text)),
        ],
      ),
    );
  }
}
