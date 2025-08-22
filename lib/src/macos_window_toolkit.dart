library;

import 'macos_window_toolkit_platform_interface.dart';

export 'macos_window_toolkit_method_channel.dart';
export 'macos_window_toolkit_platform_interface.dart';

/// Main class for macOS Window Toolkit functionality
class MacosWindowToolkit {
  /// Retrieves information about all windows currently open on the system.
  ///
  /// Returns a list of maps containing window properties:
  /// - `windowId`: Unique identifier for the window (int)
  /// - `name`: Window title/name (String)
  /// - `ownerName`: Name of the application that owns the window (String)
  /// - `bounds`: Window position and size as [x, y, width, height] (`List<double>`)
  /// - `layer`: Window layer level (int)
  /// - `isOnScreen`: Whether the window is currently visible on screen (bool)
  /// - `processId`: Process ID of the application that owns the window (int)
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final windows = await toolkit.getAllWindows();
  /// for (final window in windows) {
  ///   print('Window: ${window['name']} (ID: ${window['windowId']})');
  ///   print('App: ${window['ownerName']}');
  ///   print('Bounds: ${window['bounds']}');
  /// }
  /// ```
  ///
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getAllWindows() {
    return MacosWindowToolkitPlatform.instance.getAllWindows();
  }

  /// Checks if the app has screen recording permission.
  /// 
  /// Returns `true` if the app has been granted screen recording permission,
  /// `false` otherwise. On macOS versions prior to 10.15 (Catalina), this
  /// always returns `true` as screen recording permission is not required.
  /// 
  /// This is useful for checking permission status before calling [getAllWindows]
  /// to determine if window names will be available.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final hasPermission = await toolkit.hasScreenRecordingPermission();
  /// if (hasPermission) {
  ///   final windows = await toolkit.getAllWindows();
  ///   // Window names will be available
  /// } else {
  ///   // Consider requesting permission first
  ///   await toolkit.requestScreenRecordingPermission();
  /// }
  /// ```
  Future<bool> hasScreenRecordingPermission() {
    return MacosWindowToolkitPlatform.instance.hasScreenRecordingPermission();
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
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final granted = await toolkit.requestScreenRecordingPermission();
  /// if (granted) {
  ///   print('Permission granted! You may need to restart the app.');
  /// } else {
  ///   print('Permission denied. Window names may not be available.');
  /// }
  /// ```
  Future<bool> requestScreenRecordingPermission() {
    return MacosWindowToolkitPlatform.instance.requestScreenRecordingPermission();
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
  ///       print('Please enable screen recording permission and restart the app');
  ///     }
  ///   }
  /// }
  /// ```
  Future<bool> openScreenRecordingSettings() {
    return MacosWindowToolkitPlatform.instance.openScreenRecordingSettings();
  }
}
