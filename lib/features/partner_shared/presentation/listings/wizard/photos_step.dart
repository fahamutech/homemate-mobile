import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../core/providers.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_feedback.dart';
import '../../../../../design/widgets/hm_note.dart';
import '../../../data/partner_listing.dart';
import '../../partner_photo.dart';
import 'photo_order.dart';

/// BRK-030f: photos go up as soon as they are picked (made WebP and resized
/// first); the first is the cover. Tapping one makes it the cover, moves it,
/// or removes it.
class PhotosStep extends ConsumerStatefulWidget {
  const PhotosStep({super.key, required this.listing, required this.onChanged});

  final PartnerListing listing;
  final ValueChanged<PartnerListing> onChanged;

  @override
  ConsumerState<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends ConsumerState<PhotosStep> {
  int _uploading = 0;
  int _uploaded = 0;

  List<ListingPhoto> get _photos => widget.listing.photos;

  Future<void> _add() async {
    final picked = await ref.read(photoSourceProvider).pickMany();
    if (picked.isEmpty) return;
    setState(() {
      _uploading = picked.length;
      _uploaded = 0;
    });
    final repository = ref.read(listingsRepositoryProvider);
    final encoder = ref.read(webpEncoderProvider);
    try {
      var listing = widget.listing;
      for (final photo in picked) {
        final webp = await encoder.encode(photo.bytes);
        listing = await repository.addPhoto(listing.id, PhotoUpload(bytes: webp, name: '${photo.name.split('.').first}.webp'));
        if (!mounted) return;
        setState(() => _uploaded++);
        widget.onChanged(listing);
      }
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _uploading = 0);
    }
  }

  Future<void> _reorder(List<String> order) async {
    try {
      widget.onChanged(await ref.read(listingsRepositoryProvider).update(widget.listing.id, {'photoOrder': order}));
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    }
  }

  Future<void> _remove(String mediaId) async {
    try {
      widget.onChanged(await ref.read(listingsRepositoryProvider).removePhoto(widget.listing.id, mediaId));
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    }
  }

  Future<void> _options(int index) async {
    final text = context.text;
    final ids = [for (final p in _photos) p.id];
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              ListTile(leading: const Icon(Icons.star_outline_rounded), title: Text(text.wizardPhotosMakeCover), onTap: () => Navigator.pop(context, 'cover')),
            if (index > 0)
              ListTile(leading: const Icon(Icons.arrow_back_rounded), title: Text(text.wizardPhotosEarlier), onTap: () => Navigator.pop(context, 'earlier')),
            if (index < ids.length - 1)
              ListTile(leading: const Icon(Icons.arrow_forward_rounded), title: Text(text.wizardPhotosLater), onTap: () => Navigator.pop(context, 'later')),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: HmColors.error),
              title: Text(text.wizardPhotosRemove, style: const TextStyle(color: HmColors.error)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    switch (choice) {
      case 'cover':
        await _reorder(movePhoto(ids, index, 0));
      case 'earlier':
        await _reorder(movePhoto(ids, index, index - 1));
      case 'later':
        await _reorder(movePhoto(ids, index, index + 1));
      case 'remove':
        await _remove(ids[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return ListView(
      padding: const EdgeInsets.all(HmSpace.xxl),
      children: [
        Text(text.wizardPhotosTitle, style: HmText.title),
        const SizedBox(height: HmSpace.md),
        Text(text.wizardPhotosBody, style: HmText.body),
        const SizedBox(height: HmSpace.xxl),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: HmSpace.md,
          crossAxisSpacing: HmSpace.md,
          children: [
            for (final (index, photo) in _photos.indexed)
              GestureDetector(
                key: ValueKey('photo-${photo.id}'),
                onTap: () => _options(index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PartnerPhoto(url: photo.thumbnailUrl ?? photo.url ?? '/app/media/${photo.id}/raw'),
                    if (index == 0)
                      Positioned(
                        left: HmSpace.sm,
                        top: HmSpace.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: HmSpace.md, vertical: HmSpace.xxs),
                          decoration: BoxDecoration(color: HmColors.bgPrimary, borderRadius: BorderRadius.circular(HmRadius.pill)),
                          child: Text(text.wizardPhotosCover, style: HmText.label.copyWith(fontSize: 12, color: HmColors.brandPrimary)),
                        ),
                      ),
                  ],
                ),
              ),
            InkWell(
              onTap: _uploading > 0 ? null : _add,
              borderRadius: BorderRadius.circular(HmRadius.lg - 6),
              child: Container(
                decoration: BoxDecoration(
                  color: HmColors.brandSubtle,
                  borderRadius: BorderRadius.circular(HmRadius.lg - 6),
                  border: Border.all(color: HmColors.brandPrimary),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: HmColors.brandPrimary),
                    const SizedBox(height: HmSpace.xs),
                    Text(text.wizardPhotosAdd, style: HmText.label.copyWith(fontSize: 12, color: HmColors.brandPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_uploading > 0) ...[
          const SizedBox(height: HmSpace.xxl),
          Text(text.wizardPhotosUploading(_uploaded, _uploading), style: HmText.label),
          const SizedBox(height: HmSpace.sm),
          LinearProgressIndicator(value: _uploading == 0 ? null : _uploaded / _uploading, color: HmColors.brandPrimary),
        ],
        const SizedBox(height: HmSpace.xxl),
        HmNote(text: text.wizardPhotosHint, icon: Icons.touch_app_outlined),
      ],
    );
  }
}
