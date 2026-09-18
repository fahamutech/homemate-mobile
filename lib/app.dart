import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'design/theme.dart';
import 'routing/app_router.dart';

/// The application widget.
///
/// It does two things: restore the session once, and hand the router and theme
/// to Material. Everything else belongs to a feature.
class HomeMateApp extends ConsumerStatefulWidget {
  const HomeMateApp({super.key});

  @override
  ConsumerState<HomeMateApp> createState() => _HomeMateAppState();
}

class _HomeMateAppState extends ConsumerState<HomeMateApp> {
  @override
  void initState() {
    super.initState();
    // After the first frame: restoring touches storage and the network, and
    // the splash should already be on screen while it happens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HomeMate Africa',
      debugShowCheckedModeBanner: false,
      theme: buildHomeMateTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
