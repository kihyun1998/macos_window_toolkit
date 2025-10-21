library;

import 'platform_interface/macos_window_toolkit_platform_interface.dart';
import 'models/capturable_window_info.dart';
import 'models/capture_result.dart';
import 'models/macos_application_info.dart';
import 'models/macos_version_info.dart';
import 'models/macos_window_info.dart';
import 'models/permission_status.dart';
import 'models/window_operation_result.dart';
import 'permission_watcher.dart';

export 'method_channel/macos_window_toolkit_method_channel.dart';
export 'platform_interface/macos_window_toolkit_platform_interface.dart';
export 'models/capturable_window_info.dart';
export 'models/capture_result.dart';
export 'models/macos_application_info.dart';
export 'models/macos_version_info.dart';
export 'models/macos_window_info.dart';

/// Main class for macOS Window Toolkit functionality
class MacosWindowToolkit {
  /// Retrieves information about all windows currently open on the system.
  ///
  /// Returns a list of [MacosWindowInfo] objects containing window properties.
  /// Each window includes basic properties like position, size, title, and
  /// additional properties like transparency, workspace, and memory usage.
  ///
  /// [excludeEmptyNames] if true, windows with empty or missing names will be
  /// filtered out from the results. This is useful when you only want windows
  /// that have actual titles.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Get all windows including those with empty names
  /// final allWindows = await toolkit.getAllWindows();
  ///
  /// // Get only windows with non-empty names
  /// final namedWindows = await toolkit.getAllWindows(excludeEmptyNames: true);
  ///
  /// for (final window in namedWindows) {
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
  Future<List<MacosWindowInfo>> getAllWindows({
    bool excludeEmptyNames = false,
  }) async {
    final List<Map<String, dynamic>> windowMaps =
        await MacosWindowToolkitPlatform.instance.getAllWindows(
      excludeEmptyNames: excludeEmptyNames,
    );
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
    return MacosWindowToolkitPlatform.instance
        .requestScreenRecordingPermission();
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

  /// Checks if the app has accessibility permission.
  ///
  /// Returns `true` if the app has been granted accessibility permission,
  /// `false` otherwise. Accessibility permissions are required for certain
  /// window operations that interact with other applications, such as
  /// [closeWindow].
  ///
  /// This method checks the current accessibility permission status without
  /// showing any dialogs or requesting permission.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final hasPermission = await toolkit.hasAccessibilityPermission();
  /// if (hasPermission) {
  ///   // Can perform accessibility-related operations
  ///   final success = await toolkit.closeWindow(windowId);
  /// } else {
  ///   // Need to request permission first
  ///   await toolkit.requestAccessibilityPermission();
  /// }
  /// ```
  Future<bool> hasAccessibilityPermission() {
    return MacosWindowToolkitPlatform.instance.hasAccessibilityPermission();
  }

  /// Requests accessibility permission from the user.
  ///
  /// Shows a system dialog asking for accessibility permission. The user will
  /// be prompted to enable accessibility for the application in System Preferences.
  ///
  /// Returns `true` if permission is granted, `false` if denied or not yet granted.
  ///
  /// Note: Unlike screen recording permission, accessibility permission requires
  /// the user to manually enable it in System Preferences. The system dialog
  /// will guide users to the correct settings page, but the permission must be
  /// granted manually by the user.
  ///
  /// After granting permission in System Preferences, the application may need
  /// to be restarted for the permission to take effect.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final granted = await toolkit.requestAccessibilityPermission();
  /// if (granted) {
  ///   print('Accessibility permission granted!');
  /// } else {
  ///   print('Accessibility permission denied or not yet granted.');
  ///   print('Please enable accessibility in System Preferences.');
  ///   // Optionally open settings for user
  ///   await toolkit.openAccessibilitySettings();
  /// }
  /// ```
  Future<bool> requestAccessibilityPermission() {
    return MacosWindowToolkitPlatform.instance.requestAccessibilityPermission();
  }

  /// Opens the Accessibility section in System Preferences.
  ///
  /// This method will attempt to open the specific Accessibility settings page.
  /// If that fails, it will fall back to opening the general Privacy & Security
  /// settings, and as a last resort, it will open System Preferences.
  ///
  /// Returns `true` if System Preferences was opened successfully, `false` otherwise.
  ///
  /// This is useful for guiding users to manually enable accessibility permission
  /// when the system permission dialog doesn't provide direct access to the settings.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final hasPermission = await toolkit.hasAccessibilityPermission();
  ///
  /// if (!hasPermission) {
  ///   final granted = await toolkit.requestAccessibilityPermission();
  ///   if (!granted) {
  ///     // Guide user to manually enable permission
  ///     final opened = await toolkit.openAccessibilitySettings();
  ///     if (opened) {
  ///       print('Please enable accessibility permission for this app');
  ///       print('and restart the application');
  ///     }
  ///   }
  /// }
  /// ```
  Future<bool> openAccessibilitySettings() {
    return MacosWindowToolkitPlatform.instance.openAccessibilitySettings();
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
        await MacosWindowToolkitPlatform.instance.getWindowsByOwnerName(
      ownerName,
    );
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
        await MacosWindowToolkitPlatform.instance.getWindowsByProcessId(
      processId,
    );
    return windowMaps.map((map) => MacosWindowInfo.fromMap(map)).toList();
  }

  /// Retrieves windows with advanced filtering options.
  ///
  /// Returns a list of [MacosWindowInfo] objects for windows that match all
  /// specified filter criteria. All parameters are optional - only non-null
  /// parameters are used for filtering, and all conditions are combined with AND logic.
  ///
  /// This method provides flexible window filtering, allowing you to combine
  /// multiple criteria to find exactly the windows you need. It's more powerful
  /// and convenient than using individual filter methods.
  ///
  /// Parameters:
  /// - [windowId]: Filter by exact window ID
  /// - [name]: Filter by window title (substring match by default)
  /// - [nameExactMatch]: If true, name must match exactly. If false (default), uses substring matching.
  /// - [nameCaseSensitive]: If true (default), name matching is case sensitive.
  /// - [nameWildcard]: If true, enables wildcard matching for name (* for any characters, ? for single character).
  /// - [ownerName]: Filter by application name (substring match by default)
  /// - [ownerNameExactMatch]: If true, ownerName must match exactly. If false (default), uses substring matching.
  /// - [ownerNameCaseSensitive]: If true (default), ownerName matching is case sensitive.
  /// - [ownerNameWildcard]: If true, enables wildcard matching for ownerName (* for any characters, ? for single character).
  /// - [processId]: Filter by exact process ID
  /// - [isOnScreen]: Filter by visibility on screen (true/false)
  /// - [layer]: Filter by exact window layer level
  /// - [x]: Filter by exact x coordinate
  /// - [y]: Filter by exact y coordinate
  /// - [width]: Filter by exact width
  /// - [height]: Filter by exact height
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Find all visible Chrome windows
  /// final chromeWindows = await toolkit.getWindowsAdvanced(
  ///   ownerName: 'Chrome',
  ///   isOnScreen: true,
  /// );
  ///
  /// // Find a specific window by ID and verify it's visible
  /// final windows = await toolkit.getWindowsAdvanced(
  ///   windowId: 12345,
  ///   isOnScreen: true,
  /// );
  ///
  /// // Find windows from a specific process with a title containing "Gmail"
  /// final gmailWindows = await toolkit.getWindowsAdvanced(
  ///   processId: 67890,
  ///   name: 'Gmail',
  /// );
  ///
  /// // Find Chrome with exact match (only "Google Chrome", not "Chrome Helper")
  /// final exactChrome = await toolkit.getWindowsAdvanced(
  ///   name: 'Google Chrome',
  ///   nameExactMatch: true,
  /// );
  ///
  /// // Find "chrome" case-insensitively (matches "Chrome", "CHROME", "chrome")
  /// final anyCaseChrome = await toolkit.getWindowsAdvanced(
  ///   name: 'chrome',
  ///   nameCaseSensitive: false,
  /// );
  ///
  /// // Exact match + case insensitive
  /// final exactInsensitive = await toolkit.getWindowsAdvanced(
  ///   ownerName: 'safari',
  ///   ownerNameExactMatch: true,
  ///   ownerNameCaseSensitive: false,
  /// );
  ///
  /// // Wildcard matching - "Chrom" prefix
  /// final chromWindows = await toolkit.getWindowsAdvanced(
  ///   name: 'Chrom*',
  ///   nameWildcard: true,
  /// );
  ///
  /// // Wildcard matching - suffix and case insensitive
  /// final gmailWindows = await toolkit.getWindowsAdvanced(
  ///   name: '*gmail',
  ///   nameWildcard: true,
  ///   nameCaseSensitive: false,
  /// );
  ///
  /// // Wildcard matching - single character wildcard
  /// final safariWindows = await toolkit.getWindowsAdvanced(
  ///   name: 'Saf?ri',
  ///   nameWildcard: true,
  /// );
  /// ```
  ///
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<MacosWindowInfo>> getWindowsAdvanced({
    int? windowId,
    String? name,
    bool? nameExactMatch,
    bool? nameCaseSensitive,
    bool? nameWildcard,
    String? ownerName,
    bool? ownerNameExactMatch,
    bool? ownerNameCaseSensitive,
    bool? ownerNameWildcard,
    int? processId,
    bool? isOnScreen,
    int? layer,
    double? x,
    double? y,
    double? width,
    double? height,
  }) async {
    final List<Map<String, dynamic>> windowMaps =
        await MacosWindowToolkitPlatform.instance.getWindowsAdvanced(
      windowId: windowId,
      name: name,
      nameExactMatch: nameExactMatch,
      nameCaseSensitive: nameCaseSensitive,
      nameWildcard: nameWildcard,
      ownerName: ownerName,
      ownerNameExactMatch: ownerNameExactMatch,
      ownerNameCaseSensitive: ownerNameCaseSensitive,
      ownerNameWildcard: ownerNameWildcard,
      processId: processId,
      isOnScreen: isOnScreen,
      layer: layer,
      x: x,
      y: y,
      width: width,
      height: height,
    );
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
    final versionMap =
        await MacosWindowToolkitPlatform.instance.getMacOSVersionInfo();
    return MacosVersionInfo.fromMap(versionMap);
  }

  /// Captures a window using ScreenCaptureKit.
  ///
  /// Returns a [CaptureResult] indicating success with image data or failure with reason.
  ///
  /// [windowId] is the unique identifier of the window to capture, which can be
  /// obtained from [getAllWindows], [getWindowById], or [getCapturableWindows].
  ///
  /// [excludeTitlebar] if true, removes the titlebar from the captured image.
  ///
  /// [customTitlebarHeight] specifies a custom titlebar height to remove (in points).
  /// If null and excludeTitlebar is true, uses the default 28pt titlebar height.
  /// Must be non-negative and not larger than the window height.
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
  ///   final result = await toolkit.captureWindow(12345);
  ///   switch (result) {
  ///     case CaptureSuccess(imageData: final data):
  ///       // Convert bytes to image and display
  ///       final image = Image.memory(data);
  ///       break;
  ///     case CaptureFailure(reason: CaptureFailureReason.windowMinimized):
  ///       print('Window is minimized');
  ///       break;
  ///     case CaptureFailure(reason: CaptureFailureReason.permissionDenied):
  ///       print('Permission denied');
  ///       break;
  ///   }
  /// } else {
  ///   // Fall back to CGWindowListCreateImage method
  /// }
  /// ```
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, system failures).
  Future<CaptureResult> captureWindow(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
    int? targetWidth,
    int? targetHeight,
    bool preserveAspectRatio = false,
  }) async {
    return await MacosWindowToolkitPlatform.instance.captureWindow(
      windowId,
      excludeTitlebar: excludeTitlebar,
      customTitlebarHeight: customTitlebarHeight,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      preserveAspectRatio: preserveAspectRatio,
    );
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
  /// Returns a [CaptureResult] indicating success with image data or failure with reason.
  ///
  /// [windowId] is the unique identifier of the window to capture, which can be
  /// obtained from [getAllWindows], [getWindowById], or [getCapturableWindowsLegacy].
  ///
  /// [excludeTitlebar] if true, removes the titlebar from the captured image.
  ///
  /// [customTitlebarHeight] specifies a custom titlebar height to remove (in points).
  /// If null and excludeTitlebar is true, uses the default 28pt titlebar height.
  /// Must be non-negative and not larger than the window height.
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
  /// final result = await toolkit.captureWindowLegacy(12345);
  /// switch (result) {
  ///   case CaptureSuccess(imageData: final data):
  ///     // Convert bytes to image and display
  ///     final image = Image.memory(data);
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.windowNotFound):
  ///     print('Window not found');
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.windowMinimized):
  ///     print('Window is minimized');
  ///     break;
  /// }
  /// ```
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, system failures).
  Future<CaptureResult> captureWindowLegacy(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
    int? targetWidth,
    int? targetHeight,
    bool preserveAspectRatio = false,
  }) async {
    return await MacosWindowToolkitPlatform.instance.captureWindowLegacy(
      windowId,
      excludeTitlebar: excludeTitlebar,
      customTitlebarHeight: customTitlebarHeight,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      preserveAspectRatio: preserveAspectRatio,
    );
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
    return await MacosWindowToolkitPlatform.instance
        .getCapturableWindowsLegacy();
  }

  /// Captures a window using the best available method (auto-selection).
  ///
  /// Returns a [CaptureResult] indicating success with image data or failure with reason.
  ///
  /// [windowId] is the unique identifier of the window to capture, which can be
  /// obtained from [getAllWindows], [getWindowById], or [getCapturableWindowsAuto].
  ///
  /// [excludeTitlebar] if true, removes the titlebar from the captured image.
  ///
  /// [customTitlebarHeight] specifies a custom titlebar height to remove (in points).
  /// If null and excludeTitlebar is true, uses the default 28pt titlebar height.
  /// Must be non-negative and not larger than the window height.
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
  /// final result = await toolkit.captureWindowAuto(12345);
  /// switch (result) {
  ///   case CaptureSuccess(imageData: final data):
  ///     // Convert bytes to image and display
  ///     final image = Image.memory(data);
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.windowNotFound):
  ///     print('Window not found');
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.windowMinimized):
  ///     print('Window is minimized');
  ///     break;
  ///   case CaptureFailure(reason: CaptureFailureReason.permissionDenied):
  ///     print('Permission denied');
  ///     break;
  /// }
  /// ```
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, system failures).
  Future<CaptureResult> captureWindowAuto(
    int windowId, {
    bool excludeTitlebar = false,
    double? customTitlebarHeight,
    int? targetWidth,
    int? targetHeight,
    bool preserveAspectRatio = false,
  }) async {
    return await MacosWindowToolkitPlatform.instance.captureWindowAuto(
      windowId,
      excludeTitlebar: excludeTitlebar,
      customTitlebarHeight: customTitlebarHeight,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      preserveAspectRatio: preserveAspectRatio,
    );
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
  /// [expectedName] is an optional window name to verify. If provided, the method
  /// will also check that the window's name matches this value. This is useful
  /// for ensuring the window ID hasn't been reused by a different window, as
  /// macOS may reuse window IDs after a window is closed.
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
  ///   // Check if window is still alive before capturing (ID only)
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
  ///
  /// // For more safety, verify both ID and name to prevent window ID reuse issues
  /// final window = windows.first;
  /// final isAliveWithName = await toolkit.isWindowAlive(
  ///   window.windowId,
  ///   expectedName: window.name,
  /// );
  /// if (isAliveWithName) {
  ///   print('Window exists and name matches - safe to proceed');
  /// } else {
  ///   print('Window not found or name changed (ID may have been reused)');
  /// }
  /// ```
  ///
  /// This method is lightweight and fast as it performs a simple existence check
  /// without retrieving full window information.
  Future<bool> isWindowAlive(int windowId, {String? expectedName}) async {
    return await MacosWindowToolkitPlatform.instance.isWindowAlive(
      windowId,
      expectedName: expectedName,
    );
  }

  /// Closes a window by its window ID using Accessibility API.
  ///
  /// Returns a [WindowOperationResult] indicating success or failure with details.
  ///
  /// [windowId] is the unique identifier of the window to close, which can be
  /// obtained from [getAllWindows], [getWindowsByName], or other window listing methods.
  ///
  /// This method uses the Accessibility API to interact with the application's
  /// window close button. It first retrieves the window information to get the
  /// application name and window title, then attempts to close the window.
  ///
  /// **Important Notes:**
  /// - This method requires accessibility permissions
  /// - The success depends on the application's window structure and close button availability
  /// - Some applications may show confirmation dialogs before closing
  ///
  /// Returns:
  /// - [OperationSuccess] if the window was successfully closed
  /// - [OperationFailure] with one of the following reasons:
  ///   - [WindowOperationFailureReason.windowNotFound]: Window no longer exists
  ///   - [WindowOperationFailureReason.accessibilityPermissionDenied]: Permission not granted
  ///   - [WindowOperationFailureReason.closeButtonNotFound]: Unable to find close button
  ///   - [WindowOperationFailureReason.unknown]: Other failure states
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, internal errors).
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final windows = await toolkit.getAllWindows();
  ///
  /// for (final window in windows) {
  ///   if (window.name.contains('Untitled')) {
  ///     final result = await toolkit.closeWindow(window.windowId);
  ///     switch (result) {
  ///       case OperationSuccess():
  ///         print('Successfully closed window: ${window.name}');
  ///       case OperationFailure(:final reason, :final message):
  ///         if (reason == WindowOperationFailureReason.accessibilityPermissionDenied) {
  ///           print('Need accessibility permission');
  ///           await toolkit.requestAccessibilityPermission();
  ///         } else {
  ///           print('Failed to close window: $message');
  ///         }
  ///     }
  ///   }
  /// }
  /// ```
  Future<WindowOperationResult> closeWindow(int windowId) async {
    return await MacosWindowToolkitPlatform.instance.closeWindow(windowId);
  }

  /// Terminates an application by its process ID.
  ///
  /// This method will terminate the entire application, not just a specific window.
  /// Unlike [closeWindow], this method works at the process level and does not
  /// require accessibility permissions, making it suitable for security applications.
  ///
  /// Returns a [WindowOperationResult] indicating success or failure with details.
  ///
  /// [processId] is the process ID of the application to terminate, which can be
  /// obtained from window information returned by [getAllWindows] or other window
  /// retrieval methods.
  ///
  /// [force] determines the termination method:
  /// - `false` (default): Graceful termination - allows the application to clean up
  /// - `true`: Force termination - immediately kills the process
  ///
  /// This method tries multiple approaches:
  /// 1. NSRunningApplication API (preferred, more graceful)
  /// 2. Signal-based termination (SIGTERM/SIGKILL) as fallback
  ///
  /// Returns:
  /// - [OperationSuccess] if the application was successfully terminated
  /// - [OperationFailure] with one of the following reasons:
  ///   - [WindowOperationFailureReason.processNotFound]: Process does not exist
  ///   - [WindowOperationFailureReason.unknown]: Other failure states
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, internal errors).
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Get windows and find the process to terminate
  /// final windows = await toolkit.getAllWindows();
  /// final targetWindow = windows.firstWhere((w) => w.ownerName.contains('Safari'));
  ///
  /// // Try graceful termination first
  /// var result = await toolkit.terminateApplicationByPID(targetWindow.processId);
  ///
  /// if (result is OperationFailure) {
  ///   // If graceful termination failed, try force termination
  ///   result = await toolkit.terminateApplicationByPID(
  ///     targetWindow.processId,
  ///     force: true
  ///   );
  /// }
  ///
  /// switch (result) {
  ///   case OperationSuccess():
  ///     print('Application terminated');
  ///   case OperationFailure(:final message):
  ///     print('Termination failed: $message');
  /// }
  /// ```
  Future<WindowOperationResult> terminateApplicationByPID(
    int processId, {
    bool force = false,
  }) async {
    return await MacosWindowToolkitPlatform.instance.terminateApplicationByPID(
      processId,
      force: force,
    );
  }

  /// Terminates an application and all its child processes.
  ///
  /// This method provides comprehensive process termination by first identifying
  /// all child processes spawned by the target application, then terminating them
  /// in the correct order (children first, then parent).
  ///
  /// Returns a [WindowOperationResult] indicating success or failure with details.
  ///
  /// This is particularly useful for security applications where you need to ensure
  /// that all related processes are terminated, preventing potential security bypasses
  /// where child processes might continue running after the parent is terminated.
  ///
  /// [processId] is the process ID of the parent application to terminate.
  /// [force] determines the termination method for all processes:
  /// - `false` (default): Graceful termination for all processes
  /// - `true`: Force termination for all processes
  ///
  /// The termination process:
  /// 1. Discovers all child processes using system process list
  /// 2. Terminates child processes first (bottom-up approach)
  /// 3. Finally terminates the parent process
  ///
  /// Returns:
  /// - [OperationSuccess] if all processes were successfully terminated
  /// - [OperationFailure] with one of the following reasons:
  ///   - [WindowOperationFailureReason.processNotFound]: Parent process does not exist
  ///   - [WindowOperationFailureReason.unknown]: Other failure states (including partial failures)
  ///
  /// Throws [PlatformException] only for system errors (invalid arguments, internal errors).
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Get process ID from a window
  /// final windows = await toolkit.getAllWindows();
  /// final targetWindow = windows.firstWhere((w) => w.ownerName.contains('Electron'));
  ///
  /// // Terminate the entire process tree
  /// final result = await toolkit.terminateApplicationTree(targetWindow.processId);
  ///
  /// switch (result) {
  ///   case OperationSuccess():
  ///     print('Application and all child processes terminated');
  ///   case OperationFailure(:final message):
  ///     print('Some processes failed to terminate: $message');
  /// }
  ///
  /// // For security applications, you might want to use force termination
  /// await toolkit.terminateApplicationTree(processId, force: true);
  /// ```
  Future<WindowOperationResult> terminateApplicationTree(
    int processId, {
    bool force = false,
  }) async {
    return await MacosWindowToolkitPlatform.instance.terminateApplicationTree(
      processId,
      force: force,
    );
  }

  /// Gets all child process IDs for a given parent process ID.
  ///
  /// This method searches through the system process list to identify all processes
  /// that were spawned by the specified parent process. This is useful for understanding
  /// process relationships and for implementing comprehensive process management.
  ///
  /// [processId] is the process ID of the parent process to analyze.
  ///
  /// Returns a list of process IDs that are direct children of the specified parent.
  /// Returns an empty list if no child processes are found or if the parent process
  /// doesn't exist.
  ///
  /// This method is particularly useful in security applications for:
  /// - Understanding application architecture
  /// - Detecting process spawning patterns
  /// - Implementing selective process termination
  /// - Monitoring process relationships
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Get process ID from a window
  /// final windows = await toolkit.getAllWindows();
  /// final parentWindow = windows.firstWhere((w) => w.ownerName.contains('Browser'));
  ///
  /// // Get all child processes
  /// final childPIDs = await toolkit.getChildProcesses(parentWindow.processId);
  ///
  /// print('Parent PID: ${parentWindow.processId}');
  /// print('Child PIDs: $childPIDs');
  ///
  /// // Selectively terminate child processes if needed
  /// for (final childPID in childPIDs) {
  ///   final windows = await toolkit.getWindowsByProcessId(childPID);
  ///   if (windows.any((w) => w.name.contains('dangerous'))) {
  ///     await toolkit.terminateApplicationByPID(childPID);
  ///   }
  /// }
  /// ```
  ///
  /// Note: This method does not require accessibility permissions and works
  /// by querying the system process table directly.
  ///
  /// Throws [PlatformException] with appropriate error codes:
  /// - `GET_CHILD_PROCESSES_ERROR`: Failed to retrieve child processes
  /// - `FAILED_TO_GET_PROCESS_LIST`: Unable to retrieve system process list
  Future<List<int>> getChildProcesses(int processId) async {
    return await MacosWindowToolkitPlatform.instance.getChildProcesses(
      processId,
    );
  }

  /// Gets all installed applications on the system.
  ///
  /// Returns an [ApplicationResult] containing either:
  /// - [ApplicationSuccess] with a list of [MacosApplicationInfo] objects
  /// - [ApplicationFailure] with the reason for failure
  ///
  /// This method scans all application domains (user and system) to find
  /// installed applications. It uses direct file system access which is
  /// more reliable than command-line tools like mdfind.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final result = await toolkit.getAllInstalledApplications();
  ///
  /// switch (result) {
  ///   case ApplicationSuccess(applications: final apps):
  ///     for (final app in apps) {
  ///       print('App: ${app.name}');
  ///       print('Bundle ID: ${app.bundleId}');
  ///       print('Version: ${app.version}');
  ///       print('Path: ${app.path}');
  ///       if (app.iconPath.isNotEmpty) {
  ///         print('Icon: ${app.iconPath}');
  ///       }
  ///       print('---');
  ///     }
  ///   case ApplicationFailure(reason: final reason):
  ///     print('Failed to get applications: ${reason.name}');
  ///     if (result.canRetry) {
  ///       print('Suggestion: ${result.suggestedAction}');
  ///     }
  /// }
  /// ```
  ///
  /// Unlike other methods, this does not throw [PlatformException] for failures.
  /// All failures are returned as [ApplicationFailure] objects.
  Future<ApplicationResult> getAllInstalledApplications() async {
    try {
      final List<Map<String, dynamic>> applicationMaps =
          await MacosWindowToolkitPlatform.instance
              .getAllInstalledApplications();

      if (applicationMaps.isEmpty) {
        return const ApplicationFailure(
          reason: ApplicationFailureReason.notFound,
          message: 'No applications found on the system',
        );
      }

      final applications = applicationMaps
          .map((map) => MacosApplicationInfo.fromMap(map))
          .toList();

      return ApplicationSuccess(applications);
    } catch (e) {
      return ApplicationFailure(
        reason: ApplicationFailureReason.systemError,
        message: 'Failed to retrieve applications',
        details: e.toString(),
      );
    }
  }

  /// Gets applications filtered by name.
  ///
  /// Returns an [ApplicationResult] containing either:
  /// - [ApplicationSuccess] with matching [MacosApplicationInfo] objects
  /// - [ApplicationFailure] with the reason for failure
  ///
  /// [name] The application name to search for (case-insensitive)
  ///
  /// The search is case-insensitive and uses substring matching on the
  /// application display name.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Find Safari browser
  /// final result = await toolkit.getApplicationByName('Safari');
  /// switch (result) {
  ///   case ApplicationSuccess(applications: final apps):
  ///     if (apps.isNotEmpty) {
  ///       final safari = apps.first;
  ///       print('Found Safari at: ${safari.path}');
  ///       print('Version: ${safari.version}');
  ///     } else {
  ///       print('Safari not found');
  ///     }
  ///   case ApplicationFailure():
  ///     print('Search failed: ${result.userMessage}');
  /// }
  ///
  /// // Find all apps containing "Code"
  /// final codeResult = await toolkit.getApplicationByName('Code');
  /// if (codeResult case ApplicationSuccess(applications: final codeApps)) {
  ///   for (final app in codeApps) {
  ///     print('Found: ${app.name} (${app.bundleId})');
  ///   }
  /// }
  /// ```
  ///
  /// Unlike other methods, this does not throw [PlatformException] for failures.
  /// All failures are returned as [ApplicationFailure] objects.
  Future<ApplicationResult> getApplicationByName(String name) async {
    try {
      final List<Map<String, dynamic>> applicationMaps =
          await MacosWindowToolkitPlatform.instance.getApplicationByName(name);

      final applications = applicationMaps
          .map((map) => MacosApplicationInfo.fromMap(map))
          .toList();

      // Note: Empty results are still success, not failure
      return ApplicationSuccess(applications);
    } catch (e) {
      return ApplicationFailure(
        reason: ApplicationFailureReason.systemError,
        message: 'Failed to search for applications',
        details: e.toString(),
      );
    }
  }

  /// Opens Mac App Store with search query for the specified application name.
  ///
  /// Returns `true` if the App Store was successfully opened with the search query,
  /// `false` otherwise.
  ///
  /// This method is useful when an application is not found on the system and you
  /// want to help users find and install it from the App Store.
  ///
  /// [searchTerm] The application name or keywords to search for in the App Store
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Try to find an application first
  /// final result = await toolkit.getApplicationByName('NonExistentApp');
  /// switch (result) {
  ///   case ApplicationSuccess(applications: final apps):
  ///     if (apps.isEmpty) {
  ///       // App not found, offer to search in App Store
  ///       final opened = await toolkit.openAppStoreSearch('NonExistentApp');
  ///       if (opened) {
  ///         print('App Store opened for search');
  ///       } else {
  ///         print('Failed to open App Store');
  ///       }
  ///     } else {
  ///       print('Found ${apps.length} matching applications');
  ///     }
  ///   case ApplicationFailure():
  ///     print('Search failed: ${result.userMessage}');
  /// }
  ///
  /// // Direct App Store search
  /// final opened = await toolkit.openAppStoreSearch('Xcode');
  /// if (opened) {
  ///   print('App Store opened with Xcode search');
  /// }
  /// ```
  ///
  /// Throws [PlatformException] if unable to open the App Store due to system errors.
  /// Returns `false` if the URL scheme is not supported or App Store is not available.
  Future<bool> openAppStoreSearch(String searchTerm) async {
    return await MacosWindowToolkitPlatform.instance
        .openAppStoreSearch(searchTerm);
  }

  // MARK: - Permission Monitoring

  /// Starts monitoring permissions at the specified interval.
  ///
  /// This method enables real-time monitoring of macOS permissions (screen recording
  /// and accessibility) by checking their status periodically and emitting changes
  /// through a stream.
  ///
  /// If monitoring is already active, the existing timer will be cancelled and a
  /// new one will be started with the new interval. This prevents multiple timers
  /// from running simultaneously.
  ///
  /// [interval] The frequency to check permissions. Defaults to 2 seconds.
  /// Shorter intervals provide more responsive detection but use more CPU.
  /// Longer intervals are more efficient but may delay permission change detection.
  ///
  /// [emitOnlyChanges] If true (default), only emits when permissions change.
  /// If false, emits on every check regardless of changes. Set to false if you
  /// need regular heartbeat signals or want to show "last checked" timestamps.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Start monitoring with default 2-second interval
  /// toolkit.startPermissionWatching();
  ///
  /// // Start monitoring with custom interval
  /// toolkit.startPermissionWatching(interval: Duration(seconds: 5));
  ///
  /// // Start monitoring with heartbeat (emit even without changes)
  /// toolkit.startPermissionWatching(emitOnlyChanges: false);
  ///
  /// // Listen to permission changes
  /// toolkit.permissionStream.listen((status) {
  ///   if (status.hasChanges) {
  ///     print('Permission status changed!');
  ///     if (!status.screenRecording) {
  ///       // Handle screen recording permission loss
  ///       showDialog(context: context, builder: (_) => PermissionLostDialog());
  ///     }
  ///   }
  /// });
  /// ```
  ///
  /// **Integration with State Management:**
  /// This works excellently with Riverpod StreamProvider:
  /// ```dart
  /// final permissionStreamProvider = StreamProvider<PermissionStatus>((ref) {
  ///   final toolkit = MacosWindowToolkit();
  ///   toolkit.startPermissionWatching();
  ///   return toolkit.permissionStream;
  /// });
  /// ```
  void startPermissionWatching({
    Duration interval = const Duration(seconds: 2),
    bool emitOnlyChanges = true,
  }) {
    PermissionWatcher.instance.startWatching(
      interval: interval,
      emitOnlyChanges: emitOnlyChanges,
    );
  }

  /// Stops permission monitoring.
  ///
  /// Cancels the active timer and stops checking permission status. The stream
  /// remains available for reconnection, so you can call [startPermissionWatching]
  /// again to resume monitoring.
  ///
  /// This is useful when you want to temporarily pause monitoring to save
  /// resources or when the user explicitly disables permission monitoring.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Start monitoring
  /// toolkit.startPermissionWatching();
  ///
  /// // Later, stop monitoring
  /// toolkit.stopPermissionWatching();
  ///
  /// // Check if monitoring is active
  /// if (toolkit.isPermissionWatching) {
  ///   print('Still monitoring permissions');
  /// } else {
  ///   print('Permission monitoring is stopped');
  /// }
  /// ```
  void stopPermissionWatching() {
    PermissionWatcher.instance.stopWatching();
  }

  /// Stream of permission status changes.
  ///
  /// Emits [PermissionStatus] objects containing the current permission status
  /// whenever permissions are checked (based on the monitoring interval) or when
  /// changes are detected.
  ///
  /// **Note:** You must call [startPermissionWatching] to begin emitting values.
  /// The stream will not emit anything until monitoring is started.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// toolkit.startPermissionWatching();
  ///
  /// // Basic usage
  /// toolkit.permissionStream.listen((status) {
  ///   print('Screen recording: ${status.screenRecording}');
  ///   print('Accessibility: ${status.accessibility}');
  ///   print('Has changes: ${status.hasChanges}');
  ///   print('All granted: ${status.allPermissionsGranted}');
  /// });
  ///
  /// // React to permission changes only
  /// toolkit.permissionStream
  ///     .where((status) => status.hasChanges)
  ///     .listen((status) {
  ///       // Handle permission changes
  ///       if (status.screenRecording == false) {
  ///         navigateToPermissionSetup();
  ///       }
  ///     });
  ///
  /// // Handle errors (when permission status is null)
  /// toolkit.permissionStream.listen((status) {
  ///   if (status.hasUnknownStatus) {
  ///     print('Permission check error occurred');
  ///   }
  /// });
  /// ```
  ///
  /// **Riverpod Integration:**
  /// ```dart
  /// final permissionProvider = StreamProvider<PermissionStatus>((ref) {
  ///   final toolkit = MacosWindowToolkit();
  ///   toolkit.startPermissionWatching();
  ///   return toolkit.permissionStream;
  /// });
  ///
  /// // In widget
  /// Consumer(builder: (context, ref, child) {
  ///   final permissionAsync = ref.watch(permissionProvider);
  ///   return permissionAsync.when(
  ///     data: (status) => status.allPermissionsGranted
  ///       ? MainWidget()
  ///       : PermissionSetupWidget(),
  ///     loading: () => CircularProgressIndicator(),
  ///     error: (error, _) => Text('Error: $error'),
  ///   );
  /// });
  /// ```
  Stream<PermissionStatus> get permissionStream {
    return PermissionWatcher.instance.permissionStream;
  }

  /// Whether permission monitoring is currently active.
  ///
  /// Returns `true` if [startPermissionWatching] has been called and monitoring
  /// is active, `false` if monitoring is stopped or was never started.
  ///
  /// This is useful for:
  /// - Showing monitoring status in UI
  /// - Preventing duplicate monitoring setup
  /// - Conditional logic based on monitoring state
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  ///
  /// // Check before starting
  /// if (!toolkit.isPermissionWatching) {
  ///   toolkit.startPermissionWatching();
  /// }
  ///
  /// // Show status in UI
  /// Text(toolkit.isPermissionWatching
  ///   ? 'Permission monitoring: ON'
  ///   : 'Permission monitoring: OFF'
  /// );
  ///
  /// // Toggle monitoring
  /// ElevatedButton(
  ///   onPressed: () {
  ///     if (toolkit.isPermissionWatching) {
  ///       toolkit.stopPermissionWatching();
  ///     } else {
  ///       toolkit.startPermissionWatching();
  ///     }
  ///   },
  ///   child: Text(toolkit.isPermissionWatching ? 'Stop' : 'Start'),
  /// );
  /// ```
  bool get isPermissionWatching {
    return PermissionWatcher.instance.isWatching;
  }
}
