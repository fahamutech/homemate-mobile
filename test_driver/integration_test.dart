import 'package:integration_test/integration_test_driver.dart';

/// The driver `flutter drive` needs to run an integration test in a real
/// browser. It has no logic of its own — the test does the work.
Future<void> main() => integrationDriver();
