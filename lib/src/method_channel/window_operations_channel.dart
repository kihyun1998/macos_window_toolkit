import 'package:flutter/services.dart';

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
    String? ownerName,
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
    if (ownerName != null) args['ownerName'] = ownerName;
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

  Future<bool> isWindowAlive(int windowId) async {
    final result = await methodChannel.invokeMethod<bool>('isWindowAlive', {
      'windowId': windowId,
    });
    return result ?? false;
  }

  Future<bool> closeWindow(int windowId) async {
    final result = await methodChannel.invokeMethod<bool>('closeWindow', {
      'windowId': windowId,
    });
    return result ?? false;
  }
}
