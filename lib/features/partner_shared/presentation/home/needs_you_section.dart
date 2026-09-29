import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_attention_row.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_money.dart';
import 'needs_you.dart';

/// "Needs you": the server's attention items, each opening what it is about.
class NeedsYouSection extends StatelessWidget {
  const NeedsYouSection({super.key, required this.role, required this.items});

  final AppRole role;
  final List<NeedsYouItem> items;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HmSectionHeader(title: text.partnerHomeNeedsYou, trailingText: items.isEmpty ? null : '${items.length}'),
        if (items.isEmpty)
          Text(text.partnerHomeNothing, style: HmText.caption.copyWith(fontSize: 13))
        else
          HmCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (index, item) in items.indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  Builder(builder: (context) {
                    final style = needsYouStyle(item.kind);
                    final target = needsYouTarget(role, item.kind, item.targetId);
                    return HmAttentionRow(
                      icon: style.icon,
                      tone: style.tone,
                      title: needsYouTitle(text, item.kind, fallback: item.title),
                      subtitle: item.subtitle,
                      onTap: target == null ? null : () => context.push(target),
                    );
                  }),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
