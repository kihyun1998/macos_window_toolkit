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
