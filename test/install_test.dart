import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/core/pwa/install_controller.dart';
import 'package:homemate_mobile/core/pwa/install_prompt.dart';
import 'package:homemate_mobile/core/pwa/install_widgets.dart';
import 'package:homemate_mobile/design/theme.dart';

class FakeInstallPrompt extends InstallPrompt {
  FakeInstallPrompt(this.method, {this.accepts = true});

  @override
  InstallMethod method;
  final bool accepts;
  int prompts = 0;

  @override
  Future<bool> prompt() async {
    prompts++;
    if (accepts) method = InstallMethod.none;
    return accepts;
  }
}

class InMemoryDismissalStore implements InstallDismissalStore {
  InMemoryDismissalStore([this.at]);

  DateTime? at;

  @override
  Future<DateTime?> read() async => at;

  @override
  Future<void> write(DateTime value) async => at = value;
}

Widget _app(InstallPrompt prompt, InstallDismissalStore store) => ProviderScope(
      overrides: [
        installPromptProvider.overrideWithValue(prompt),
        installDismissalStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        theme: buildHomeMateTheme(),
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('sw')],
        localizationsDelegates: const [
          AppTextDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: InstallAppCard())),
      ),
    );

void main() {
  testWidgets('a native build or an installed PWA shows no card', (tester) async {
    await tester.pumpWidget(_app(FakeInstallPrompt(InstallMethod.none), InMemoryDismissalStore()));
    await tester.pumpAndSettle();

    expect(find.text('Install HomeMate'), findsNothing);
  });

  testWidgets('Chrome: Install opens the browser dialog and the card goes', (tester) async {
    final prompt = FakeInstallPrompt(InstallMethod.prompt);
    await tester.pumpWidget(_app(prompt, InMemoryDismissalStore()));
    await tester.pumpAndSettle();

    expect(find.text('Install HomeMate'), findsOneWidget);
    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();

    expect(prompt.prompts, 1);
    expect(find.text('HomeMate is on your home screen.'), findsOneWidget);
    expect(find.text('Install HomeMate'), findsNothing);
  });

  testWidgets('iPhone: Install explains Share, then Add to Home Screen', (tester) async {
    final prompt = FakeInstallPrompt(InstallMethod.iosShareSheet);
    await tester.pumpWidget(_app(prompt, InMemoryDismissalStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();

    expect(prompt.prompts, 0);
    expect(find.text('Add HomeMate to your Home Screen'), findsOneWidget);
    expect(find.textContaining('Share button'), findsOneWidget);
    expect(find.textContaining('Add to Home Screen'), findsWidgets);
  });

  testWidgets('Not now hides the card and is remembered', (tester) async {
    final store = InMemoryDismissalStore();
    await tester.pumpWidget(_app(FakeInstallPrompt(InstallMethod.prompt), store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Install HomeMate'), findsNothing);
    expect(store.at, isNotNull);
  });

  testWidgets('stays quiet for a fortnight after Not now', (tester) async {
    final recent = DateTime.now().subtract(const Duration(days: 3));
    await tester.pumpWidget(
      _app(FakeInstallPrompt(InstallMethod.prompt), InMemoryDismissalStore(recent)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Install HomeMate'), findsNothing);
  });

  testWidgets('asks once more after the quiet period', (tester) async {
    final old = DateTime.now().subtract(const Duration(days: 15));
    await tester.pumpWidget(
      _app(FakeInstallPrompt(InstallMethod.browserMenu), InMemoryDismissalStore(old)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Install HomeMate'), findsOneWidget);
  });
}
