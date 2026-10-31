import 'package:flutter/services.dart';

/// Platform-specific error codes returned by the native macOS implementation
enum PlatformErrorCode {
  // Window operation errors
  windowListError('WINDOW_LIST_ERROR'),
  invalidArguments('INVALID_ARGUMENTS'),

  // Capture errors
  captureUnsupportedMacOSVersion('UNSUPPORTED_MACOS_VERSION'),
  captureInvalidWindowId('INVALID_WINDOW_ID'),
  captureWindowMinimized('WINDOW_MINIMIZED'),
  captureFailed('CAPTURE_FAILED'),

  /// Not currently sent by the native side.
  captureNoCompatibleMethod('NO_COMPATIBLE_CAPTURE_METHOD'),
  captureScreenRecordingPermissionDenied('SCREEN_RECORDING_PERMISSION_DENIED'),
  captureRequiresMacOS14('REQUIRES_MACOS_14'),

  // Window management errors
  /// Not currently sent by the native side.
  closeWindowError('CLOSE_WINDOW_ERROR'),
  windowNotFound('WINDOW_NOT_FOUND'),
  insufficientWindowInfo('INSUFFICIENT_WINDOW_INFO'),

  /// Not currently sent by the native side.
  appleScriptExecutionFailed('APPLESCRIPT_EXECUTION_FAILED'),
  accessibilityPermissionDenied('ACCESSIBILITY_PERMISSION_DENIED'),

  // Process termination errors
  /// Not currently sent by the native side.
  terminateAppError('TERMINATE_APP_ERROR'),

  /// Not currently sent by the native side.
  terminateTreeError('TERMINATE_TREE_ERROR'),
  processNotFound('PROCESS_NOT_FOUND'),

  /// A PID a terminate call refuses to signal: 1 or below, or outside `pid_t`.
  invalidProcessId('INVALID_PROCESS_ID'),
  terminationFailed('TERMINATION_FAILED'),
  failedToGetProcessList('FAILED_TO_GET_PROCESS_LIST'),
  getChildProcessesError('GET_CHILD_PROCESSES_ERROR'),

  // Window operation states and errors
  failedToRetrieveWindowList('FAILED_TO_RETRIEVE_WINDOW_LIST'),
  closeButtonNotFound('CLOSE_BUTTON_NOT_FOUND'),
  closeActionFailed('CLOSE_ACTION_FAILED'),
  focusActionFailed('FOCUS_ACTION_FAILED'),

  /// The window was still open when `closeWindow`'s `waitUntilClosed` ran out.
  windowStillOpen('WINDOW_STILL_OPEN'),

  /// The window was not focused when `focusWindow`'s `waitUntilFocused` ran out.
  windowNotFocused('WINDOW_NOT_FOCUSED'),
  windowNotAccessible('WINDOW_NOT_ACCESSIBLE'),
  spaceSwitchAPIUnavailable('SPACE_SWITCH_API_UNAVAILABLE'),
  fullScreenCheckFailed('FULLSCREEN_CHECK_FAILED'),

  // Application errors
  getApplicationsError('GET_APPLICATIONS_ERROR'),
  openAppStoreError('OPEN_APP_STORE_ERROR');

  const PlatformErrorCode(this.code);

  final String code;

  /// Get PlatformErrorCode from string code, returns null if not found
  static PlatformErrorCode? fromCode(String code) {
    for (final errorCode in PlatformErrorCode.values) {
      if (errorCode.code == code) {
        return errorCode;
      }
    }
    return null;
  }

  /// Get user-friendly error message for the error code
  String get userMessage {
    switch (this) {
      case PlatformErrorCode.windowListError:
        return 'Failed to retrieve window list';
      case PlatformErrorCode.invalidArguments:
        return 'Invalid parameters provided';
      case PlatformErrorCode.captureUnsupportedMacOSVersion:
        return 'macOS version not supported for this capture method';
      case PlatformErrorCode.captureInvalidWindowId:
        return 'Window not found or not capturable';
      case PlatformErrorCode.captureWindowMinimized:
        return 'Window is minimized and cannot be captured. Please restore the window first.';
      case PlatformErrorCode.captureFailed:
        return 'Window capture failed';
      case PlatformErrorCode.captureNoCompatibleMethod:
        return 'No compatible capture method available';
      case PlatformErrorCode.captureScreenRecordingPermissionDenied:
        return 'Screen recording permission is required for window capture. Please grant permission in System Settings.';
      case PlatformErrorCode.captureRequiresMacOS14:
        return 'This capture method requires macOS 14.0 or later';
      case PlatformErrorCode.closeWindowError:
        return 'Failed to close window';
      case PlatformErrorCode.windowNotFound:
        return 'Window not found';
      case PlatformErrorCode.insufficientWindowInfo:
        return 'Not enough window information';
      case PlatformErrorCode.appleScriptExecutionFailed:
        return 'AppleScript execution failed';
      case PlatformErrorCode.accessibilityPermissionDenied:
        return 'Accessibility permission is required for window management. Please grant permission in System Settings.';
      case PlatformErrorCode.terminateAppError:
        return 'Application termination error';
      case PlatformErrorCode.terminateTreeError:
        return 'Process tree termination error';
      case PlatformErrorCode.processNotFound:
        return 'Process not found';
      case PlatformErrorCode.invalidProcessId:
        return 'Invalid process ID';
      case PlatformErrorCode.terminationFailed:
        return 'Termination failed';
      case PlatformErrorCode.failedToGetProcessList:
        return 'Failed to get process list';
      case PlatformErrorCode.getChildProcessesError:
        return 'Failed to get child processes';
      case PlatformErrorCode.failedToRetrieveWindowList:
        return 'Failed to retrieve window list';
      case PlatformErrorCode.closeButtonNotFound:
        return 'Unable to find close button for this window';
      case PlatformErrorCode.closeActionFailed:
        return 'Failed to press the close button';
      case PlatformErrorCode.focusActionFailed:
        return 'Unable to bring window to front';
      case PlatformErrorCode.windowStillOpen:
        return 'The window did not close in time';
      case PlatformErrorCode.windowNotFocused:
        return 'The window did not become focused in time';
      case PlatformErrorCode.windowNotAccessible:
        return 'Window is not accessible (may be on a different Space, or its app does not support Accessibility)';
      case PlatformErrorCode.spaceSwitchAPIUnavailable:
        return 'The window is on another Space and switching Spaces is unavailable on this macOS version';
      case PlatformErrorCode.fullScreenCheckFailed:
        return 'Failed to check whether the window is fullscreen';
      case PlatformErrorCode.getApplicationsError:
        return 'Failed to retrieve installed applications';
      case PlatformErrorCode.openAppStoreError:
        return 'Failed to open the App Store';
    }
  }
}

/// Extension on PlatformException to easily get typed error codes
extension PlatformExceptionExtension on Exception {
  PlatformErrorCode? get errorCode {
    if (this is PlatformException) {
      final platformException = this as PlatformException;
      return PlatformErrorCode.fromCode(platformException.code);
    }
    return null;
  }

  String get userFriendlyMessage {
    if (this is PlatformException) {
      final platformException = this as PlatformException;
      final errorCode = PlatformErrorCode.fromCode(platformException.code);
      if (errorCode != null) {
        return errorCode.userMessage;
      }
      return platformException.message ?? 'Unknown error occurred';
    }
    return toString();
  }
}
