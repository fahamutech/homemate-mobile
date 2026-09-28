import 'install_prompt.dart';

/// A native build is already installed; there is nothing to offer.
InstallPrompt createPlatformInstallPrompt() => NoInstallPrompt();
