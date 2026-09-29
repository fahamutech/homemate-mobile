import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_document_card.dart';
import '../../../shared/models.dart';
import 'document_slot.dart';
import 'document_upload.dart';

/// HmDocumentCard for one slot: its state as a badge, and the button that
/// takes or uploads it while it is still wanted.
class DocumentSlotCard extends ConsumerStatefulWidget {
  const DocumentSlotCard({super.key, required this.slot, required this.identity, this.optional = false});

  final DocumentSlot slot;
  final IdentityStatus identity;
  final bool optional;

  @override
  ConsumerState<DocumentSlotCard> createState() => _DocumentSlotCardState();
}

class _DocumentSlotCardState extends ConsumerState<DocumentSlotCard> {
  bool _busy = false;

  Future<void> _upload() async {
    setState(() => _busy = true);
    await uploadPartnerDocument(context, ref, widget.slot);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final state = documentState(widget.identity, widget.slot);
    final badge = switch (state) {
      'verified' => HmBadge(label: text.partnerDocVerified, tone: HmBadgeTone.success),
      'pending' => HmBadge(label: text.partnerDocInReview, tone: HmBadgeTone.info),
      'rejected' => HmBadge(label: text.partnerDocRejected, tone: HmBadgeTone.error),
      _ => widget.optional
          ? HmBadge(label: text.optional)
          : HmBadge(label: text.partnerDocNeeded, tone: HmBadgeTone.warning),
    };
    final wanted = state == 'missing' || state == 'rejected';

    return HmDocumentCard(
      key: ValueKey('document-${widget.slot.name}'),
      icon: widget.slot.icon,
      title: widget.slot.title(text),
      description: widget.slot.body(text),
      status: badge,
      actionLabel: !wanted
          ? null
          : widget.slot.camera
              ? text.partnerDocTakePhoto
              : text.partnerDocUpload,
      actionIcon: widget.slot.camera ? Icons.photo_camera_outlined : Icons.upload_rounded,
      busy: _busy,
      onAction: _upload,
    );
  }
}
