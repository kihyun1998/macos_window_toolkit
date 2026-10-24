import 'package:flutter/services.dart';

import '../models/capturable_window_info.dart';
import '../models/capture_result.dart';
import 'failure_codes.dart';

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
    int? cropContentWidth,
    int? cropContentHeight,
    int? cropX,
    int? cropY,
    int? cropWidth,
    int? cropHeight,
    bool resizeCroppedToWindowSize = true,
  }) async {
    final arguments = <String, dynamic>{
      'windowId': windowId,
      'excludeTitlebar': excludeTitlebar,
      'preserveAspectRatio': preserveAspectRatio,
      'resizeCroppedToWindowSize': resizeCroppedToWindowSize,
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
    if (cropContentWidth != null) {
      arguments['cropContentWidth'] = cropContentWidth;
    }
    if (cropContentHeight != null) {
      arguments['cropContentHeight'] = cropContentHeight;
    }
    if (cropX != null) {
      arguments['cropX'] = cropX;
    }
    if (cropY != null) {
      arguments['cropY'] = cropY;
    }
    if (cropWidth != null) {
      arguments['cropWidth'] = cropWidth;
    }
    if (cropHeight != null) {
      arguments['cropHeight'] = cropHeight;
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
      if (systemErrorCodes.contains(e.code)) {
        rethrow;
      }
      return captureFailureFromException(e);
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
      return captureFailureFromState(result);
    }
  }
}
