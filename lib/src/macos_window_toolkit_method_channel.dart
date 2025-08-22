import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'macos_window_toolkit_platform_interface.dart';

/// An implementation of [MacosWindowToolkitPlatform] that uses method channels.
class MethodChannelMacosWindowToolkit extends MacosWindowToolkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('macos_window_toolkit');

  @override
  Future<List<Map<String, dynamic>>> getAllWindows() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>('getAllWindows');
    if (result == null) {
      return [];
    }
    return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Future<bool> hasScreenRecordingPermission() async {
    final result = await methodChannel.invokeMethod<bool>('hasScreenRecordingPermission');
    return result ?? false;
  }

  @override
  Future<bool> requestScreenRecordingPermission() async {
    final result = await methodChannel.invokeMethod<bool>('requestScreenRecordingPermission');
    return result ?? false;
  }

  @override
  Future<bool> openScreenRecordingSettings() async {
    final result = await methodChannel.invokeMethod<bool>('openScreenRecordingSettings');
    return result ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getWindowsByName(String name) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowsByName',
      {'name': name},
    );
    if (result == null) {
      return [];
    }
    return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getWindowsByOwnerName(String ownerName) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowsByOwnerName',
      {'ownerName': ownerName},
    );
    if (result == null) {
      return [];
    }
    return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getWindowById(int windowId) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowById',
      {'windowId': windowId},
    );
    if (result == null) {
      return [];
    }
    return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getWindowsByProcessId(int processId) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getWindowsByProcessId',
      {'processId': processId},
    );
    if (result == null) {
      return [];
    }
    return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
