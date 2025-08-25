import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'macos_window_toolkit_method_channel.dart';
import 'models/capturable_window_info.dart';

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

  /// Gets macOS version information.
  /// 
  /// Returns a map containing:
  /// - `majorVersion`: Major version number (int)
  /// - `minorVersion`: Minor version number (int)
  /// - `patchVersion`: Patch version number (int)
  /// - `versionString`: Full version string (String)
  /// - `isScreenCaptureKitAvailable`: Whether ScreenCaptureKit is available (bool)
  Future<Map<String, dynamic>> getMacOSVersionInfo() {
    throw UnimplementedError('getMacOSVersionInfo() has not been implemented.');
  }

  /// Captures a window using ScreenCaptureKit.
  /// 
  /// Returns the captured image as bytes in PNG format.
  /// 
  /// [windowId] is the unique identifier of the window to capture.
  /// 
  /// Throws [PlatformException] with appropriate error codes:
  /// - `UNSUPPORTED_MACOS_VERSION`: macOS version does not support ScreenCaptureKit (requires 12.3+)
  /// - `SCREENCAPTUREKIT_NOT_AVAILABLE`: ScreenCaptureKit is not available
  /// - `INVALID_WINDOW_ID`: Window with the specified ID was not found
  /// - `CAPTURE_FAILED`: Window capture failed for other reasons
  /// 
  /// Example usage:
  /// ```dart
  /// try {
  ///   final imageBytes = await toolkit.captureWindow(12345);
  ///   // Use imageBytes to display or save the captured image
  /// } catch (e) {
  ///   if (e is PlatformException && e.code == 'UNSUPPORTED_MACOS_VERSION') {
  ///     // Fall back to CGWindowListCreateImage method
  ///   }
  /// }
  /// ```
  Future<Uint8List> captureWindow(int windowId, {bool excludeTitlebar = false}) {
    throw UnimplementedError('captureWindow() has not been implemented.');
  }

  /// Gets list of capturable windows using ScreenCaptureKit.
  /// 
  /// Returns a list of [CapturableWindowInfo] objects that are specifically optimized
  /// for window capture operations. This method only returns windows that can
  /// actually be captured by ScreenCaptureKit, which may be a subset of windows
  /// returned by [getAllWindows].
  /// 
  /// Throws [PlatformException] with appropriate error codes:
  /// - `UNSUPPORTED_MACOS_VERSION`: macOS version does not support ScreenCaptureKit
  /// - `SCREENCAPTUREKIT_NOT_AVAILABLE`: ScreenCaptureKit is not available
  /// - `CAPTURE_FAILED`: Failed to retrieve capturable windows
  Future<List<CapturableWindowInfo>> getCapturableWindows() {
    throw UnimplementedError('getCapturableWindows() has not been implemented.');
  }

  /// Captures a window using CGWindowListCreateImage (legacy method).
  /// 
  /// Returns the captured image as bytes in PNG format.
  /// 
  /// [windowId] is the unique identifier of the window to capture.
  /// 
  /// This method uses the legacy CGWindowListCreateImage API which is available
  /// on all macOS versions (10.5+) but may have lower quality or performance
  /// compared to ScreenCaptureKit.
  /// 
  /// Throws [PlatformException] with appropriate error codes:
  /// - `INVALID_WINDOW_ID`: Window with the specified ID was not found
  /// - `CAPTURE_FAILED`: Window capture failed for other reasons
  /// 
  /// Example usage:
  /// ```dart
  /// try {
  ///   final imageBytes = await toolkit.captureWindowLegacy(12345);
  ///   // Use imageBytes to display or save the captured image
  /// } catch (e) {
  ///   if (e is PlatformException && e.code == 'INVALID_WINDOW_ID') {
  ///     print('Window not found');
  ///   }
  /// }
  /// ```
  Future<Uint8List> captureWindowLegacy(int windowId) {
    throw UnimplementedError('captureWindowLegacy() has not been implemented.');
  }

  /// Gets list of capturable windows using CGWindowListCopyWindowInfo (legacy method).
  /// 
  /// Returns a list of [CapturableWindowInfo] objects using the legacy
  /// CGWindowListCopyWindowInfo API. This method is available on all macOS
  /// versions but may provide different window information compared to
  /// ScreenCaptureKit.
  /// 
  /// This method always succeeds and does not throw exceptions. Empty list
  /// is returned if no windows are found.
  Future<List<CapturableWindowInfo>> getCapturableWindowsLegacy() {
    throw UnimplementedError('getCapturableWindowsLegacy() has not been implemented.');
  }

  /// Captures a window using the best available method (auto-selection).
  /// 
  /// Automatically selects between ScreenCaptureKit and CGWindowListCreateImage
  /// based on macOS version and availability:
  /// - Uses ScreenCaptureKit on macOS 14.0+ for best quality
  /// - Falls back to CGWindowListCreateImage on older versions or if ScreenCaptureKit fails
  /// 
  /// Returns the captured image as bytes in PNG format.
  /// 
  /// [windowId] is the unique identifier of the window to capture.
  /// 
  /// This is the recommended method for window capture as it provides the best
  /// experience across all macOS versions.
  /// 
  /// Throws [PlatformException] with appropriate error codes:
  /// - `NO_COMPATIBLE_CAPTURE_METHOD`: No capture method is available
  /// - `CAPTURE_METHOD_FAILED`: The selected capture method failed
  /// - `INVALID_WINDOW_ID`: Window with the specified ID was not found
  /// 
  /// Example usage:
  /// ```dart
  /// try {
  ///   final imageBytes = await toolkit.captureWindowAuto(12345);
  ///   // Use imageBytes to display or save the captured image
  /// } catch (e) {
  ///   if (e is PlatformException && e.code == 'INVALID_WINDOW_ID') {
  ///     print('Window not found');
  ///   }
  /// }
  /// ```
  Future<Uint8List> captureWindowAuto(int windowId, {bool excludeTitlebar = false}) {
    throw UnimplementedError('captureWindowAuto() has not been implemented.');
  }

  /// Gets list of capturable windows using the best available method (auto-selection).
  /// 
  /// Automatically selects between ScreenCaptureKit and CGWindowListCopyWindowInfo
  /// based on macOS version and availability:
  /// - Uses ScreenCaptureKit on macOS 12.3+ for better window information
  /// - Falls back to CGWindowListCopyWindowInfo on older versions or if ScreenCaptureKit fails
  /// 
  /// Returns a list of [CapturableWindowInfo] objects optimized for the current system.
  /// This is the recommended method for getting capturable windows as it provides
  /// the best experience across all macOS versions.
  /// 
  /// Throws [PlatformException] with appropriate error codes:
  /// - `NO_COMPATIBLE_CAPTURE_METHOD`: No window listing method is available
  /// - `CAPTURE_METHOD_FAILED`: The selected window listing method failed
  Future<List<CapturableWindowInfo>> getCapturableWindowsAuto() {
    throw UnimplementedError('getCapturableWindowsAuto() has not been implemented.');
  }

  /// Gets information about the capture method that would be used by auto-selection.
  /// 
  /// Returns a map containing:
  /// - `captureMethod`: The capture method that would be used ("ScreenCaptureKit" or "CGWindowListCreateImage")
  /// - `windowListMethod`: The window listing method that would be used ("ScreenCaptureKit" or "CGWindowListCopyWindowInfo")
  /// - `macOSVersion`: Current macOS version string
  /// - `isScreenCaptureKitAvailable`: Whether ScreenCaptureKit framework is available (bool)
  /// - `supportsModernCapture`: Whether modern capture (ScreenCaptureKit) is supported (bool)
  /// - `supportsModernWindowList`: Whether modern window listing (ScreenCaptureKit) is supported (bool)
  /// 
  /// This method is useful for debugging and providing user feedback about
  /// the capture capabilities on their system.
  /// 
  /// Example usage:
  /// ```dart
  /// final info = await toolkit.getCaptureMethodInfo();
  /// print('Capture method: ${info['captureMethod']}');
  /// print('macOS version: ${info['macOSVersion']}');
  /// print('Modern capture supported: ${info['supportsModernCapture']}');
  /// ```
  Future<Map<String, dynamic>> getCaptureMethodInfo() {
    throw UnimplementedError('getCaptureMethodInfo() has not been implemented.');
  }

  /// Checks if a window with the specified ID is currently alive/exists.
  /// 
  /// Returns `true` if the window exists and is currently available on the system,
  /// `false` otherwise.
  /// 
  /// [windowId] is the unique identifier of the window to check.
  /// 
  /// This method is useful for verifying if a window is still valid before
  /// attempting operations like capture or manipulation.
  /// 
  /// Example usage:
  /// ```dart
  /// final isAlive = await toolkit.isWindowAlive(12345);
  /// if (isAlive) {
  ///   // Window exists, safe to perform operations
  ///   final imageBytes = await toolkit.captureWindow(12345);
  /// } else {
  ///   print('Window no longer exists');
  /// }
  /// ```
  Future<bool> isWindowAlive(int windowId) {
    throw UnimplementedError('isWindowAlive() has not been implemented.');
  }
}
