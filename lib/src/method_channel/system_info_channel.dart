import 'package:flutter/services.dart';
import '../models/macos_screen_info.dart';

/// Mixin providing method channel implementations for system info operations.
mixin SystemInfoChannel {
  /// Method channel accessor - must be provided by the implementing class.
  MethodChannel get methodChannel;

  Future<Map<String, dynamic>> getMacOSVersionInfo() async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getMacOSVersionInfo',
    );
    if (result == null) {
      return {};
    }
    return Map<String, dynamic>.from(result);
  }

  Future<double> getScreenScaleFactor() async {
    final result = await methodChannel.invokeMethod<double>(
      'getScreenScaleFactor',
    );
    return result ?? 1.0;
  }

  Future<List<MacosScreenInfo>> getAllScreensInfo() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getAllScreensInfo',
    );
    if (result == null) {
      return [];
    }
    return result
        .map((e) => MacosScreenInfo.fromMap(_convertMap(e as Map)))
        .toList();
  }

  Map<String, dynamic> _convertMap(Map map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertMap(value));
      }
      return MapEntry(key.toString(), value);
    });
  }
}
