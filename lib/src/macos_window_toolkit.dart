library;

import 'dart:typed_data';

import 'macos_window_toolkit_platform_interface.dart';
import 'models/capturable_window_info.dart';
import 'models/macos_window_info.dart';
import 'models/macos_version_info.dart';

export 'macos_window_toolkit_method_channel.dart';
export 'macos_window_toolkit_platform_interface.dart';
export 'models/capturable_window_info.dart';
export 'models/macos_window_info.dart';
export 'models/macos_version_info.dart';

/// Main class for macOS Window Toolkit functionality
class MacosWindowToolkit {
  /// Retrieves information about all windows currently open on the system.
  ///
  /// Returns a list of [MacosWindowInfo] objects containing window properties.
  /// Each window includes basic properties like position, size, title, and
  /// additional properties like transparency, workspace, and memory usage.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final windows = await toolkit.getAllWindows();
  /// for (final window in windows) {
  ///   print('Window: ${window.name} (ID: ${window.windowId})');
  ///   print('App: ${window.ownerName}');
  ///   print('Position: (${window.x}, ${window.y})');
  ///   print('Size: ${window.width} x ${window.height}');
  ///   if (window.alpha != null) {
  ///     print('Transparency: ${window.alpha}');
  ///   }
  /// }
  /// ```
  ///
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<MacosWindowInfo>> getAllWindows() async {
    final List<Map<String, dynamic>> windowMaps = 
        await MacosWindowToolkitPlatform.instance.getAllWindows();
    return windowMaps.map((map) => MacosWindowInfo.fromMap(map)).toList();
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

  /// Retrieves windows filtered by name (window title).
  /// 
  /// Returns a list of [MacosWindowInfo] objects for windows whose
  /// name/title contains the specified [name] string. The search is case-sensitive
  /// and uses substring matching.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final chromeWindows = await toolkit.getWindowsByName('Chrome');
  /// for (final window in chromeWindows) {
  ///   print('Found Chrome window: ${window.name}');
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<MacosWindowInfo>> getWindowsByName(String name) async {
    final List<Map<String, dynamic>> windowMaps = 
        await MacosWindowToolkitPlatform.instance.getWindowsByName(name);
    return windowMaps.map((map) => MacosWindowInfo.fromMap(map)).toList();
  }

  /// Retrieves windows filtered by owner name (application name).
  /// 
  /// Returns a list of [MacosWindowInfo] objects for windows owned by
  /// applications whose name contains the specified [ownerName] string.
  /// The search is case-sensitive and uses substring matching.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final safariWindows = await toolkit.getWindowsByOwnerName('Safari');
  /// for (final window in safariWindows) {
  ///   print('Safari window: ${window.name}');
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<MacosWindowInfo>> getWindowsByOwnerName(String ownerName) async {
    final List<Map<String, dynamic>> windowMaps = 
        await MacosWindowToolkitPlatform.instance.getWindowsByOwnerName(ownerName);
    return windowMaps.map((map) => MacosWindowInfo.fromMap(map)).toList();
  }

  /// Retrieves a specific window by its window ID.
  /// 
  /// Returns a list containing the [MacosWindowInfo] with the specified [windowId].
  /// Returns an empty list if no window with the given ID is found.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final windows = await toolkit.getWindowById(12345);
  /// if (windows.isNotEmpty) {
  ///   print('Found window: ${windows.first.name}');
  /// } else {
  ///   print('Window not found');
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<MacosWindowInfo>> getWindowById(int windowId) async {
    final List<Map<String, dynamic>> windowMaps = 
        await MacosWindowToolkitPlatform.instance.getWindowById(windowId);
    return windowMaps.map((map) => MacosWindowInfo.fromMap(map)).toList();
  }

  /// Retrieves windows filtered by process ID.
  /// 
  /// Returns a list of [MacosWindowInfo] objects for windows owned by
  /// the application with the specified [processId].
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final appWindows = await toolkit.getWindowsByProcessId(1234);
  /// print('Found ${appWindows.length} windows for process 1234');
  /// ```
  /// 
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<MacosWindowInfo>> getWindowsByProcessId(int processId) async {
    final List<Map<String, dynamic>> windowMaps = 
        await MacosWindowToolkitPlatform.instance.getWindowsByProcessId(processId);
    return windowMaps.map((map) => MacosWindowInfo.fromMap(map)).toList();
  }

  /// Gets macOS version information.
  /// 
  /// Returns a [MacosVersionInfo] object containing:
  /// - `majorVersion`: Major version number (e.g., 13 for macOS Ventura)
  /// - `minorVersion`: Minor version number (e.g., 0 for 13.0)
  /// - `patchVersion`: Patch version number (e.g., 1 for 13.0.1)
  /// - `versionString`: Full version string (e.g., "13.0.1")
  /// - `isScreenCaptureKitAvailable`: Whether ScreenCaptureKit is available (macOS 12.3+)
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final versionInfo = await toolkit.getMacOSVersionInfo();
  /// print('macOS ${versionInfo.versionString}');
  /// print('ScreenCaptureKit available: ${versionInfo.isScreenCaptureKitAvailable}');
  /// 
  /// // Check if running on macOS 13 or later
  /// if (versionInfo.isAtLeast(13)) {
  ///   print('Running on macOS Ventura or later');
  /// }
  /// ```
  Future<MacosVersionInfo> getMacOSVersionInfo() async {
    final versionMap = await MacosWindowToolkitPlatform.instance.getMacOSVersionInfo();
    return MacosVersionInfo.fromMap(versionMap);
  }

  /// Captures a window using ScreenCaptureKit.
  /// 
  /// Returns the captured image as bytes in PNG format.
  /// 
  /// [windowId] is the unique identifier of the window to capture, which can be
  /// obtained from [getAllWindows], [getWindowById], or [getCapturableWindows].
  /// 
  /// This method uses ScreenCaptureKit (macOS 12.3+) which provides high-quality
  /// window captures with better performance and more accurate color reproduction
  /// compared to the legacy CGWindowListCreateImage method.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// 
  /// // First check if ScreenCaptureKit is available
  /// final versionInfo = await toolkit.getMacOSVersionInfo();
  /// if (versionInfo.isScreenCaptureKitAvailable) {
  ///   try {
  ///     final imageBytes = await toolkit.captureWindow(12345);
  ///     // Convert bytes to image and display
  ///     final image = Image.memory(imageBytes);
  ///   } catch (e) {
  ///     if (e is PlatformException && e.code == 'INVALID_WINDOW_ID') {
  ///       print('Window not found');
  ///     }
  ///   }
  /// } else {
  ///   // Fall back to CGWindowListCreateImage method
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] with the following error codes:
  /// - `UNSUPPORTED_MACOS_VERSION`: Current macOS version doesn't support ScreenCaptureKit (requires 12.3+)
  /// - `SCREENCAPTUREKIT_NOT_AVAILABLE`: ScreenCaptureKit framework is not available
  /// - `INVALID_WINDOW_ID`: Window with the specified ID was not found or is not capturable
  /// - `CAPTURE_NOT_SUPPORTED`: Window capture is not supported for this specific window
  /// - `CAPTURE_FAILED`: Window capture failed due to system restrictions or other errors
  Future<Uint8List> captureWindow(int windowId) async {
    return await MacosWindowToolkitPlatform.instance.captureWindow(windowId);
  }

