import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';

/// A listing photo.
///
/// Object storage needs credentials the app must not hold, so images come
/// through the API with the session attached. That means the token has to
/// travel as a header, never in the URL — a URL ends up in logs, caches and
/// browser history.
class PropertyImage extends ConsumerWidget {
  const PropertyImage({
    super.key,
    required this.mediaId,
    this.thumbnail = true,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? mediaId;
  final bool thumbnail;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = borderRadius ?? HmRadius.card;
    if (mediaId == null || mediaId!.isEmpty) {
      return _Placeholder(height: height, width: width, borderRadius: radius);
    }

    final token = ref.watch(authControllerProvider.notifier).token;
    final url = ref.watch(catalogueRepositoryProvider).imageUrl(mediaId!, thumbnail: thumbnail);

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: {if (token != null) 'authorization': 'Bearer $token'},
        height: height,
        width: width ?? double.infinity,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => _Placeholder(height: height, width: width, borderRadius: radius),
        errorWidget: (_, __, ___) =>
            _Placeholder(height: height, width: width, borderRadius: radius, failed: true),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.height, this.width, this.borderRadius, this.failed = false});

  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool failed;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: HmColors.surfaceInput,
          borderRadius: borderRadius ?? HmRadius.card,
        ),
        child: Icon(
          failed ? Icons.image_not_supported_outlined : Icons.home_work_outlined,
          color: HmColors.textDisabled,
          size: 28,
        ),
      );
}
