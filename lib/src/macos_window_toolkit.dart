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
}
