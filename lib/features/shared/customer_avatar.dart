import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/providers.dart';
import '../../design/tokens.dart';

/// Bumped whenever a new photo is uploaded.
///
/// The photo lives at one fixed URL, so without this the image cache would go
/// on serving the picture somebody has just replaced — the upload succeeds, the
/// screen does not change, and it looks like nothing happened.
final profilePhotoRevisionProvider = StateProvider<int>((ref) => 0);

/// The customer's own face, or their initials until they have given us one.
///
/// Same rule as [PropertyImage]: the photo comes through the API with the
/// session on the request, because object storage needs credentials the app
/// must not hold and a token in a URL ends up in logs and caches.
class CustomerAvatar extends ConsumerWidget {
  const CustomerAvatar({super.key, required this.radius, this.fontSize});

  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(currentCustomerProvider);
    final initials = customer?.initials ?? '#';

    final fallback = _Initials(initials: initials, radius: radius, fontSize: fontSize);
    if (customer?.hasPhoto != true) return fallback;

    final token = ref.watch(authControllerProvider.notifier).token;
    final revision = ref.watch(profilePhotoRevisionProvider);

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: '${Env.apiBaseUrl}/app/me/photo/raw?thumbnail=1',
        cacheKey: 'me-photo-$revision',
        httpHeaders: {if (token != null) 'authorization': 'Bearer $token'},
        // See PropertyImage: web's default <img>-tag loader drops this header.
        imageRenderMethodForWeb:
            kIsWeb ? ImageRenderMethodForWeb.HttpGet : ImageRenderMethodForWeb.HtmlImage,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        // A photo that will not load must still leave a usable avatar rather
        // than a broken-image box where a face should be.
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.radius, this.fontSize});

  final String initials;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: HmColors.brandPrimarySoft,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize ?? radius * 0.64,
            fontWeight: FontWeight.w700,
            color: HmColors.brandPrimary,
          ),
        ),
      );
}
