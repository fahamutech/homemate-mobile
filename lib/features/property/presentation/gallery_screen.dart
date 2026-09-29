import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../discovery/data/search_providers.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../../../core/i18n/app_text.dart';

/// CUS-005b. Every photo of one listing, full bleed.
///
/// It is a route rather than a dialog so the back gesture, the system back
/// button and a deep link all behave: a customer three photos deep expects
/// "back" to leave the gallery, not the app.
///
/// Dark by deliberate exception to the app's light surfaces — a photograph is
/// judged against its surroundings, and a white page beside a dim interior
/// shot makes the room look worse than it is.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key, required this.propertyId, this.initialIndex = 0});

  final String propertyId;
  final int initialIndex;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _show(int index) {
    setState(() => _index = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(propertyDetailProvider(widget.propertyId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The status bar sits on black here, so its icons have to flip.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: HmAsync(
          value: detail,
          onRetry: () => ref.invalidate(propertyDetailProvider(widget.propertyId)),
          data: (property) {
            final media = property.media;
            if (media.isEmpty) {
              return Center(
                child: Text(
                  context.text.galleryEmpty,
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return SafeArea(
              child: Column(
                children: [
                  _Header(
                    index: _index,
                    total: media.length,
                    title: property.summary.title,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: media.length,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (_, position) => _ZoomableImage(
                        mediaId: media[position].id,
                        caption: media[position].caption,
                      ),
                    ),
                  ),
                  _Thumbnails(
                    media: media,
                    index: _index,
                    onSelected: _show,
                  ),
                  const SizedBox(height: HmSpace.xxl),
                  const _Hint(),
                  const SizedBox(height: HmSpace.huge),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.title,
    required this.onClose,
  });

  final int index;
  final int total;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl, vertical: HmSpace.md),
        child: Row(
          children: [
            _RoundButton(icon: Icons.close, tooltip: context.text.galleryClose, onPressed: onClose),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${index + 1} / $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: HmSpace.xxs),
                  Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            // Balances the close button so the counter stays centred.
            const SizedBox(width: 40),
          ],
        ),
      );
}

/// One photo, pinch- and double-tap-zoomable.
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.mediaId, this.caption});

  final String mediaId;
  final String? caption;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Double tap toggles between fit and 2.5×, centred on the tap — the
  /// gesture everyone already knows from their phone's photo app.
  void _toggleZoom(TapDownDetails details) {
    if (_transform.value != Matrix4.identity()) {
      _transform.value = Matrix4.identity();
      return;
    }
    final position = details.localPosition;
    _transform.value = Matrix4.identity()
      ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0, 1)
      ..scaleByDouble(2.5, 2.5, 2.5, 1);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: GestureDetector(
              onDoubleTapDown: _toggleZoom,
              onDoubleTap: () {},
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: PropertyImage(
                    mediaId: widget.mediaId,
                    thumbnail: false,
                    fit: BoxFit.contain,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ),
          if ((widget.caption ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(HmSpace.huge, HmSpace.xxl, HmSpace.huge, 0),
              child: Text(
                widget.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      );
}

class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.media, required this.index, required this.onSelected});

  final List<PropertyMedia> media;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl),
          itemCount: media.length,
          separatorBuilder: (_, __) => const SizedBox(width: HmSpace.md),
          itemBuilder: (_, position) {
            final selected = position == index;
            return Semantics(
              button: true,
              selected: selected,
              label: context.text.galleryPhotoOf(position + 1, media.length),
              child: GestureDetector(
                onTap: () => onSelected(position),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(HmRadius.sm),
                    border: Border.all(
                      color: selected ? HmColors.brandPrimary : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(HmRadius.sm - 2),
                    child: PropertyImage(
                      mediaId: media[position].id,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl, vertical: HmSpace.md),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(HmRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.zoom_out_map, size: 15, color: Colors.white70),
              SizedBox(width: HmSpace.md),
              Text(context.text.galleryPinch, style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white24,
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      );
}
