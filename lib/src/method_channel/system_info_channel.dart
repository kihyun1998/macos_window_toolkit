import 'package:flutter/services.dart';

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
}
