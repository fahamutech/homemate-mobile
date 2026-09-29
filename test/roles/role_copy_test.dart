import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/roles/presentation/role_copy.dart';

void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  test('each role has its name, summary and Figma icon', () {
    expect(AppRole.values.map((r) => roleLabel(en, r)), ['Customer', 'Broker', 'Landlord']);
    expect(AppRole.values.map((r) => roleLabel(sw, r)), ['Mteja', 'Dalali', 'Mwenye nyumba']);
    expect(roleSummary(en, AppRole.landlord), 'Your homes, tenants and rent');
    expect(roleIcon(AppRole.broker), Icons.real_estate_agent_rounded);
    expect(roleIcon(AppRole.landlord), Icons.key_rounded);
  });

  test('only a role on its way has a status label', () {
    expect(roleStatusLabel(en, 'pending_review'), 'Under review');
    expect(roleStatusLabel(en, 'action_needed'), 'Action needed');
    expect(roleStatusLabel(en, 'applied'), 'Setup not finished');
    expect(roleStatusLabel(en, 'active'), isNull);
    expect(roleStatusLabel(en, null), isNull);
  });
}
