import '../models/capturable_window_info.dart';
import '../models/capture_result.dart';

/// Platform interface for window capture operations.
abstract class CaptureOperationsInterface {
  /// Captures a window using ScreenCaptureKit.
  ///
  /// Returns a [CaptureResult] indicating success with image data or failure with reason.
  ///
  /// [windowId] is the unique identifier of the window to capture.
  /// [excludeTitlebar] if true, removes the titlebar from the captured image.
  /// [customTitlebarHeight] specifies a custom titlebar height to remove (in points).
  /// If null and excludeTitlebar is true, uses the default 28pt titlebar height.
  /// Must be non-negative and not larger than the window height.
  ///
  /// Returns:
  /// - `CaptureSuccess` with image data on successful capture
  /// - `CaptureFailure` for states like window minimized, permission denied, etc.
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, system failures).
  ///
  /// Example usage:
  /// ```dart
  /// final result = await toolkit.captureWindow(12345);
  /// switch (result) {
  ///   case CaptureSuccess(imageData: final data):
  ///     // Display image
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.windowMinimized):
  ///     // Show "restore window" button
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.unsupportedVersion):
  ///     // Fall back to legacy method
  ///     break;
  /// }
  /// ```
  Future<CaptureResult> captureWindow(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
  }) {
    throw UnimplementedError('captureWindow() has not been implemented.');
  }

  /// Gets list of capturable windows using ScreenCaptureKit.
  ///
  /// Returns a list of [CapturableWindowInfo] objects that are specifically optimized
  /// for window capture operations. This method only returns windows that can
  /// actually be captured by ScreenCaptureKit, which may be a subset of windows
  /// returned by [getAllWindows].
  ///
  /// Throws [PlatformException] with appropriate error codes:
  /// - `UNSUPPORTED_MACOS_VERSION`: macOS version does not support ScreenCaptureKit
  /// - `SCREENCAPTUREKIT_NOT_AVAILABLE`: ScreenCaptureKit is not available
  /// - `CAPTURE_FAILED`: Failed to retrieve capturable windows
  Future<List<CapturableWindowInfo>> getCapturableWindows() {
    throw UnimplementedError(
      'getCapturableWindows() has not been implemented.',
    );
  }

  /// Captures a window using CGWindowListCreateImage (legacy method).
  ///
  /// Returns a [CaptureResult] indicating success with image data or failure with reason.
  ///
  /// [windowId] is the unique identifier of the window to capture.
  /// [excludeTitlebar] if true, removes the titlebar from the captured image.
  /// [customTitlebarHeight] specifies a custom titlebar height to remove (in points).
  /// If null and excludeTitlebar is true, uses the default 28pt titlebar height.
  /// Must be non-negative and not larger than the window height.
  ///
  /// This method uses the legacy CGWindowListCreateImage API which is available
  /// on all macOS versions (10.5+) but may have lower quality or performance
  /// compared to ScreenCaptureKit.
  ///
  /// Returns:
  /// - `CaptureSuccess` with image data on successful capture
  /// - `CaptureFailure` for states like window minimized, window not found, etc.
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, system failures).
  ///
  /// Example usage:
  /// ```dart
  /// final result = await toolkit.captureWindowLegacy(12345);
  /// switch (result) {
  ///   case CaptureSuccess(imageData: final data):
  ///     // Display image
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.windowNotFound):
  ///     // Show "window not found" message
  ///     break;
  /// }
  /// ```
  Future<CaptureResult> captureWindowLegacy(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
  }) {
    throw UnimplementedError('captureWindowLegacy() has not been implemented.');
  }

  /// Gets list of capturable windows using CGWindowListCopyWindowInfo (legacy method).
  ///
  /// Returns a list of [CapturableWindowInfo] objects using the legacy
  /// CGWindowListCopyWindowInfo API. This method is available on all macOS
  /// versions but may provide different window information compared to
  /// ScreenCaptureKit.
  ///
  /// This method always succeeds and does not throw exceptions. Empty list
  /// is returned if no windows are found.
  Future<List<CapturableWindowInfo>> getCapturableWindowsLegacy() {
    throw UnimplementedError(
      'getCapturableWindowsLegacy() has not been implemented.',
    );
  }

  /// Captures a window using the best available method (auto-selection).
  ///
  /// Automatically selects between ScreenCaptureKit and CGWindowListCreateImage
  /// based on macOS version and availability:
  /// - Uses ScreenCaptureKit on macOS 14.0+ for best quality
  /// - Falls back to CGWindowListCreateImage on older versions or if ScreenCaptureKit fails
  ///
  /// Returns a [CaptureResult] indicating success with image data or failure with reason.
  ///
  /// [windowId] is the unique identifier of the window to capture.
  /// [excludeTitlebar] if true, removes the titlebar from the captured image.
  /// [customTitlebarHeight] specifies a custom titlebar height to remove (in points).
  /// If null and excludeTitlebar is true, uses the default 28pt titlebar height.
  /// Must be non-negative and not larger than the window height.
  ///
  /// This is the recommended method for window capture as it provides the best
  /// experience across all macOS versions.
  ///
  /// Returns:
  /// - `CaptureSuccess` with image data on successful capture
  /// - `CaptureFailure` for states like window minimized, permission denied, etc.
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, system failures).
  ///
  /// Example usage:
  /// ```dart
  /// final result = await toolkit.captureWindowAuto(12345);
  /// switch (result) {
  ///   case CaptureSuccess(imageData: final data):
  ///     // Display image
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.windowMinimized):
  ///     // Show restore button
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.permissionDenied):
  ///     // Show permission dialog
  ///     break;
  /// }
  /// ```
  Future<CaptureResult> captureWindowAuto(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
  }) {
    throw UnimplementedError('captureWindowAuto() has not been implemented.');
  }

  /// Gets list of capturable windows using the best available method (auto-selection).
  ///
  /// Automatically selects between ScreenCaptureKit and CGWindowListCopyWindowInfo
  /// based on macOS version and availability:
  /// - Uses ScreenCaptureKit on macOS 12.3+ for better window information
  /// - Falls back to CGWindowListCopyWindowInfo on older versions or if ScreenCaptureKit fails
  ///
  /// Returns a list of [CapturableWindowInfo] objects optimized for the current system.
  /// This is the recommended method for getting capturable windows as it provides
  /// the best experience across all macOS versions.
  ///
  /// Throws [PlatformException] with appropriate error codes:
  /// - `NO_COMPATIBLE_CAPTURE_METHOD`: No window listing method is available
  /// - `CAPTURE_METHOD_FAILED`: The selected window listing method failed
  Future<List<CapturableWindowInfo>> getCapturableWindowsAuto() {
    throw UnimplementedError(
      'getCapturableWindowsAuto() has not been implemented.',
    );
  }

  /// Gets information about the capture method that would be used by auto-selection.
  ///
  /// Returns a map containing:
  /// - `captureMethod`: The capture method that would be used ("ScreenCaptureKit" or "CGWindowListCreateImage")
  /// - `windowListMethod`: The window listing method that would be used ("ScreenCaptureKit" or "CGWindowListCopyWindowInfo")
  /// - `macOSVersion`: Current macOS version string
  /// - `isScreenCaptureKitAvailable`: Whether ScreenCaptureKit framework is available (bool)
  /// - `supportsModernCapture`: Whether modern capture (ScreenCaptureKit) is supported (bool)
  /// - `supportsModernWindowList`: Whether modern window listing (ScreenCaptureKit) is supported (bool)
  ///
  /// This method is useful for debugging and providing user feedback about
  /// the capture capabilities on their system.
  ///
  /// Example usage:
  /// ```dart
  /// final info = await toolkit.getCaptureMethodInfo();
  /// print('Capture method: ${info['captureMethod']}');
  /// print('macOS version: ${info['macOSVersion']}');
  /// print('Modern capture supported: ${info['supportsModernCapture']}');
  /// ```
  Future<Map<String, dynamic>> getCaptureMethodInfo() {
    throw UnimplementedError(
      'getCaptureMethodInfo() has not been implemented.',
    );
  }
}
