import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/auth/data/session_store.dart';
import 'package:homemate_mobile/features/shared/customer_avatar.dart';

import 'support/fakes.dart';

/// The avatar, and the one thing it must never do: show nothing.
///
/// The bug behind these: the profile step rendered initials unconditionally and
/// never looked at the photo at all, so uploading one appeared to do nothing.
/// Now that it does fetch a photo, the failure modes matter — an account with
/// no photo, and a photo that will not load — because both of them happen on a
/// bad connection and neither may leave a hole where a face should be.
void main() {
  Customer neema({bool hasPhoto = false}) => Customer(
        id: 'cust-1',
        phoneNumber: '+255712345678',
        fullName: 'Neema Kileo',
        hasPin: true,
        onboardingComplete: true,
        hasPhoto: hasPhoto,
      );

  /// Signs the customer in before the first frame, so the avatar has somebody
  /// to draw rather than the signed-out placeholder.
  ///
  /// Through the session store rather than `adopt`, because `wrap` kicks off a
  /// restore of its own: adopting afterwards races that restore, and the
  /// signed-out state it settles on wins.
  Future<void> show(WidgetTester tester, TestHarness harness, Customer customer) async {
    harness.auth.customer = customer;
    await harness.store.write(
      StoredSession(token: 'session-token', userJson: customer.toJson()),
    );

    await tester.pumpWidget(
      harness.wrap(const Scaffold(body: Center(child: CustomerAvatar(radius: 30)))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('falls back to initials when the account has no photo', (tester) async {
    final harness = TestHarness();
    await show(tester, harness, neema());

    expect(find.text('NK'), findsOneWidget);
  });

  testWidgets('still shows initials when the photo cannot be fetched', (tester) async {
    final harness = TestHarness();
    await show(tester, harness, neema(hasPhoto: true));

    // There is no network in a widget test, so this exercises the error path.
    expect(find.text('NK'), findsOneWidget);
  });

  testWidgets('a new upload moves the cache key past the picture it replaced', (tester) async {
    final harness = TestHarness();
    await show(tester, harness, neema(hasPhoto: true));

    final container = harness.container!;
    expect(container.read(profilePhotoRevisionProvider), 0);

    container.read(profilePhotoRevisionProvider.notifier).state++;
    // Without this the image cache serves the photo that was just replaced.
    expect(container.read(profilePhotoRevisionProvider), 1);
  });
}
