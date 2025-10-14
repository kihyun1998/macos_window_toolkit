import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform_interface/macos_window_toolkit_platform_interface.dart';
import 'application_operations_channel.dart';
import 'capture_operations_channel.dart';
import 'permission_operations_channel.dart';
import 'system_info_channel.dart';
import 'window_operations_channel.dart';

/// An implementation of [MacosWindowToolkitPlatform] that uses method channels.
class MethodChannelMacosWindowToolkit extends MacosWindowToolkitPlatform
    with
        PermissionOperationsChannel,
        WindowOperationsChannel,
        CaptureOperationsChannel,
        ApplicationOperationsChannel,
        SystemInfoChannel {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  @override
  final methodChannel = const MethodChannel('macos_window_toolkit');
}
