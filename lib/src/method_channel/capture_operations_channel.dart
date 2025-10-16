import 'package:flutter/services.dart';

import '../models/capturable_window_info.dart';
import '../models/capture_result.dart';

/// Mixin providing method channel implementations for capture operations.
mixin CaptureOperationsChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<CaptureResult> captureWindow(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
    int? targetWidth,
    int? targetHeight,
    bool preserveAspectRatio = false,
  }) async {
    final arguments = <String, dynamic>{
      'windowId': windowId,
      'excludeTitlebar': excludeTitlebar,
      'preserveAspectRatio': preserveAspectRatio,
    };
    if (customTitlebarHeight != null) {
      arguments['customTitlebarHeight'] = customTitlebarHeight;
    }
    if (targetWidth != null) {
      arguments['targetWidth'] = targetWidth;
    }
    if (targetHeight != null) {
      arguments['targetHeight'] = targetHeight;
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

  Future<CaptureResult> captureWindowLegacy(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
    int? targetWidth,
    int? targetHeight,
    bool preserveAspectRatio = false,
  }) async {
    final arguments = <String, dynamic>{
      'windowId': windowId,
      'excludeTitlebar': excludeTitlebar,
      'preserveAspectRatio': preserveAspectRatio,
    };
    if (customTitlebarHeight != null) {
      arguments['customTitlebarHeight'] = customTitlebarHeight;
    }
    if (targetWidth != null) {
      arguments['targetWidth'] = targetWidth;
    }
    if (targetHeight != null) {
      arguments['targetHeight'] = targetHeight;
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

  Future<CaptureResult> captureWindowAuto(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
    int? targetWidth,
    int? targetHeight,
    bool preserveAspectRatio = false,
  }) async {
    final arguments = <String, dynamic>{
      'windowId': windowId,
      'excludeTitlebar': excludeTitlebar,
      'preserveAspectRatio': preserveAspectRatio,
    };
    if (customTitlebarHeight != null) {
      arguments['customTitlebarHeight'] = customTitlebarHeight;
    }
    if (targetWidth != null) {
      arguments['targetWidth'] = targetWidth;
    }
    if (targetHeight != null) {
      arguments['targetHeight'] = targetHeight;
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

  Future<Map<String, dynamic>> getCaptureMethodInfo() async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getCaptureMethodInfo',
    );
    if (result == null) {
      return {};
    }
    return Map<String, dynamic>.from(result);
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
