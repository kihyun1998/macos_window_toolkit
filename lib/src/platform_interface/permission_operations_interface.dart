/// Platform interface for permission-related operations.
abstract class PermissionOperationsInterface {
  /// Checks if the app has screen recording permission.
  ///
  /// Returns `true` if the app has been granted screen recording permission,
  /// `false` otherwise. On macOS versions prior to 10.15 (Catalina), this
  /// always returns `true` as screen recording permission is not required.
  ///
  /// This is useful for checking permission status before calling [getAllWindows]
  /// to determine if window names will be available.
  Future<bool> hasScreenRecordingPermission() {
    throw UnimplementedError(
      'hasScreenRecordingPermission() has not been implemented.',
    );
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
    throw UnimplementedError(
      'requestScreenRecordingPermission() has not been implemented.',
    );
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
    throw UnimplementedError(
      'openScreenRecordingSettings() has not been implemented.',
    );
  }

  /// Checks if the app has accessibility permission.
  ///
  /// Returns `true` if the app has been granted accessibility permission,
  /// `false` otherwise. Accessibility permissions are required for certain
  /// window operations that interact with other applications.
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
  ///   await toolkit.closeWindow(windowId);
  /// } else {
  ///   // Need to request permission first
  ///   await toolkit.requestAccessibilityPermission();
  /// }
  /// ```
  Future<bool> hasAccessibilityPermission() {
    throw UnimplementedError(
      'hasAccessibilityPermission() has not been implemented.',
    );
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
    throw UnimplementedError(
      'requestAccessibilityPermission() has not been implemented.',
    );
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
    throw UnimplementedError(
      'openAccessibilitySettings() has not been implemented.',
    );
  }
}
