import 'package:flutter/services.dart';

import '../models/scroll_info.dart';
import '../models/window_operation_result.dart';
import 'failure_codes.dart';

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
      if (systemErrorCodes.contains(e.code)) {
        rethrow;
      }
      return operationFailureFromException(e);
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
      if (systemErrorCodes.contains(e.code)) {
        rethrow;
      }
      return operationFailureFromException(e);
    }
  }

  /// Helper method to parse operation result from native response
  WindowOperationResult _parseOperationResult(Map<dynamic, dynamic> result) {
    final success = result['success'] as bool? ?? false;
    return success
        ? const OperationSuccess()
        : operationFailureFromState(result);
  }

  Future<bool> isWindowFullScreen(int windowId) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'isWindowFullScreen',
      {'windowId': windowId},
    );

    if (result is bool) {
      return result;
    }

    // Handle Map response (state errors like permission denied, unsupported version)
    if (result is Map) {
      final map = Map<dynamic, dynamic>.from(result);
      final reason = map['reason'] as String? ?? 'unknown';
      final message = map['message'] as String? ?? 'Unknown error';
      throw PlatformException(
        code: map['code'] as String? ?? reason.toUpperCase(),
        message: message,
        details: Map<dynamic, dynamic>.from(map)
          ..remove('success')
          ..remove('reason'),
      );
    }

    return false;
  }

  Future<ScrollOperationResult> getScrollInfo(int windowId) async {
    try {
      final result =
          await methodChannel.invokeMethod<dynamic>('getScrollInfo', {
        'windowId': windowId,
      });

      if (result == null) {
        return const ScrollFailure(
          reason: ScrollFailureReason.unknown,
          message: 'No response from getScrollInfo',
        );
      }

      if (result is Map) {
        return _parseScrollResult(Map<dynamic, dynamic>.from(result));
      }

      return const ScrollFailure(
        reason: ScrollFailureReason.unknown,
        message: 'Unexpected response type',
      );
    } on PlatformException catch (e) {
      if (systemErrorCodes.contains(e.code)) {
        rethrow;
      }
      return scrollFailureFromException(e);
    }
  }

  /// Helper method to parse scroll result from native response
  ScrollOperationResult _parseScrollResult(Map<dynamic, dynamic> result) {
    final success = result['success'] as bool? ?? false;

    if (success) {
      final scrollInfoMap = result['scrollInfo'] as Map?;
      if (scrollInfoMap != null) {
        final scrollInfo = ScrollInfo.fromMap(
          Map<String, dynamic>.from(scrollInfoMap),
        );
        return ScrollSuccess(scrollInfo);
      }
      return const ScrollFailure(
        reason: ScrollFailureReason.unknown,
        message: 'Missing scroll info in response',
      );
    } else {
      return scrollFailureFromState(result);
    }
  }
}
