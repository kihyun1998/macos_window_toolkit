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

  /// Gets the screen scale factor (backingScaleFactor) of the main screen.
  ///
  /// Returns 1.0 for standard displays, 2.0 for Retina displays.
  Future<double> getScreenScaleFactor() {
    throw UnimplementedError(
        'getScreenScaleFactor() has not been implemented.');
  }

  /// Gets information about all connected screens.
  ///
  /// Returns a list of maps containing screen information:
  /// - `index`: Screen index (int)
  /// - `isMain`: Whether this is the main screen (bool)
  /// - `scaleFactor`: Screen scale factor (double)
  /// - `frame`: Screen frame (Map with x, y, width, height)
  /// - `visibleFrame`: Visible frame excluding menu bar and dock (Map)
  /// - `pixelWidth`: Actual pixel width (int)
  /// - `pixelHeight`: Actual pixel height (int)
  Future<List<Map<String, dynamic>>> getAllScreensInfo() {
    throw UnimplementedError('getAllScreensInfo() has not been implemented.');
  }
}
