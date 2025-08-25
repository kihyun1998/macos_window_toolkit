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
  Future<Uint8List> captureWindow(int windowId, {bool excludeTitlebar = false}) async {
    return await MacosWindowToolkitPlatform.instance.captureWindow(windowId, excludeTitlebar: excludeTitlebar);
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

  /// Captures a window using CGWindowListCreateImage (legacy method).
  /// 
  /// Returns the captured image as bytes in PNG format.
  /// 
  /// [windowId] is the unique identifier of the window to capture, which can be
  /// obtained from [getAllWindows], [getWindowById], or [getCapturableWindowsLegacy].
  /// 
  /// This method uses the legacy CGWindowListCreateImage API which is available
  /// on all macOS versions (10.5+) but may have lower quality or performance
  /// compared to ScreenCaptureKit. Use this method when you need compatibility
  /// with older macOS versions or when ScreenCaptureKit is not available.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// 
  /// try {
  ///   final imageBytes = await toolkit.captureWindowLegacy(12345);
  ///   // Convert bytes to image and display
  ///   final image = Image.memory(imageBytes);
  /// } catch (e) {
  ///   if (e is PlatformException && e.code == 'INVALID_WINDOW_ID') {
  ///     print('Window not found');
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] with the following error codes:
  /// - `INVALID_WINDOW_ID`: Window with the specified ID was not found or is not capturable
  /// - `CAPTURE_NOT_SUPPORTED`: Window capture is not supported for this specific window
  /// - `CAPTURE_FAILED`: Window capture failed due to system restrictions or other errors
  Future<Uint8List> captureWindowLegacy(int windowId) async {
    return await MacosWindowToolkitPlatform.instance.captureWindowLegacy(windowId);
  }

  /// Gets list of capturable windows using CGWindowListCopyWindowInfo (legacy method).
  /// 
  /// Returns a list of [CapturableWindowInfo] objects using the legacy
  /// CGWindowListCopyWindowInfo API. This method is available on all macOS
  /// versions and provides broader compatibility compared to ScreenCaptureKit.
  /// 
  /// Note that the window information returned by this method may differ
  /// slightly from [getCapturableWindows] as it uses different underlying APIs.
  /// The bundleIdentifier field will be empty as CGWindowListCopyWindowInfo
  /// does not provide bundle information.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// 
  /// final capturableWindows = await toolkit.getCapturableWindowsLegacy();
  /// for (final window in capturableWindows) {
  ///   print('Capturable window: ${window.title} (ID: ${window.windowId})');
  ///   print('App: ${window.ownerName}');
  ///   print('Size: ${window.frame.width} x ${window.frame.height}');
  /// }
  /// ```
  /// 
  /// This method always succeeds and does not throw exceptions. Returns an
  /// empty list if no windows are found.
  Future<List<CapturableWindowInfo>> getCapturableWindowsLegacy() async {
    return await MacosWindowToolkitPlatform.instance.getCapturableWindowsLegacy();
  }

  /// Captures a window using the best available method (auto-selection).
  /// 
  /// Returns the captured image as bytes in PNG format.
  /// 
  /// [windowId] is the unique identifier of the window to capture, which can be
  /// obtained from [getAllWindows], [getWindowById], or [getCapturableWindowsAuto].
  /// 
  /// This method automatically selects the optimal capture method:
  /// - Uses ScreenCaptureKit on macOS 14.0+ for best quality
  /// - Falls back to CGWindowListCreateImage on older versions or if ScreenCaptureKit fails
  /// 
  /// This is the **recommended method** for window capture as it provides the best
  /// experience across all macOS versions without requiring version checks.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// 
  /// try {
  ///   final imageBytes = await toolkit.captureWindowAuto(12345);
  ///   // Convert bytes to image and display
  ///   final image = Image.memory(imageBytes);
  /// } catch (e) {
  ///   if (e is PlatformException && e.code == 'INVALID_WINDOW_ID') {
  ///     print('Window not found');
  ///   } else if (e is PlatformException && e.code == 'NO_COMPATIBLE_CAPTURE_METHOD') {
  ///     print('No capture method available on this system');
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] with the following error codes:
  /// - `NO_COMPATIBLE_CAPTURE_METHOD`: No capture method is available
  /// - `CAPTURE_METHOD_FAILED`: The selected capture method failed
  /// - `INVALID_WINDOW_ID`: Window with the specified ID was not found
  Future<Uint8List> captureWindowAuto(int windowId, {bool excludeTitlebar = false}) async {
    return await MacosWindowToolkitPlatform.instance.captureWindowAuto(windowId, excludeTitlebar: excludeTitlebar);
  }

  /// Gets list of capturable windows using the best available method (auto-selection).
  /// 
  /// Returns a list of [CapturableWindowInfo] objects optimized for the current system.
  /// 
  /// This method automatically selects the optimal window listing method:
  /// - Uses ScreenCaptureKit on macOS 12.3+ for better window information
  /// - Falls back to CGWindowListCopyWindowInfo on older versions or if ScreenCaptureKit fails
  /// 
  /// This is the **recommended method** for getting capturable windows as it provides
  /// the best experience across all macOS versions without requiring version checks.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// 
  /// try {
  ///   final capturableWindows = await toolkit.getCapturableWindowsAuto();
  ///   for (final window in capturableWindows) {
  ///     print('Capturable window: ${window.title} (ID: ${window.windowId})');
  ///     print('App: ${window.ownerName} (${window.bundleIdentifier})');
  ///     print('Size: ${window.frame.width} x ${window.frame.height}');
  ///   }
  /// } catch (e) {
  ///   if (e is PlatformException && e.code == 'NO_COMPATIBLE_CAPTURE_METHOD') {
  ///     print('No window listing method available on this system');
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] with the following error codes:
  /// - `NO_COMPATIBLE_CAPTURE_METHOD`: No window listing method is available
  /// - `CAPTURE_METHOD_FAILED`: The selected window listing method failed
  Future<List<CapturableWindowInfo>> getCapturableWindowsAuto() async {
    return await MacosWindowToolkitPlatform.instance.getCapturableWindowsAuto();
  }

  /// Gets information about the capture method that would be used by auto-selection.
  /// 
  /// Returns information about the capture capabilities and methods that would be
  /// selected on the current system. This is useful for debugging, user feedback,
  /// and understanding the capture behavior.
  /// 
  /// The returned map contains:
  /// - `captureMethod`: The capture method that would be used ("ScreenCaptureKit" or "CGWindowListCreateImage")
  /// - `windowListMethod`: The window listing method that would be used ("ScreenCaptureKit" or "CGWindowListCopyWindowInfo")
  /// - `macOSVersion`: Current macOS version string (e.g., "14.0.1")
  /// - `isScreenCaptureKitAvailable`: Whether ScreenCaptureKit framework is available (bool)
  /// - `supportsModernCapture`: Whether modern capture (ScreenCaptureKit) is supported (bool)
  /// - `supportsModernWindowList`: Whether modern window listing (ScreenCaptureKit) is supported (bool)
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final info = await toolkit.getCaptureMethodInfo();
  /// 
  /// print('Capture method: ${info['captureMethod']}');
  /// print('Window list method: ${info['windowListMethod']}');
  /// print('macOS version: ${info['macOSVersion']}');
  /// print('ScreenCaptureKit available: ${info['isScreenCaptureKitAvailable']}');
  /// print('Modern capture supported: ${info['supportsModernCapture']}');
  /// print('Modern window list supported: ${info['supportsModernWindowList']}');
  /// 
  /// // Show user-friendly message
  /// if (info['supportsModernCapture'] == true) {
  ///   print('Using high-quality ScreenCaptureKit capture');
  /// } else {
  ///   print('Using compatible CGWindowListCreateImage capture');
  /// }
  /// ```
  Future<Map<String, dynamic>> getCaptureMethodInfo() async {
    return await MacosWindowToolkitPlatform.instance.getCaptureMethodInfo();
  }

  /// Checks if a window with the specified ID is currently alive/exists.
  /// 
  /// Returns `true` if the window exists and is currently available on the system,
  /// `false` otherwise.
  /// 
  /// [windowId] is the unique identifier of the window to check, which can be
  /// obtained from [getAllWindows], [getWindowsByName], or other window listing methods.
  /// 
  /// This method is useful for verifying if a window is still valid before
  /// attempting operations like capture or other window manipulations. It's 
  /// particularly important for long-running applications where windows may
  /// be closed by users or applications.
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final windows = await toolkit.getAllWindows();
  /// 
  /// for (final window in windows) {
  ///   // Check if window is still alive before capturing
  ///   final isAlive = await toolkit.isWindowAlive(window.windowId);
  ///   if (isAlive) {
  ///     try {
  ///       final imageBytes = await toolkit.captureWindow(window.windowId);
  ///       // Process captured image
  ///     } catch (e) {
  ///       print('Failed to capture window: ${window.name}');
  ///     }
  ///   } else {
  ///     print('Window ${window.name} is no longer available');
  ///   }
  /// }
  /// ```
  /// 
  /// This method is lightweight and fast as it performs a simple existence check
  /// without retrieving full window information.
  Future<bool> isWindowAlive(int windowId) async {
    return await MacosWindowToolkitPlatform.instance.isWindowAlive(windowId);
  }

  /// Closes a window by its window ID using AppleScript.
  /// 
  /// Returns `true` if the window was successfully closed, `false` otherwise.
  /// 
  /// [windowId] is the unique identifier of the window to close, which can be
  /// obtained from [getAllWindows], [getWindowsByName], or other window listing methods.
  /// 
  /// This method uses AppleScript to interact with the application's window
  /// close button. It first retrieves the window information to get the
  /// application name and window title, then executes an AppleScript to
  /// click the close button.
  /// 
  /// **Important Notes:**
  /// - This method may require accessibility permissions on some systems
  /// - It may not work with all applications depending on their AppleScript support
  /// - The success depends on the application's window structure and close button availability
  /// - Some applications may show confirmation dialogs before closing
  /// 
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final windows = await toolkit.getAllWindows();
  /// 
  /// for (final window in windows) {
  ///   if (window.name.contains('Untitled')) {
  ///     try {
  ///       final success = await toolkit.closeWindow(window.windowId);
  ///       if (success) {
  ///         print('Successfully closed window: ${window.name}');
  ///       } else {
  ///         print('Failed to close window: ${window.name}');
  ///       }
  ///     } catch (e) {
  ///       if (e is PlatformException) {
  ///         print('Error closing window: ${e.code} - ${e.message}');
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  /// 
  /// Throws [PlatformException] with the following error codes:
  /// - `CLOSE_WINDOW_ERROR`: General window closing error
  /// - `WINDOW_NOT_FOUND`: Window with the specified ID was not found
  /// - `INSUFFICIENT_WINDOW_INFO`: Not enough window information to close the window
  /// - `APPLESCRIPT_EXECUTION_FAILED`: AppleScript execution failed
  Future<bool> closeWindow(int windowId) async {
    return await MacosWindowToolkitPlatform.instance.closeWindow(windowId);
  }
}
