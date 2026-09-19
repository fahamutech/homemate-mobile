import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens.dart';
import 'app_locale.dart';
import 'app_text.dart';
import 'locale_controller.dart';

/// The one language control in the app, reached from two places: the onboarding
/// flow, before anyone has read a word of English, and the home screen's top
/// bar afterwards.
Future<void> showLanguagePicker(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: HmRadius.sheet),
      builder: (_) => const _LanguageSheet(),
    );

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(localeProvider);
    final text = context.text;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(HmSpace.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text.languageSheetTitle, style: HmText.heading),
            const SizedBox(height: HmSpace.md),
            Text(text.languageSheetMessage, style: HmText.caption),
            const SizedBox(height: HmSpace.xxl),
            RadioGroup<AppLocale>(
              groupValue: selected,
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(localeProvider.notifier).select(value);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final locale in AppLocale.values)
                    RadioListTile<AppLocale>(
                      value: locale,
                      contentPadding: EdgeInsets.zero,
                      activeColor: HmColors.brandPrimary,
                      // The endonym leads, because the person who needs this
                      // row is the one who cannot read the other column.
                      title: Text(locale.endonym, style: HmText.body),
                      subtitle: locale == selected
                          ? Text(text.currentLanguage, style: HmText.caption)
                          : null,
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

/// The top-bar control: the same affordance as the notification bell, so the
/// two read as a pair.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return IconButton(
      onPressed: () => showLanguagePicker(context),
      tooltip: context.text.languageTooltip,
      // The current language is named on the button, not hidden behind it: a
      // bare globe icon tells you there is a language setting but not which
      // language you are already in.
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language_outlined),
          const SizedBox(width: HmSpace.xxs),
          Text(
            locale.code.toUpperCase(),
            style: HmText.label.copyWith(fontSize: 11, color: HmColors.brandPrimary),
          ),
        ],
      ),
    );
  }
}
