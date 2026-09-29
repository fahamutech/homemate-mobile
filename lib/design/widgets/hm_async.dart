import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../tokens.dart';
import '../../core/i18n/app_text.dart';
import '../../core/network/error_text.dart';

/// Loading, empty, error and content — the four states every fetched screen
/// has, written once.
///
/// Without this each screen invents its own spinner and its own error text,
/// and the ones nobody exercised in review end up showing a raw exception.
class HmAsync<T> extends StatelessWidget {
  const HmAsync({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.emptyWhen,
    this.empty,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Lets a list say "this counts as empty" without this widget knowing what
  /// kind of collection it is holding.
  final bool Function(T data)? emptyWhen;
  final Widget? empty;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? const HmLoading(),
      error: (error, _) => HmErrorView(error: error, onRetry: onRetry),
      data: (loaded) {
        if (emptyWhen?.call(loaded) == true) {
          return empty ?? HmEmpty(title: context.text.commonNothingYet);
        }
        return data(loaded);
      },
    );
  }
}

class HmLoading extends StatelessWidget {
  const HmLoading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (label != null) ...[
              const SizedBox(height: HmSpace.xxl),
              Text(label!, style: HmText.caption),
            ],
          ],
        ),
      );
}

/// What went wrong, in the words the backend chose, plus a way out.
class HmErrorView extends StatelessWidget {
  const HmErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;
    // An unexpected exception is a bug; showing its toString to a customer
    // helps nobody, so it becomes the generic sentence instead.
    final message = errorText(context.text, error);
    final canRetry = onRetry != null && (api == null || api.isTransient || api.isRateLimited);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(HmSpace.huge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              api?.isRateLimited == true ? Icons.timer_outlined : Icons.cloud_off_rounded,
              size: 40,
              color: HmColors.textDisabled,
            ),
            const SizedBox(height: HmSpace.xxl),
            Text(message, textAlign: TextAlign.center, style: HmText.body),
            if (canRetry) ...[
              const SizedBox(height: HmSpace.huge),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.text.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An empty state that says what to do next, not just that there is nothing.
class HmEmpty extends StatelessWidget {
  const HmEmpty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.huge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: HmColors.textDisabled),
              const SizedBox(height: HmSpace.xxl),
              Text(title, style: HmText.heading, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: HmSpace.md),
                Text(message!, style: HmText.caption, textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: HmSpace.huge),
                action!,
              ],
            ],
          ),
        ),
      );
}
