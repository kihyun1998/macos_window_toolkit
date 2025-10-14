import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'macos_window_toolkit_platform_interface.dart';
import 'models/capturable_window_info.dart';
import 'models/capture_result.dart';

/// An implementation of [MacosWindowToolkitPlatform] that uses method channels.
class MethodChannelMacosWindowToolkit extends MacosWindowToolkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('macos_window_toolkit');

  @override
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

  @override
  Future<bool> hasScreenRecordingPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasScreenRecordingPermission',
    );
    return result ?? false;
  }

  @override
  Future<bool> requestScreenRecordingPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'requestScreenRecordingPermission',
    );
    return result ?? false;
  }

  @override
  Future<bool> openScreenRecordingSettings() async {
    final result = await methodChannel.invokeMethod<bool>(
      'openScreenRecordingSettings',
    );
    return result ?? false;
  }

  @override
  Future<bool> hasAccessibilityPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'hasAccessibilityPermission',
    );
    return result ?? false;
  }

  @override
  Future<bool> requestAccessibilityPermission() async {
    final result = await methodChannel.invokeMethod<bool>(
      'requestAccessibilityPermission',
    );
    return result ?? false;
  }

  @override
  Future<bool> openAccessibilitySettings() async {
    final result = await methodChannel.invokeMethod<bool>(
      'openAccessibilitySettings',
    );
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
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
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

  @override
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

  @override
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

  @override
  Future<Map<String, dynamic>> getMacOSVersionInfo() async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getMacOSVersionInfo',
    );
    if (result == null) {
      return {};
    }
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<CaptureResult> captureWindow(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
  }) async {
    final arguments = <String, dynamic>{
      'windowId': windowId,
      'excludeTitlebar': excludeTitlebar,
    };
    if (customTitlebarHeight != null) {
      arguments['customTitlebarHeight'] = customTitlebarHeight;
    }

    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'captureWindow',
        arguments,
      );
      if (result == null) {
        return const CaptureFailure(
          reason: CaptureFailureReason.unknown,
          message: 'No data returned from capture',
        );
      }

      return _parseCaptureResult(result);
    } on PlatformException catch (e) {
      // Only system errors should throw, others should return CaptureFailure
      if (_isSystemError(e.code)) {
        rethrow;
      }
      return _platformExceptionToCaptureFailure(e);
    }
  }

  @override
  Future<List<CapturableWindowInfo>> getCapturableWindows() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getCapturableWindows',
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) => CapturableWindowInfo.fromMap(map))
        .toList();
  }

  @override
  Future<CaptureResult> captureWindowLegacy(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
  }) async {
    final arguments = <String, dynamic>{
      'windowId': windowId,
      'excludeTitlebar': excludeTitlebar,
    };
    if (customTitlebarHeight != null) {
      arguments['customTitlebarHeight'] = customTitlebarHeight;
    }

    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'captureWindowLegacy',
        arguments,
      );
      if (result == null) {
        return const CaptureFailure(
          reason: CaptureFailureReason.unknown,
          message: 'No data returned from capture',
        );
      }

      return _parseCaptureResult(result);
    } on PlatformException catch (e) {
      // Only system errors should throw, others should return CaptureFailure
      if (_isSystemError(e.code)) {
        rethrow;
      }
      return _platformExceptionToCaptureFailure(e);
    }
  }

  @override
  Future<List<CapturableWindowInfo>> getCapturableWindowsLegacy() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getCapturableWindowsLegacy',
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) => CapturableWindowInfo.fromMap(map))
        .toList();
  }

  @override
  Future<CaptureResult> captureWindowAuto(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
  }) async {
    final arguments = <String, dynamic>{
      'windowId': windowId,
      'excludeTitlebar': excludeTitlebar,
    };
    if (customTitlebarHeight != null) {
      arguments['customTitlebarHeight'] = customTitlebarHeight;
    }

    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'captureWindowAuto',
        arguments,
      );
      if (result == null) {
        return const CaptureFailure(
          reason: CaptureFailureReason.unknown,
          message: 'No data returned from capture',
        );
      }

      return _parseCaptureResult(result);
    } on PlatformException catch (e) {
      // Only system errors should throw, others should return CaptureFailure
      if (_isSystemError(e.code)) {
        rethrow;
      }
      return _platformExceptionToCaptureFailure(e);
    }
  }

  @override
  Future<List<CapturableWindowInfo>> getCapturableWindowsAuto() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getCapturableWindowsAuto',
    );
    if (result == null) {
      return [];
    }
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((map) => CapturableWindowInfo.fromMap(map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getCaptureMethodInfo() async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getCaptureMethodInfo',
    );
    if (result == null) {
      return {};
    }
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<bool> isWindowAlive(int windowId) async {
    final result = await methodChannel.invokeMethod<bool>('isWindowAlive', {
      'windowId': windowId,
    });
    return result ?? false;
  }

  @override
  Future<bool> closeWindow(int windowId) async {
    final result = await methodChannel.invokeMethod<bool>('closeWindow', {
      'windowId': windowId,
    });
    return result ?? false;
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Future<bool> openAppStoreSearch(String searchTerm) async {
    final result = await methodChannel.invokeMethod<bool>(
      'openAppStoreSearch',
      {'searchTerm': searchTerm},
    );
    return result ?? false;
  }

  /// Helper method to parse capture result from native response
  CaptureResult _parseCaptureResult(Map<dynamic, dynamic> result) {
    final success = result['success'] as bool? ?? false;

    if (success) {
      final imageData = result['imageData'] as Uint8List?;
      if (imageData != null) {
        return CaptureSuccess(imageData);
      } else {
        return const CaptureFailure(
          reason: CaptureFailureReason.unknown,
          message: 'Success indicated but no image data received',
        );
      }
    } else {
      final reasonCode = result['reason'] as String? ?? 'unknown';
      final message = result['message'] as String?;
      final details = result['details'] as String?;

      final reason = _mapReasonCodeToFailureReason(reasonCode);
      return CaptureFailure(reason: reason, message: message, details: details);
    }
  }

  /// Maps native reason codes to CaptureFailureReason enum
  CaptureFailureReason _mapReasonCodeToFailureReason(String code) {
    switch (code) {
      case 'window_minimized':
        return CaptureFailureReason.windowMinimized;
      case 'window_not_found':
        return CaptureFailureReason.windowNotFound;
      case 'unsupported_version':
        return CaptureFailureReason.unsupportedVersion;
      case 'permission_denied':
        return CaptureFailureReason.permissionDenied;
      case 'capture_in_progress':
        return CaptureFailureReason.captureInProgress;
      case 'window_not_capturable':
        return CaptureFailureReason.windowNotCapturable;
      default:
        return CaptureFailureReason.unknown;
    }
  }

  /// Converts PlatformException to CaptureFailure for legacy error handling
  CaptureFailure _platformExceptionToCaptureFailure(PlatformException e) {
    final reason = _mapErrorCodeToFailureReason(e.code);
    return CaptureFailure(
      reason: reason,
      message: e.message,
      details: e.details?.toString(),
    );
  }

  /// Maps legacy error codes to CaptureFailureReason
  CaptureFailureReason _mapErrorCodeToFailureReason(String code) {
    switch (code) {
      case 'WINDOW_MINIMIZED':
        return CaptureFailureReason.windowMinimized;
      case 'INVALID_WINDOW_ID':
        return CaptureFailureReason.windowNotFound;
      case 'UNSUPPORTED_MACOS_VERSION':
        return CaptureFailureReason.unsupportedVersion;
      case 'PERMISSION_DENIED':
      case 'SCREEN_RECORDING_PERMISSION_DENIED':
        return CaptureFailureReason.permissionDenied;
      case 'CAPTURE_IN_PROGRESS':
        return CaptureFailureReason.captureInProgress;
      case 'WINDOW_NOT_CAPTURABLE':
        return CaptureFailureReason.windowNotCapturable;
      default:
        return CaptureFailureReason.unknown;
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
