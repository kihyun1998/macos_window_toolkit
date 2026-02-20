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
  /// [targetWidth] if specified, resizes the captured image to this width.
  /// [targetHeight] if specified, resizes the captured image to this height.
  /// Both targetWidth and targetHeight must be provided together or both null.
  /// When specified, the image will be resized to exact dimensions (aspect ratio may change).
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
    int? targetWidth,
    int? targetHeight,
    bool preserveAspectRatio = false,
    int? cropContentWidth,
    int? cropContentHeight,
    int? cropX,
    int? cropY,
    int? cropWidth,
    int? cropHeight,
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
}
