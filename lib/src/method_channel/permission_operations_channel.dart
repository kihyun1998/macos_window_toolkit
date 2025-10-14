import 'package:flutter/services.dart';

/// Mixin providing method channel implementations for permission operations.
mixin PermissionOperationsChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<bool> hasScreenRecordingPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasScreenRecordingPermission',
    );
    return result ?? false;
  }

  Future<bool> requestScreenRecordingPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'requestScreenRecordingPermission',
    );
    return result ?? false;
  }

  Future<bool> openScreenRecordingSettings() async {
    final result = await methodChannel.invokeMethod<bool>(
      'openScreenRecordingSettings',
    );
    return result ?? false;
  }

  Future<bool> hasAccessibilityPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasAccessibilityPermission',
    );
    return result ?? false;
  }

  Future<bool> requestAccessibilityPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'requestAccessibilityPermission',
    );
    return result ?? false;
  }

  Future<bool> openAccessibilitySettings() async {
    final result = await methodChannel.invokeMethod<bool>(
      'openAccessibilitySettings',
    );
    return result ?? false;
  }
}
