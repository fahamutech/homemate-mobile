/// How this browser lets a customer put HomeMate on their home screen.
enum InstallMethod {
  /// Not a browser, already installed, or a browser with no way to install.
  none,

  /// Chrome, Edge, Samsung Internet: the browser's own install dialog.
  prompt,

  /// iPhone and iPad: Share → Add to Home Screen, which only the customer can
  /// do, so the app shows the steps.
  iosShareSheet,

  /// A mobile browser that did not offer its dialog (yet): the steps through
  /// its menu.
  browserMenu,
}

/// The platform side of installing the PWA.
abstract class InstallPrompt {
  InstallMethod get method;

  /// Shows the browser's install dialog; true when the customer accepted.
  Future<bool> prompt();

  /// Fires when [method] may have changed — the browser became ready to
  /// offer its dialog, or the app was installed.
  Stream<void> get changes => const Stream.empty();
}

class NoInstallPrompt extends InstallPrompt {
  @override
  InstallMethod get method => InstallMethod.none;

  @override
  Future<bool> prompt() async => false;
}
