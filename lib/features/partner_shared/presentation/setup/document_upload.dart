import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/widgets/hm_feedback.dart';
import '../../data/partner_providers.dart';
import 'document_slot.dart';

/// Takes or picks a document and sends it. True when one was sent; the
/// person's identity and applications are re-read either way.
Future<bool> uploadPartnerDocument(BuildContext context, WidgetRef ref, DocumentSlot slot) async {
  final text = context.text;
  try {
    final photo = await ref.read(photoSourceProvider).pick(camera: slot.camera);
    if (photo == null) return false;
    await ref.read(identityRepositoryProvider).uploadDocument(
          documentType: slot.uploadType,
          bytes: photo.bytes,
          contentType: photo.contentType,
          filename: photo.name,
        );
    if (context.mounted) HmFeedback.success(context, text.partnerDocSent(slot.title(text)));
    return true;
  } catch (error) {
    if (context.mounted) HmFeedback.failure(context, error);
    return false;
  } finally {
    ref.invalidate(identityStatusProvider);
    ref.invalidate(applicationsProvider);
  }
}
