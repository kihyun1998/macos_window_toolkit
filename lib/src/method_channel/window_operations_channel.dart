import 'package:flutter/services.dart';

import '../models/macos_window_info.dart';
import '../models/scroll_info.dart';
import '../models/window_operation_result.dart';
import 'channel_calls.dart';
import 'failure_codes.dart';

/// Mixin providing method channel implementations for window operations.
mixin WindowOperationsChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<List<MacosWindowInfo>> getAllWindows({
    bool excludeEmptyNames = false,
  }) {
    return invokeList(
      methodChannel,
      'getAllWindows',
      MacosWindowInfo.fromMap,
      arguments:
          excludeEmptyNames ? {'excludeEmptyNames': excludeEmptyNames} : null,
    );
  }

  Future<List<MacosWindowInfo>> getWindowsByName(String name) {
    return invokeList(
      methodChannel,
      'getWindowsByName',
      MacosWindowInfo.fromMap,
      arguments: {'name': name},
    );
  }

  Future<List<MacosWindowInfo>> getWindowsByOwnerName(String ownerName) {
    return invokeList(
      methodChannel,
      'getWindowsByOwnerName',
      MacosWindowInfo.fromMap,
      arguments: {'ownerName': ownerName},
    );
  }

  Future<List<MacosWindowInfo>> getWindowById(int windowId) {
    return invokeList(
      methodChannel,
      'getWindowById',
      MacosWindowInfo.fromMap,
      arguments: {'windowId': windowId},
    );
  }

  Future<List<MacosWindowInfo>> getWindowsByProcessId(int processId) {
    return invokeList(
      methodChannel,
      'getWindowsByProcessId',
      MacosWindowInfo.fromMap,
      arguments: {'processId': processId},
    );
  }

  Future<List<MacosWindowInfo>> getWindowsAdvanced({
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
  }) {
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

    return invokeList(
      methodChannel,
      'getWindowsAdvanced',
      MacosWindowInfo.fromMap,
      arguments: args.isEmpty ? null : args,
    );
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

  Future<WindowOperationResult> closeWindow(
    int windowId, {
    Duration? waitUntilClosed,
  }) {
    if (waitUntilClosed != null && waitUntilClosed <= Duration.zero) {
      throw ArgumentError.value(
          waitUntilClosed, 'waitUntilClosed', 'must be positive');
    }
    return invokeOperation(methodChannel, 'closeWindow', {
      'windowId': windowId,
      if (waitUntilClosed != null)
        'waitUntilClosedMs': waitUntilClosed.inMilliseconds,
    });
  }

  Future<WindowOperationResult> focusWindow(int windowId) {
    return invokeOperation(
        methodChannel, 'focusWindow', {'windowId': windowId});
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

  Future<ScrollOperationResult> getScrollInfo(int windowId) {
    return invokeResult(
      methodChannel,
      'getScrollInfo',
      arguments: {'windowId': windowId},
      parse: _parseScrollResult,
      fromException: scrollFailureFromException,
      unknown: (message) =>
          ScrollFailure(reason: ScrollFailureReason.unknown, message: message),
    );
  }

  /// Helper method to parse scroll result from native response
  ScrollOperationResult _parseScrollResult(Map<dynamic, dynamic> result) {
    final success = result['success'] as bool? ?? false;

    if (success) {
      final scrollInfoMap = result['scrollInfo'] as Map?;
      if (scrollInfoMap != null) {
        return ScrollSuccess(ScrollInfo.fromMap(stringKeyed(scrollInfoMap)));
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
