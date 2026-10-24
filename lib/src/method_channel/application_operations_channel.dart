import 'package:flutter/services.dart';

import '../models/macos_application_info.dart';
import '../models/window_operation_result.dart';
import 'channel_calls.dart';

/// Mixin providing method channel implementations for application operations.
mixin ApplicationOperationsChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<WindowOperationResult> terminateApplicationByPID(
    int processId, {
    bool force = false,
  }) {
    return invokeOperation(
      methodChannel,
      'terminateApplicationByPID',
      {'processId': processId, 'force': force},
    );
  }

  Future<WindowOperationResult> terminateApplicationTree(
    int processId, {
    bool force = false,
  }) {
    return invokeOperation(
      methodChannel,
      'terminateApplicationTree',
      {'processId': processId, 'force': force},
    );
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

  Future<List<MacosApplicationInfo>> getAllInstalledApplications() {
    return invokeList(
      methodChannel,
      'getAllInstalledApplications',
      MacosApplicationInfo.fromMap,
    );
  }

  Future<List<MacosApplicationInfo>> getApplicationByName(String name) {
    return invokeList(
      methodChannel,
      'getApplicationByName',
      MacosApplicationInfo.fromMap,
      arguments: {'name': name},
    );
  }

  Future<bool> openAppStoreSearch(String searchTerm) async {
    final result = await methodChannel.invokeMethod<bool>(
      'openAppStoreSearch',
      {'searchTerm': searchTerm},
    );
    return result ?? false;
  }
}
