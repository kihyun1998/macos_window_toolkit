import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'macos_window_toolkit_method_channel.dart';

abstract class MacosWindowToolkitPlatform extends PlatformInterface {
  /// Constructs a MacosWindowToolkitPlatform.
  MacosWindowToolkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static MacosWindowToolkitPlatform _instance = MethodChannelMacosWindowToolkit();

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

  /// Retrieves information about all windows currently open on the system.
  /// 
  /// Returns a list of maps containing window properties:
  /// - `windowId`: Unique identifier for the window (int)
  /// - `name`: Window title/name (String)
  /// - `ownerName`: Name of the application that owns the window (String)
  /// - `bounds`: Window position and size as [x, y, width, height] (List<double>)
  /// - `layer`: Window layer level (int)
  /// - `isOnScreen`: Whether the window is currently visible on screen (bool)
  /// - `processId`: Process ID of the application that owns the window (int)
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getAllWindows() {
    throw UnimplementedError('getAllWindows() has not been implemented.');
  }
}
