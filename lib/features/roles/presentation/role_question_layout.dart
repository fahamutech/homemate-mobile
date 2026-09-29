import 'package:flutter/material.dart';

import '../../../design/tokens.dart';

/// The frame AUTH-001 and ROL-001 share: the brand mark, a title and a line,
/// the options, and one action pinned to the bottom.
class RoleQuestionLayout extends StatelessWidget {
  const RoleQuestionLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: HmColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: HmLayout.contentMaxWidth),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(HmSpace.xxl, 48, HmSpace.xxl, HmSpace.huge),
                      children: [
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: HmColors.brandPrimary,
                              borderRadius: BorderRadius.circular(HmRadius.lg),
                            ),
                            child: const Icon(Icons.home_outlined, size: 30, color: HmColors.textOnBrand),
                          ),
                        ),
                        const SizedBox(height: HmSpace.xl),
                        Text(title, textAlign: TextAlign.center, style: HmText.title),
                        const SizedBox(height: HmSpace.xl),
                        Text(subtitle, textAlign: TextAlign.center, style: HmText.body.copyWith(height: 22 / 15)),
                        const SizedBox(height: HmSpace.huge),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, HmSpace.section),
                decoration: const BoxDecoration(
                  color: HmColors.bgPrimary,
                  border: Border(top: BorderSide(color: HmColors.borderDefault)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: HmLayout.contentMaxWidth),
                    child: action,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
