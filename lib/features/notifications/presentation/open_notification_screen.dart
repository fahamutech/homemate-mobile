import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../routing/routes.dart';
import '../../roles/data/app_role.dart';
import '../../shared/models.dart';
import '../data/notification_providers.dart';
import 'notifications_screen.dart';

/// Where a tapped push lands (`/open-notification?…`, the data the backend
/// put on it). For a moment: it marks the notice read, switches to the role
/// it is for when the person holds that role, and opens the screen it is about
/// over that role's inbox — so Back goes to the inbox, not out of the app.
class OpenNotificationScreen extends ConsumerStatefulWidget {
  const OpenNotificationScreen({super.key, required this.data});

  final Map<String, String> data;

  @override
  ConsumerState<OpenNotificationScreen> createState() => _OpenNotificationScreenState();
}

class _OpenNotificationScreenState extends ConsumerState<OpenNotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  String? _field(String key) {
    final value = widget.data[key];
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _open() async {
    final id = _field('notificationId');
    if (id != null) {
      // Fire and forget: failing to mark it read must not block opening it.
      ref.read(activityRepositoryProvider).markNotificationRead(id).catchError((Object _) {});
    }

    final roles = ref.read(roleControllerProvider);
    var role = roles.current ?? AppRole.customer;
    final audience = AppRole.fromName(_field('audience'));
    if (audience != null && audience != role && roles.switchable.contains(audience)) {
      try {
        await ref.read(roleControllerProvider.notifier).open(audience);
        role = audience;
      } catch (_) {
        // Stay in the role in use; its inbox still has the notice.
      }
    }

    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(activitySummaryProvider);
    if (!mounted) return;

    final inbox = role == AppRole.customer ? '${Routes.home}/notifications' : Routes.partnerNotifications(role);
    final destination = notificationDestination(
      AppNotification(
        id: id ?? '',
        title: '',
        kind: _field('kind') ?? 'system',
        createdAt: DateTime.now(),
        subjectTable: _field('subjectTable'),
        subjectId: _field('subjectId'),
        audience: _field('audience'),
      ),
      role,
    );

    final router = GoRouter.of(context);
    router.go(inbox);
    if (destination != null) router.push(destination);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: HmColors.brandPrimary),
              const SizedBox(height: HmSpace.xl),
              Text(context.text.notificationsOpening, style: HmText.body),
            ],
          ),
        ),
      );
}
