/// What a step hands the wizard when it is left: the fields to save, or null
/// when something on it is not right yet (the step shows why).
class WizardStepController {
  Map<String, dynamic>? Function()? collect;

  /// Nothing to save when no step registered; the step's answer otherwise.
  Map<String, dynamic>? read() {
    final step = collect;
    return step == null ? const {} : step();
  }
}
