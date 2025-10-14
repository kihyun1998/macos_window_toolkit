import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../method_channel/macos_window_toolkit_method_channel.dart';
import 'application_operations_interface.dart';
import 'capture_operations_interface.dart';
import 'permission_operations_interface.dart';
import 'system_info_interface.dart';
import 'window_operations_interface.dart';

abstract class MacosWindowToolkitPlatform extends PlatformInterface
    implements
        PermissionOperationsInterface,
        WindowOperationsInterface,
        CaptureOperationsInterface,
        ApplicationOperationsInterface,
        SystemInfoInterface {
  /// Constructs a MacosWindowToolkitPlatform.
  MacosWindowToolkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static MacosWindowToolkitPlatform _instance =
      MethodChannelMacosWindowToolkit();

  /// The default instance of [MacosWindowToolkitPlatform] to use.
  ///
  /// Defaults to [MethodChannelMacosWindowToolkit].
  static MacosWindowToolkitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MacosWindowToolkitPlatform] when
  /// they register themselves.
  static set instance(MacosWindowToolkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
