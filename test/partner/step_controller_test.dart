import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/wizard/step_controller.dart';

void main() {
  test('a step that is not ready stops the wizard; no step means nothing to save', () {
    final controller = WizardStepController();
    expect(controller.read(), isEmpty);
    controller.collect = () => null;
    expect(controller.read(), isNull);
    controller.collect = () => {'title': 'x'};
    expect(controller.read(), {'title': 'x'});
  });
}
