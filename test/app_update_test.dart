import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/app_update/app_update_banner.dart';
import 'package:homemate_mobile/core/app_update/app_update_controller.dart';
import 'package:homemate_mobile/core/app_update/app_updater.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/theme.dart';

/// Play's side of the flexible flow, scripted: what a check reports, and
/// what each tap moves it to.
class FakeUpdater extends AppUpdater {
  FakeUpdater(this.onCheck);

  AppUpdateStatus onCheck;
  final applied = <AppUpdateStatus>[];
  final _changes = StreamController<AppUpdateStatus>.broadcast();
  int checks = 0;

  void emit(AppUpdateStatus status) => _changes.add(status);

  @override
  Stream<AppUpdateStatus> get changes => _changes.stream;

  @override
  Future<AppUpdateStatus> check() async {
    checks++;
    return onCheck;
  }

  @override
  Future<AppUpdateStatus> apply(AppUpdateStatus status) async {
    applied.add(status);
    return switch (status) {
      AppUpdateStatus.available => AppUpdateStatus.ready,
      AppUpdateStatus.ready => AppUpdateStatus.none,
      _ => status,
    };
  }

  @override
  void dispose() => _changes.close();
}

Widget _app(FakeUpdater updater) => ProviderScope(
      overrides: [appUpdaterProvider.overrideWithValue(updater)],
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
        builder: (context, child) => AppUpdateBanner(child: child!),
        home: const Scaffold(body: Text('Home')),
      ),
    );

void main() {
  group('isNewerBuild', () {
    test('only a strictly higher deployed number is newer', () {
      expect(isNewerBuild({'build_number': '105'}, 104), isTrue);
      expect(isNewerBuild({'build_number': 105}, 104), isTrue);
      expect(isNewerBuild({'build_number': '104'}, 104), isFalse);
      expect(isNewerBuild({'build_number': '103'}, 104), isFalse);
    });

    test('a local build or a broken file never asks for a reload', () {
      expect(isNewerBuild({'build_number': '999'}, 0), isFalse);
      expect(isNewerBuild({'build_number': 'abc'}, 104), isFalse);
      expect(isNewerBuild({'version': '1.1.0'}, 104), isFalse);
      expect(isNewerBuild('<!doctype html>', 104), isFalse);
      expect(isNewerBuild(null, 104), isFalse);
    });
  });

  testWidgets('nothing shows while the app is current', (tester) async {
    await tester.pumpWidget(_app(FakeUpdater(AppUpdateStatus.none)));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.system_update_outlined), findsNothing);
  });

  testWidgets('offers the update, downloads it, then offers the restart', (tester) async {
    final updater = FakeUpdater(AppUpdateStatus.available);
    await tester.pumpWidget(_app(updater));
    await tester.pumpAndSettle();

    expect(find.text('A new version of HomeMate is available.'), findsOneWidget);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(updater.applied, [AppUpdateStatus.available]);
    expect(find.text('The new version is ready.'), findsOneWidget);
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();

    expect(updater.applied, [AppUpdateStatus.available, AppUpdateStatus.ready]);
  });

  testWidgets('shows progress while Play downloads', (tester) async {
    final updater = FakeUpdater(AppUpdateStatus.none);
    await tester.pumpWidget(_app(updater));
    await tester.pumpAndSettle();

    updater.emit(AppUpdateStatus.downloading);
    await tester.pump();
    await tester.pump();

    expect(find.text('Downloading the new version…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('closing hides that offer, but a finished download comes back', (tester) async {
    final updater = FakeUpdater(AppUpdateStatus.available);
    await tester.pumpWidget(_app(updater));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.system_update_outlined), findsNothing);

    updater.emit(AppUpdateStatus.ready);
    await tester.pump();
    await tester.pump();
    expect(find.text('The new version is ready.'), findsOneWidget);
  });

  testWidgets('checks again when the app returns to the foreground', (tester) async {
    final updater = FakeUpdater(AppUpdateStatus.none);
    await tester.pumpWidget(_app(updater));
    await tester.pumpAndSettle();
    final before = updater.checks;

    updater.onCheck = AppUpdateStatus.available;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(updater.checks, greaterThan(before));
    expect(find.text('A new version of HomeMate is available.'), findsOneWidget);
  });
}