  /// Gets list of capturable windows using ScreenCaptureKit.
  /// 
  /// Returns a list of [CapturableWindowInfo] objects that are specifically optimized
  /// for window capture operations. This method only returns windows that can
  /// actually be captured by ScreenCaptureKit, which may be a subset of windows
  /// returned by [getAllWindows].
  /// 
  /// This method is particularly useful when you want to present users with
  /// a list of windows they can capture, as it filters out system windows
  /// and other non-capturable elements.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// 
  /// try {
  ///   final capturableWindows = await toolkit.getCapturableWindows();
  ///   for (final window in capturableWindows) {
  ///     print('Capturable window: ${window.title} (ID: ${window.windowId})');
  ///     print('App: ${window.ownerName} (${window.bundleIdentifier})');
  ///     print('Size: ${window.frame.width} x ${window.frame.height}');
  ///   }
  /// } catch (e) {
  ///   if (e is PlatformException && e.code == 'UNSUPPORTED_MACOS_VERSION') {
  ///     print('ScreenCaptureKit not available on this macOS version');
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] with the following error codes:
  /// - `UNSUPPORTED_MACOS_VERSION`: Current macOS version doesn't support ScreenCaptureKit
  /// - `SCREENCAPTUREKIT_NOT_AVAILABLE`: ScreenCaptureKit framework is not available
  /// - `CAPTURE_FAILED`: Failed to retrieve capturable windows due to system restrictions
  Future<List<CapturableWindowInfo>> getCapturableWindows() async {
    return await MacosWindowToolkitPlatform.instance.getCapturableWindows();
  }
}
