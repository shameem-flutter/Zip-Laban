import 'dart:js_interop';

@JS('triggerPwaInstall')
external JSPromise<JSString> _triggerPwaInstall();

@JS('checkPwaInstallState')
external JSString _checkPwaInstallState();

/// Web implementation using modern dart:js_interop
class PwaInstallPlatform {
  static Future<String> triggerInstall() async {
    try {
      final promise = _triggerPwaInstall();
      final jsString = await promise.toDart;
      return jsString.toDart;
    } catch (_) {
      return 'browser_prompt_unavailable';
    }
  }

  static String checkState() {
    try {
      return _checkPwaInstallState().toDart;
    } catch (_) {
      return 'unknown';
    }
  }
}
