/// Platform interface for window-related operations.
abstract class WindowOperationsInterface {
  /// Retrieves information about all windows currently open on the system.
  ///
  /// [excludeEmptyNames] if true, windows with empty or missing names will be
  /// filtered out from the results. This is useful when you only want windows
  /// that have actual titles.
  ///
  /// Returns a list of maps containing window properties:
  /// - `windowId`: Unique identifier for the window (int)
  /// - `name`: Window title/name (String)
  /// - `ownerName`: Name of the application that owns the window (String)
  /// - `bounds`: Window position and size as [x, y, width, height] (List\<double\>)
  /// - `layer`: Window layer level (int)
  /// - `isOnScreen`: Whether the window is currently visible on screen (bool)
  /// - `processId`: Process ID of the application that owns the window (int)
  ///
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getAllWindows({
    bool excludeEmptyNames = false,
  }) {
    throw UnimplementedError('getAllWindows() has not been implemented.');
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
    throw UnimplementedError(
      'getWindowsByOwnerName() has not been implemented.',
    );
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
    throw UnimplementedError(
      'getWindowsByProcessId() has not been implemented.',
    );
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

  /// Closes a window by its window ID using AppleScript.
  ///
  /// Returns `true` if the window was successfully closed, `false` otherwise.
  ///
  /// [windowId] is the unique identifier of the window to close.
  ///
  /// This method uses AppleScript to interact with the application's window
  /// close button. It first retrieves the window information to get the
  /// application name and window title, then executes an AppleScript to
  /// click the close button.
  ///
  /// Note: This method requires accessibility permissions on some systems
  /// and may not work with all applications depending on their AppleScript
  /// support and window structure.
  ///
  /// Throws [PlatformException] with appropriate error codes:
  /// - `CLOSE_WINDOW_ERROR`: General window closing error
  /// - `WINDOW_NOT_FOUND`: Window with the specified ID was not found
  /// - `INSUFFICIENT_WINDOW_INFO`: Not enough window information to close the window
  /// - `APPLESCRIPT_EXECUTION_FAILED`: AppleScript execution failed
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final success = await toolkit.closeWindow(12345);
  ///   if (success) {
  ///     print('Window closed successfully');
  ///   } else {
  ///     print('Failed to close window');
  ///   }
  /// } catch (e) {
  ///   if (e is PlatformException) {
  ///     print('Error: ${e.code} - ${e.message}');
  ///   }
  /// }
  /// ```
  Future<bool> closeWindow(int windowId) {
    throw UnimplementedError('closeWindow() has not been implemented.');
  }
}
