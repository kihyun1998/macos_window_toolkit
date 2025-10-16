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

  /// Retrieves windows with advanced filtering options.
  ///
  /// All parameters are optional. Only non-null parameters are used for filtering.
  /// All specified conditions are combined with AND logic.
  ///
  /// Parameters:
  /// - [windowId]: Filter by exact window ID
  /// - [name]: Filter by window title (substring match by default)
  /// - [nameExactMatch]: If true, name must match exactly. If false (default), uses substring matching.
  /// - [nameCaseSensitive]: If true (default), name matching is case sensitive.
  /// - [ownerName]: Filter by application name (substring match by default)
  /// - [ownerNameExactMatch]: If true, ownerName must match exactly. If false (default), uses substring matching.
  /// - [ownerNameCaseSensitive]: If true (default), ownerName matching is case sensitive.
  /// - [processId]: Filter by exact process ID
  /// - [isOnScreen]: Filter by visibility on screen
  /// - [layer]: Filter by exact window layer level
  /// - [x]: Filter by exact x coordinate
  /// - [y]: Filter by exact y coordinate
  /// - [width]: Filter by exact width
  /// - [height]: Filter by exact height
  ///
  /// Returns a list of maps containing window properties for windows that match
  /// all specified criteria.
  ///
  /// Example usage:
  /// ```dart
  /// // Find all visible windows from Chrome
  /// final windows = await toolkit.getWindowsAdvanced(
  ///   ownerName: 'Chrome',
  ///   isOnScreen: true,
  /// );
  ///
  /// // Find a specific window by ID and verify it's visible
  /// final window = await toolkit.getWindowsAdvanced(
  ///   windowId: 12345,
  ///   isOnScreen: true,
  /// );
  /// ```
  ///
  /// Throws [PlatformException] if unable to retrieve window information.
  Future<List<Map<String, dynamic>>> getWindowsAdvanced({
    int? windowId,
    String? name,
    bool? nameExactMatch,
    bool? nameCaseSensitive,
    String? ownerName,
    bool? ownerNameExactMatch,
    bool? ownerNameCaseSensitive,
    int? processId,
    bool? isOnScreen,
    int? layer,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    throw UnimplementedError('getWindowsAdvanced() has not been implemented.');
  }

  /// Checks if a window with the specified ID is currently alive/exists.
  ///
  /// Returns `true` if the window exists and is currently available on the system,
  /// `false` otherwise.
  ///
  /// [windowId] is the unique identifier of the window to check.
  ///
  /// [expectedName] is an optional window name to verify. If provided, the method
  /// will also check that the window's name matches this value. This is useful
  /// for ensuring the window ID hasn't been reused by a different window, as
  /// macOS may reuse window IDs after a window is closed.
  ///
  /// This method is useful for verifying if a window is still valid before
  /// attempting operations like capture or manipulation.
  ///
  /// Example usage:
  /// ```dart
  /// // Check if window exists by ID only
  /// final isAlive = await toolkit.isWindowAlive(12345);
  /// if (isAlive) {
  ///   // Window exists, safe to perform operations
  ///   final imageBytes = await toolkit.captureWindow(12345);
  /// } else {
  ///   print('Window no longer exists');
  /// }
  ///
  /// // Check if window exists AND has the expected name (safer)
  /// final isAliveWithName = await toolkit.isWindowAlive(
  ///   12345,
  ///   expectedName: 'My Document',
  /// );
  /// if (isAliveWithName) {
  ///   print('Window exists and name matches');
  /// } else {
  ///   print('Window not found or name changed (ID may have been reused)');
  /// }
  /// ```
  Future<bool> isWindowAlive(int windowId, {String? expectedName}) {
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
