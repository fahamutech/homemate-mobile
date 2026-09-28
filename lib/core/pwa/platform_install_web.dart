import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'install_prompt.dart';

InstallPrompt createPlatformInstallPrompt() => WebInstallPrompt();

/// `window.hmPwa`, set up by `web/index.html` before the engine loads — the
/// browser's `beforeinstallprompt` fires once and early, so it has to be
/// caught in plain JavaScript and held for the app.
@JS('hmPwa')
external _HmPwa? get _hmPwa;

extension type _HmPwa(JSObject _) implements JSObject {
  external bool get isIos;
  external bool get isMobile;
  external bool isStandalone();
  external bool canPrompt();
  external JSPromise<JSString> prompt();
}

class WebInstallPrompt extends InstallPrompt {
  WebInstallPrompt() {
    web.window.addEventListener('hm-pwa-change', ((web.Event _) => _changes.add(null)).toJS);
  }

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  InstallMethod get method {
    final pwa = _hmPwa;
    if (pwa == null || pwa.isStandalone()) return InstallMethod.none;
    if (pwa.canPrompt()) return InstallMethod.prompt;
    if (pwa.isIos) return InstallMethod.iosShareSheet;
    // A desktop browser without the dialog (Firefox, Safari on a Mac) has no
    // install path worth describing.
    return pwa.isMobile ? InstallMethod.browserMenu : InstallMethod.none;
  }

  @override
  Future<bool> prompt() async {
    final pwa = _hmPwa;
    if (pwa == null) return false;
    final outcome = (await pwa.prompt().toDart).toDart;
    return outcome == 'accepted';
  }
}
