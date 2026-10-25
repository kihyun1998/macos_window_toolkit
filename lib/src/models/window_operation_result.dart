/// Result type for window operation functions
/// Used by closeWindow, terminateApplicationByPID, and terminateApplicationTree
sealed class WindowOperationResult {
  const WindowOperationResult();
}

/// Successful window operation
class OperationSuccess extends WindowOperationResult {
  const OperationSuccess();
}

/// Window operation failed due to various reasons (not system errors)
class OperationFailure extends WindowOperationResult {
  final WindowOperationFailureReason reason;
  final String? message;
  final String? details;

  const OperationFailure({
    required this.reason,
    this.message,
    this.details,
  });

  /// User-friendly message for this failure
  String get userMessage {
    switch (reason) {
      case WindowOperationFailureReason.windowNotFound:
        return 'Window not found or no longer exists';
      case WindowOperationFailureReason.windowNotAccessible:
        return 'Window is not accessible (may be on a different Space, or its app does not support Accessibility)';
      case WindowOperationFailureReason.processNotFound:
        return 'Process not found or already terminated';
      case WindowOperationFailureReason.accessibilityPermissionDenied:
        return 'Accessibility permission required';
      case WindowOperationFailureReason.closeButtonNotFound:
        return 'Unable to find close button for this window';
      case WindowOperationFailureReason.focusActionFailed:
        return 'Unable to bring window to front';
      case WindowOperationFailureReason.windowStillOpen:
        return 'The window is still open';
      case WindowOperationFailureReason.unknown:
        return message ?? 'Operation failed';
    }
  }

  /// Whether this failure can be retried after user action
  bool get canRetry {
    switch (reason) {
      case WindowOperationFailureReason.accessibilityPermissionDenied:
        return true;
      case WindowOperationFailureReason.windowNotFound:
      case WindowOperationFailureReason.windowNotAccessible:
      case WindowOperationFailureReason.processNotFound:
      case WindowOperationFailureReason.closeButtonNotFound:
      case WindowOperationFailureReason.focusActionFailed:
      case WindowOperationFailureReason.windowStillOpen:
      case WindowOperationFailureReason.unknown:
        return false;
    }
  }

  /// Suggested user action for this failure
  String? get suggestedAction {
    switch (reason) {
      case WindowOperationFailureReason.accessibilityPermissionDenied:
        return 'Grant accessibility permission in System Settings';
      case WindowOperationFailureReason.windowNotAccessible:
        return 'Switch to the Space where the window is located, or check that its app supports Accessibility';
      case WindowOperationFailureReason.windowNotFound:
      case WindowOperationFailureReason.processNotFound:
      case WindowOperationFailureReason.closeButtonNotFound:
      case WindowOperationFailureReason.windowStillOpen:
        return 'The app may be asking whether to save changes; check the window';
      case WindowOperationFailureReason.focusActionFailed:
      case WindowOperationFailureReason.unknown:
        return null;
    }
  }
}

/// Specific reasons for window operation failure (states, not errors)
enum WindowOperationFailureReason {
  /// Window ID is invalid or window no longer exists
  windowNotFound,

  /// Window exists but cannot be accessed via Accessibility API
  /// (e.g., it is on a different Space or the app does not support it)
  windowNotAccessible,

  /// Process ID is invalid or process no longer exists
  processNotFound,

  /// Accessibility permission not granted
  accessibilityPermissionDenied,

  /// Close button not found (for closeWindow operation)
  closeButtonNotFound,

  /// Focus action failed (for focusWindow operation)
  focusActionFailed,

  /// The close button was pressed, but the window was still open when
  /// `closeWindow`'s `waitUntilClosed` ran out.
  windowStillOpen,

  /// Unknown operation state (not a system error)
  unknown,
}
