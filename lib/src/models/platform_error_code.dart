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
  captureNoCompatibleMethod('NO_COMPATIBLE_CAPTURE_METHOD'),
  captureScreenRecordingPermissionDenied('SCREEN_RECORDING_PERMISSION_DENIED'),
  captureRequiresMacOS14('REQUIRES_MACOS_14'),

  // Window management errors
  closeWindowError('CLOSE_WINDOW_ERROR'),
  windowNotFound('WINDOW_NOT_FOUND'),
  insufficientWindowInfo('INSUFFICIENT_WINDOW_INFO'),
  appleScriptExecutionFailed('APPLESCRIPT_EXECUTION_FAILED'),
  accessibilityPermissionDenied('ACCESSIBILITY_PERMISSION_DENIED'),

  // Process termination errors
  terminateAppError('TERMINATE_APP_ERROR'),
  terminateTreeError('TERMINATE_TREE_ERROR'),
  processNotFound('PROCESS_NOT_FOUND'),
  terminationFailed('TERMINATION_FAILED'),
  failedToGetProcessList('FAILED_TO_GET_PROCESS_LIST'),
  getChildProcessesError('GET_CHILD_PROCESSES_ERROR');

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
      case PlatformErrorCode.terminationFailed:
        return 'Termination failed';
      case PlatformErrorCode.failedToGetProcessList:
        return 'Failed to get process list';
      case PlatformErrorCode.getChildProcessesError:
        return 'Failed to get child processes';
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
