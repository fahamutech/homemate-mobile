import 'package:flutter/material.dart';

import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_feedback.dart';

/// A setup step's body: scrolling content, an inline error, and the actions
/// pinned to the bottom above a hairline.
class SetupFrame extends StatelessWidget {
  const SetupFrame({super.key, required this.children, required this.actions, this.error});

  final List<Widget> children;
  final List<Widget> actions;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xl, HmSpace.xxl, HmSpace.huge),
              children: children,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, HmSpace.xxl),
            decoration: const BoxDecoration(
              color: HmColors.bgPrimary,
              border: Border(top: BorderSide(color: HmColors.borderDefault)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Next to the button that caused it, where it cannot be missed.
                  HmInlineError(error),
                  for (final (index, action) in actions.indexed) ...[
                    if (index > 0) const SizedBox(height: HmSpace.md),
                    action,
                  ],
                ],
              ),
            ),
          ),
        ],
      );
}
