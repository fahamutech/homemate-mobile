import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'design/font_licence.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicences();
  runApp(const ProviderScope(child: HomeMateApp()));
}
