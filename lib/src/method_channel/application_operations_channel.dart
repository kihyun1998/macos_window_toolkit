import 'package:flutter/services.dart';

import '../models/window_operation_result.dart';

/// Mixin providing method channel implementations for application operations.
mixin ApplicationOperationsChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<WindowOperationResult> terminateApplicationByPID(
    int processId, {
    bool force = false,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<dynamic>(
        'terminateApplicationByPID',
        {'processId': processId, 'force': force},
      );

      if (result == null) {
        return const OperationFailure(
          reason: WindowOperationFailureReason.unknown,
          message: 'No response from terminateApplicationByPID',
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

  Future<WindowOperationResult> terminateApplicationTree(
    int processId, {
    bool force = false,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<dynamic>(
        'terminateApplicationTree',
        {'processId': processId, 'force': force},
      );

      if (result == null) {
        return const OperationFailure(
          reason: WindowOperationFailureReason.unknown,
          message: 'No response from terminateApplicationTree',
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

  Future<List<int>> getChildProcesses(int processId) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getChildProcesses',
      {'processId': processId},
    );
    if (result == null) {
      return [];
    }
    return result.cast<int>();
  }

  Future<List<Map<String, dynamic>>> getAllInstalledApplications() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getAllInstalledApplications',
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getApplicationByName(String name) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getApplicationByName',
      {'name': name},
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<bool> openAppStoreSearch(String searchTerm) async {
    final result = await methodChannel.invokeMethod<bool>(
      'openAppStoreSearch',
      {'searchTerm': searchTerm},
    );
    return result ?? false;
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
