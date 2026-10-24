import 'package:flutter/services.dart';

import '../models/capturable_window_info.dart';
import '../models/capture_result.dart';
import 'channel_calls.dart';
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
  }) {
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

    return invokeResult(
      methodChannel,
      'captureWindow',
      arguments: arguments,
      parse: _parseCaptureResult,
      fromException: captureFailureFromException,
      unknown: (message) => CaptureFailure(
          reason: CaptureFailureReason.unknown, message: message),
    );
  }

  Future<List<CapturableWindowInfo>> getCapturableWindows() {
    return invokeList(
      methodChannel,
      'getCapturableWindows',
      CapturableWindowInfo.fromMap,
    );
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
