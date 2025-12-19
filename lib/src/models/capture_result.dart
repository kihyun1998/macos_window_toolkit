import 'dart:typed_data';

/// Result type for capture operations
sealed class CaptureResult {
  const CaptureResult();
}

/// Successful capture with image data
class CaptureSuccess extends CaptureResult {
  final Uint8List imageData;

  const CaptureSuccess(this.imageData);
}

/// Capture failed due to various reasons (not system errors)
class CaptureFailure extends CaptureResult {
  final CaptureFailureReason reason;
  final String? message;
  final String? details;
  final int? errorCode;
  final String? errorDomain;

  const CaptureFailure({
    required this.reason,
    this.message,
    this.details,
    this.errorCode,
    this.errorDomain,
  });

  String get userMessage {
    switch (reason) {
      case CaptureFailureReason.windowMinimized:
        return 'Window is minimized. Please restore the window first.';
      case CaptureFailureReason.windowNotFound:
        return 'Window not found or no longer exists';
      case CaptureFailureReason.unsupportedVersion:
        return 'macOS version not supported for this capture method';
      case CaptureFailureReason.permissionDenied:
        return 'Screen recording permission required';
      case CaptureFailureReason.captureInProgress:
        return 'Another capture is already in progress';
      case CaptureFailureReason.windowNotCapturable:
        return 'This window cannot be captured';
      case CaptureFailureReason.unknown:
        return message ?? 'Unable to capture window';
    }
  }

  /// Whether this failure can be retried after user action
  bool get canRetry {
    switch (reason) {
      case CaptureFailureReason.windowMinimized:
      case CaptureFailureReason.permissionDenied:
      case CaptureFailureReason.captureInProgress:
        return true;
      case CaptureFailureReason.windowNotFound:
      case CaptureFailureReason.unsupportedVersion:
      case CaptureFailureReason.windowNotCapturable:
      case CaptureFailureReason.unknown:
        return false;
    }
  }

  /// Suggested user action for this failure
  String? get suggestedAction {
    switch (reason) {
      case CaptureFailureReason.windowMinimized:
        return 'Restore the window from dock or window switcher';
      case CaptureFailureReason.permissionDenied:
        return 'Grant screen recording permission in System Settings';
      case CaptureFailureReason.captureInProgress:
        return 'Wait for the current capture to complete';
      case CaptureFailureReason.windowNotFound:
      case CaptureFailureReason.unsupportedVersion:
      case CaptureFailureReason.windowNotCapturable:
      case CaptureFailureReason.unknown:
        return null;
    }
  }
}

/// Specific reasons for capture failure (states, not errors)
enum CaptureFailureReason {
  /// Window is minimized and cannot be captured
  windowMinimized,

  /// Window ID is invalid or window no longer exists
  windowNotFound,

  /// macOS version doesn't support the requested capture method
  unsupportedVersion,

  /// Screen recording permission not granted
  permissionDenied,

  /// Another capture operation is in progress
  captureInProgress,

  /// Window exists but cannot be captured (e.g., system windows)
  windowNotCapturable,

  /// Unknown capture state (not a system error)
  unknown,
}
