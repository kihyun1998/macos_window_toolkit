import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'macos_window_toolkit_platform_interface.dart';

/// An implementation of [MacosWindowToolkitPlatform] that uses method channels.
class MethodChannelMacosWindowToolkit extends MacosWindowToolkitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('macos_window_toolkit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
