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

  /// Checks if the app has screen recording permission.
  /// 
  /// Returns `true` if the app has been granted screen recording permission,
  /// `false` otherwise. On macOS versions prior to 10.15 (Catalina), this
  /// always returns `true` as screen recording permission is not required.
  /// 
  /// This is useful for checking permission status before calling [getAllWindows]
  /// to determine if window names will be available.
  Future<bool> hasScreenRecordingPermission() {
    throw UnimplementedError('hasScreenRecordingPermission() has not been implemented.');
  }

  /// Requests screen recording permission from the user.
  /// 
  /// Shows a system dialog asking for screen recording permission. If the user
  /// clicks "Open System Preferences", they will be taken directly to the
  /// Screen Recording section of Privacy settings.
  /// 
  /// Returns `true` if permission is granted, `false` if denied.
  /// 
  /// Note: The system dialog will only appear once per app session. If the user
  /// has already seen and dismissed the dialog, subsequent calls will not show
  /// the dialog again until the app is restarted.
  /// 
  /// On macOS versions prior to 10.15 (Catalina), this always returns `true`
  /// as screen recording permission is not required.
  Future<bool> requestScreenRecordingPermission() {
    throw UnimplementedError('requestScreenRecordingPermission() has not been implemented.');
  }

  /// Opens the Screen Recording section in System Preferences.
  /// 
  /// This method will attempt to open the specific Screen Recording settings page.
  /// If that fails, it will fall back to opening the general Privacy & Security
  /// settings, and as a last resort, it will open System Preferences.
  /// 
  /// Returns `true` if System Preferences was opened successfully, `false` otherwise.
  /// 
  /// This is useful when the system permission dialog doesn't appear (e.g., when
  /// the user has already denied permission once) and you need to guide users
  /// to manually enable the permission.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final hasPermission = await toolkit.hasScreenRecordingPermission();
  /// 
  /// if (!hasPermission) {
  ///   final granted = await toolkit.requestScreenRecordingPermission();
  ///   if (!granted) {
  ///     // System dialog didn't appear or was denied
  ///     final opened = await toolkit.openScreenRecordingSettings();
  ///     if (opened) {
  ///       // Show user guidance message
  ///     }
  ///   }
  /// }
  /// ```
  Future<bool> openScreenRecordingSettings() {
    throw UnimplementedError('openScreenRecordingSettings() has not been implemented.');
  }

  /// Retrieves windows filtered by name (window title).
  /// 
  /// Returns a list of maps containing window properties for windows whose
  /// name/title contains the specified [name] string. The search is case-sensitive
  /// and uses substring matching.
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getWindowsByName(String name) {
    throw UnimplementedError('getWindowsByName() has not been implemented.');
  }

  /// Retrieves windows filtered by owner name (application name).
  /// 
  /// Returns a list of maps containing window properties for windows owned by
  /// applications whose name contains the specified [ownerName] string.
  /// The search is case-sensitive and uses substring matching.
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getWindowsByOwnerName(String ownerName) {
    throw UnimplementedError('getWindowsByOwnerName() has not been implemented.');
  }

  /// Retrieves a specific window by its window ID.
  /// 
  /// Returns a list containing the window with the specified [windowId].
  /// Returns an empty list if no window with the given ID is found.
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getWindowById(int windowId) {
    throw UnimplementedError('getWindowById() has not been implemented.');
  }

  /// Retrieves windows filtered by process ID.
  /// 
  /// Returns a list of maps containing window properties for windows owned by
  /// the application with the specified [processId].
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getWindowsByProcessId(int processId) {
    throw UnimplementedError('getWindowsByProcessId() has not been implemented.');
  }
}
