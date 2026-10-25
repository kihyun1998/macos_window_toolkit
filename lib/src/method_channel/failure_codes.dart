import 'package:flutter/services.dart';

import '../models/capture_result.dart';
import '../models/scroll_info.dart';
import '../models/window_operation_result.dart';

/// Native error codes that are rethrown as [PlatformException] instead of
/// being returned as a failure result.
const systemErrorCodes = {
  'INVALID_ARGUMENTS',
  'SYSTEM_ERROR',
  'OUT_OF_MEMORY',
  'INTERNAL_ERROR',
};

/// The wire reason each native error code stands for, used when a failure
/// arrives as a [PlatformException] rather than as a state reply.
const _reasonByCode = {
  'WINDOW_NOT_FOUND': 'window_not_found',
  'INVALID_WINDOW_ID': 'window_not_found',
  'WINDOW_NOT_ACCESSIBLE': 'window_not_accessible',
  'PROCESS_NOT_FOUND': 'process_not_found',
  'INVALID_PROCESS_ID': 'process_not_found',
  'ACCESSIBILITY_PERMISSION_DENIED': 'accessibility_permission_denied',
  'CLOSE_BUTTON_NOT_FOUND': 'close_button_not_found',
  'FOCUS_ACTION_FAILED': 'focus_action_failed',
  'WINDOW_STILL_OPEN': 'window_still_open',
  'WINDOW_MINIMIZED': 'window_minimized',
  'UNSUPPORTED_MACOS_VERSION': 'unsupported_version',
  'REQUIRES_MACOS_14': 'unsupported_version',
  'PERMISSION_DENIED': 'permission_denied',
  'SCREEN_RECORDING_PERMISSION_DENIED': 'permission_denied',
  'CAPTURE_IN_PROGRESS': 'capture_in_progress',
  'WINDOW_NOT_CAPTURABLE': 'window_not_capturable',
  'NO_SCROLLABLE_CONTENT': 'no_scrollable_content',
};

const _windowReasons = {
  'window_not_found': WindowOperationFailureReason.windowNotFound,
  'window_not_accessible': WindowOperationFailureReason.windowNotAccessible,
  'process_not_found': WindowOperationFailureReason.processNotFound,
  'accessibility_permission_denied':
      WindowOperationFailureReason.accessibilityPermissionDenied,
  'close_button_not_found': WindowOperationFailureReason.closeButtonNotFound,
  'focus_action_failed': WindowOperationFailureReason.focusActionFailed,
  'window_still_open': WindowOperationFailureReason.windowStillOpen,
};

const _captureReasons = {
  'window_minimized': CaptureFailureReason.windowMinimized,
  'window_not_found': CaptureFailureReason.windowNotFound,
  'unsupported_version': CaptureFailureReason.unsupportedVersion,
  'permission_denied': CaptureFailureReason.permissionDenied,
  'capture_in_progress': CaptureFailureReason.captureInProgress,
  'window_not_capturable': CaptureFailureReason.windowNotCapturable,
};

const _scrollReasons = {
  'window_not_found': ScrollFailureReason.windowNotFound,
  'window_not_accessible': ScrollFailureReason.windowNotAccessible,
  'accessibility_permission_denied':
      ScrollFailureReason.accessibilityPermissionDenied,
  'no_scrollable_content': ScrollFailureReason.noScrollableContent,
};

/// The wire reason of a state reply.
String? _stateReason(Map<dynamic, dynamic> reply) =>
    reply['reason'] as String? ?? _reasonByCode[reply['code']];

/// The `details` text of a [PlatformException], whose details are either the
/// native error map or a plain value.
String? _exceptionDetails(PlatformException e) {
  final details = e.details;
  if (details is Map) return details['details']?.toString();
  return details?.toString();
}

/// Builds the failure for a window or process operation's state reply.
OperationFailure operationFailureFromState(Map<dynamic, dynamic> reply) {
  return OperationFailure(
    reason: _windowReasons[_stateReason(reply)] ??
        WindowOperationFailureReason.unknown,
    message: reply['message'] as String?,
    details: reply['details'] as String?,
  );
}

/// Builds the failure for a window or process operation's platform error.
OperationFailure operationFailureFromException(PlatformException e) {
  return OperationFailure(
    reason: _windowReasons[_reasonByCode[e.code]] ??
        WindowOperationFailureReason.unknown,
    message: e.message,
    details: _exceptionDetails(e),
  );
}

/// Builds the failure for a capture's state reply.
CaptureFailure captureFailureFromState(Map<dynamic, dynamic> reply) {
  return CaptureFailure(
    reason:
        _captureReasons[_stateReason(reply)] ?? CaptureFailureReason.unknown,
    message: reply['message'] as String?,
    details: reply['details'] as String?,
    errorCode: reply['errorCode'] as int?,
    errorDomain: reply['errorDomain'] as String?,
  );
}

/// Builds the failure for a capture's platform error.
CaptureFailure captureFailureFromException(PlatformException e) {
  final details = e.details;
  return CaptureFailure(
    reason:
        _captureReasons[_reasonByCode[e.code]] ?? CaptureFailureReason.unknown,
    message: e.message,
    details: _exceptionDetails(e),
    errorCode: details is Map ? details['errorCode'] as int? : null,
    errorDomain: details is Map ? details['errorDomain'] as String? : null,
  );
}

/// Builds the failure for a scroll inspection's state reply.
ScrollFailure scrollFailureFromState(Map<dynamic, dynamic> reply) {
  return ScrollFailure(
    reason: _scrollReasons[_stateReason(reply)] ?? ScrollFailureReason.unknown,
    message: reply['message'] as String?,
    details: reply['details'] as String?,
  );
}

/// Builds the failure for a scroll inspection's platform error.
ScrollFailure scrollFailureFromException(PlatformException e) {
  return ScrollFailure(
    reason:
        _scrollReasons[_reasonByCode[e.code]] ?? ScrollFailureReason.unknown,
    message: e.message,
    details: _exceptionDetails(e),
  );
}
