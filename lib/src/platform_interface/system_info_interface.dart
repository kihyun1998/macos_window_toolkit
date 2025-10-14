/// Platform interface for system information operations.
abstract class SystemInfoInterface {
  /// Gets macOS version information.
  ///
  /// Returns a map containing:
  /// - `majorVersion`: Major version number (int)
  /// - `minorVersion`: Minor version number (int)
  /// - `patchVersion`: Patch version number (int)
  /// - `versionString`: Full version string (String)
  /// - `isScreenCaptureKitAvailable`: Whether ScreenCaptureKit is available (bool)
  Future<Map<String, dynamic>> getMacOSVersionInfo() {
    throw UnimplementedError('getMacOSVersionInfo() has not been implemented.');
  }
}
