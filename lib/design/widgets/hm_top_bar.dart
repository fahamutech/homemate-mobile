import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Navigation/TopBar: a back arrow, the screen's title and any actions,
/// on white with a hairline underneath. 57pt tall.
class HmTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HmTopBar({super.key, required this.title, this.onBack, this.backTooltip, this.actions = const []});

  final String title;

  /// Null means there is nowhere to go back to, so no arrow.
  final VoidCallback? onBack;
  final String? backTooltip;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(57);

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.bgPrimary,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 57,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: HmColors.borderDefault)),
            ),
            padding: EdgeInsets.only(left: onBack == null ? HmSpace.xxl : HmSpace.xs, right: HmSpace.xs),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    tooltip: backTooltip,
                    icon: const Icon(Icons.arrow_back_rounded, size: 24, color: HmColors.textPrimary),
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: HmColors.textPrimary),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      );
}
