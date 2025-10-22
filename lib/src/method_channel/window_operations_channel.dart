import 'package:flutter/services.dart';

import '../models/window_operation_result.dart';

/// Mixin providing method channel implementations for window operations.
mixin WindowOperationsChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<List<Map<String, dynamic>>> getAllWindows({
    bool excludeEmptyNames = false,
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getAllWindows',
      excludeEmptyNames ? {'excludeEmptyNames': excludeEmptyNames} : null,
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getWindowsByName(String name) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowsByName',
      {'name': name},
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getWindowsByOwnerName(
    String ownerName,
  ) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowsByOwnerName',
      {'ownerName': ownerName},
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getWindowById(int windowId) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowById',
      {'windowId': windowId},
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getWindowsByProcessId(
    int processId,
  ) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowsByProcessId',
      {'processId': processId},
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getWindowsAdvanced({
    int? windowId,
    String? name,
    bool? nameExactMatch,
    bool? nameCaseSensitive,
    bool? nameWildcard,
    String? ownerName,
    bool? ownerNameExactMatch,
    bool? ownerNameCaseSensitive,
    bool? ownerNameWildcard,
    int? processId,
    bool? isOnScreen,
    int? layer,
    double? x,
    double? y,
    double? width,
    double? height,
  }) async {
    final args = <String, dynamic>{};

    if (windowId != null) args['windowId'] = windowId;
    if (name != null) args['name'] = name;
    if (nameExactMatch != null) args['nameExactMatch'] = nameExactMatch;
    if (nameCaseSensitive != null) {
      args['nameCaseSensitive'] = nameCaseSensitive;
    }
    if (nameWildcard != null) args['nameWildcard'] = nameWildcard;
    if (ownerName != null) args['ownerName'] = ownerName;
    if (ownerNameExactMatch != null) {
      args['ownerNameExactMatch'] = ownerNameExactMatch;
    }
    if (ownerNameCaseSensitive != null) {
      args['ownerNameCaseSensitive'] = ownerNameCaseSensitive;
    }
    if (ownerNameWildcard != null) {
      args['ownerNameWildcard'] = ownerNameWildcard;
    }
    if (processId != null) args['processId'] = processId;
    if (isOnScreen != null) args['isOnScreen'] = isOnScreen;
    if (layer != null) args['layer'] = layer;
    if (x != null) args['x'] = x;
    if (y != null) args['y'] = y;
    if (width != null) args['width'] = width;
    if (height != null) args['height'] = height;

    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowsAdvanced',
      args.isEmpty ? null : args,
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<bool> isWindowAlive(int windowId, {String? expectedName}) async {
    final args = <String, dynamic>{'windowId': windowId};
    if (expectedName != null) {
      args['expectedName'] = expectedName;
    }

    final result =
        await methodChannel.invokeMethod<bool>('isWindowAlive', args);
    return result ?? false;
  }

  Future<WindowOperationResult> closeWindow(int windowId) async {
    try {
      final result = await methodChannel.invokeMethod<dynamic>('closeWindow', {
        'windowId': windowId,
      });

      if (result == null) {
        return const OperationFailure(
          reason: WindowOperationFailureReason.unknown,
          message: 'No response from closeWindow',
        );
      }

      // Handle Map response (v1.4.3+ state errors)
      if (result is Map) {
        return _parseOperationResult(Map<dynamic, dynamic>.from(result));
      }

      // Handle bool response (backward compatible or success case)
      if (result is bool) {
        return result
            ? const OperationSuccess()
            : const OperationFailure(
                reason: WindowOperationFailureReason.unknown,
                message: 'Operation returned false',
              );
      }

      return const OperationFailure(
        reason: WindowOperationFailureReason.unknown,
        message: 'Unexpected response type',
      );
    } on PlatformException catch (e) {
      // Only system errors should throw, others should return OperationFailure
      if (_isSystemError(e.code)) {
        rethrow;
      }
      return _platformExceptionToOperationFailure(e);
    }
  }

  Future<WindowOperationResult> focusWindow(int windowId) async {
    try {
      final result = await methodChannel.invokeMethod<dynamic>('focusWindow', {
        'windowId': windowId,
      });

      if (result == null) {
        return const OperationFailure(
          reason: WindowOperationFailureReason.unknown,
          message: 'No response from focusWindow',
        );
      }

      // Handle Map response (v1.4.3+ state errors)
      if (result is Map) {
        return _parseOperationResult(Map<dynamic, dynamic>.from(result));
      }

      // Handle bool response (backward compatible or success case)
      if (result is bool) {
        return result
            ? const OperationSuccess()
            : const OperationFailure(
                reason: WindowOperationFailureReason.unknown,
                message: 'Operation returned false',
              );
      }

      return const OperationFailure(
        reason: WindowOperationFailureReason.unknown,
        message: 'Unexpected response type',
      );
    } on PlatformException catch (e) {
      // Only system errors should throw, others should return OperationFailure
      if (_isSystemError(e.code)) {
        rethrow;
      }
      return _platformExceptionToOperationFailure(e);
    }
  }

  /// Helper method to parse operation result from native response
  WindowOperationResult _parseOperationResult(Map<dynamic, dynamic> result) {
    final success = result['success'] as bool? ?? false;

    if (success) {
      return const OperationSuccess();
    } else {
      final reasonCode = result['reason'] as String? ?? 'unknown';
      final message = result['message'] as String?;
      final details = result['details'] as String?;

      final reason = _mapReasonCodeToFailureReason(reasonCode);
      return OperationFailure(
          reason: reason, message: message, details: details);
    }
  }

  /// Maps native reason codes to WindowOperationFailureReason enum
  WindowOperationFailureReason _mapReasonCodeToFailureReason(String code) {
    switch (code) {
      case 'window_not_found':
        return WindowOperationFailureReason.windowNotFound;
      case 'process_not_found':
        return WindowOperationFailureReason.processNotFound;
      case 'accessibility_permission_denied':
        return WindowOperationFailureReason.accessibilityPermissionDenied;
      case 'close_button_not_found':
        return WindowOperationFailureReason.closeButtonNotFound;
      case 'focus_action_failed':
        return WindowOperationFailureReason.focusActionFailed;
      default:
        return WindowOperationFailureReason.unknown;
    }
  }

  /// Converts PlatformException to OperationFailure for legacy error handling
  OperationFailure _platformExceptionToOperationFailure(PlatformException e) {
    final reason = _mapErrorCodeToFailureReason(e.code);
    return OperationFailure(
      reason: reason,
      message: e.message,
      details: e.details?.toString(),
    );
  }

  /// Maps legacy error codes to WindowOperationFailureReason
  WindowOperationFailureReason _mapErrorCodeToFailureReason(String code) {
    switch (code) {
      case 'WINDOW_NOT_FOUND':
      case 'INVALID_WINDOW_ID':
        return WindowOperationFailureReason.windowNotFound;
      case 'PROCESS_NOT_FOUND':
        return WindowOperationFailureReason.processNotFound;
      case 'ACCESSIBILITY_PERMISSION_DENIED':
        return WindowOperationFailureReason.accessibilityPermissionDenied;
      case 'CLOSE_BUTTON_NOT_FOUND':
        return WindowOperationFailureReason.closeButtonNotFound;
      case 'FOCUS_ACTION_FAILED':
        return WindowOperationFailureReason.focusActionFailed;
      default:
        return WindowOperationFailureReason.unknown;
    }
  }

  /// Determines if an error code represents a system error that should throw
  bool _isSystemError(String code) {
    switch (code) {
      case 'INVALID_ARGUMENTS':
      case 'SYSTEM_ERROR':
      case 'OUT_OF_MEMORY':
      case 'INTERNAL_ERROR':
        return true;
      default:
        return false;
    }
  }
}
