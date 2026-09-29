import 'package:flutter/material.dart';

import '../../shared/property_image.dart';

/// The media id in `/app/media/<id>/raw`, the form the partner API links
/// photos in.
String? mediaIdFromUrl(String? url) => url == null ? null : RegExp(r'/app/media/([^/?]+)').firstMatch(url)?.group(1);

/// A listing photo from a partner API link, through the authenticated loader.
class PartnerPhoto extends StatelessWidget {
  const PartnerPhoto({super.key, required this.url, this.radius = 10});

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      PropertyImage(mediaId: mediaIdFromUrl(url), borderRadius: BorderRadius.circular(radius));
}
