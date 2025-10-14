import 'package:flutter/services.dart';

/// Mixin providing method channel implementations for application operations.
mixin ApplicationOperationsChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<bool> terminateApplicationByPID(
    int processId, {
    bool force = false,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'terminateApplicationByPID',
      {'processId': processId, 'force': force},
    );
    return result ?? false;
  }

  Future<bool> terminateApplicationTree(
    int processId, {
    bool force = false,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'terminateApplicationTree',
      {'processId': processId, 'force': force},
    );
    return result ?? false;
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
}
