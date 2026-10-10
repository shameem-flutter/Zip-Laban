/// Stub implementation for non-web platforms and test runner
class PwaInstallPlatform {
  static Future<String> triggerInstall() async {
    return 'unsupported_platform';
  }

  static String checkState() {
    return 'unsupported';
  }
}
