import 'package:flutter/services.dart';

import '../models/macos_screen_info.dart';
import '../models/macos_version_info.dart';
import 'channel_calls.dart';

/// Mixin providing method channel implementations for system info operations.
mixin SystemInfoChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<MacosVersionInfo> getMacOSVersionInfo() async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getMacOSVersionInfo',
    );
    return MacosVersionInfo.fromMap(stringKeyed(result ?? const {}));
  }

  Future<double> getScreenScaleFactor() async {
    final result = await methodChannel.invokeMethod<double>(
      'getScreenScaleFactor',
    );
    return result ?? 1.0;
  }

  Future<List<MacosScreenInfo>> getAllScreensInfo() {
    return invokeList(
      methodChannel,
      'getAllScreensInfo',
      MacosScreenInfo.fromMap,
    );
  }
}
