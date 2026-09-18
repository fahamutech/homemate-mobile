import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../routing/app_router.dart';
import '../../discovery/data/search_providers.dart';
import '../../shared/property_card.dart';

/// CUS-013a. The properties the customer kept.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPropertiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(savedPropertiesProvider),
        child: HmAsync(
          value: saved,
          onRetry: () => ref.invalidate(savedPropertiesProvider),
          emptyWhen: (page) => page.isEmpty,
          empty: HmEmpty(
            title: 'Nothing saved yet',
            message: 'Tap the heart on a listing to keep it here for later.',
            icon: Icons.favorite_outline,
            action: OutlinedButton(
              onPressed: () => context.go(Routes.search),
              child: const Text('Browse homes'),
            ),
          ),
          data: (page) => ListView.separated(
            padding: const EdgeInsets.all(HmSpace.xxl),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: HmSpace.xxl),
            itemBuilder: (_, index) => PropertyCard(
              // Everything here is saved by definition, whatever the search
              // response happened to say.
              property: page.items[index].copyWith(isSaved: true),
              onSavedChanged: (saved) {
                if (!saved) {
                  ref.invalidate(savedPropertiesProvider);
                  ref.invalidate(activitySummaryProvider);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
