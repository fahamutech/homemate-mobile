import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Puts the bundled Roboto's Apache 2.0 notice on the app's licences page,
/// next to the packages' own.
void registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Roboto'],
      await rootBundle.loadString('assets/fonts/ROBOTO-LICENSE.txt'),
    );
  });
}
