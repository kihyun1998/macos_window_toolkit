import 'package:flutter/services.dart';

import '../models/window_operation_result.dart';
import 'failure_codes.dart';

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
      if (systemErrorCodes.contains(e.code)) {
        rethrow;
      }
      return operationFailureFromException(e);
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
      if (systemErrorCodes.contains(e.code)) {
        rethrow;
      }
      return operationFailureFromException(e);
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
    return success
        ? const OperationSuccess()
        : operationFailureFromState(result);
  }
}
