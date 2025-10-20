import '../models/window_operation_result.dart';

/// Platform interface for application management operations.
abstract class ApplicationOperationsInterface {
  /// Terminates an application by its process ID.
  ///
  /// This method will terminate the entire application, not just a specific window.
  ///
  /// Returns a [WindowOperationResult] indicating success or failure with details.
  ///
  /// [processId] is the process ID of the application to terminate.
  /// [force] determines the termination method:
  /// - `false` (default): Graceful termination (SIGTERM or NSRunningApplication.terminate())
  /// - `true`: Force termination (SIGKILL or NSRunningApplication.forceTerminate())
  ///
  /// This method tries the following approaches in order:
  /// 1. NSRunningApplication terminate/forceTerminate (more graceful)
  /// 2. Signal-based termination (SIGTERM/SIGKILL) as fallback
  ///
  /// **Note**: This method does NOT require accessibility permissions, making it suitable
  /// for security applications where accessibility permissions might be disabled.
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
  /// final result = await toolkit.terminateApplicationByPID(1234);
  /// switch (result) {
  ///   case OperationSuccess():
  ///     print('Application terminated successfully');
  ///   case OperationFailure(:final reason):
  ///     if (reason == WindowOperationFailureReason.processNotFound) {
  ///       print('Process already terminated');
  ///     } else {
  ///       // Try force termination
  ///       final forceResult = await toolkit.terminateApplicationByPID(1234, force: true);
  ///     }
  /// }
  /// ```
  Future<WindowOperationResult> terminateApplicationByPID(int processId,
      {bool force = false}) {
    throw UnimplementedError(
      'terminateApplicationByPID() has not been implemented.',
    );
  }

  /// Terminates an application and all its child processes.
  ///
  /// This method first identifies all child processes of the target application,
  /// then terminates them in bottom-up order (children first, then parent).
  ///
  /// Returns a [WindowOperationResult] indicating success or failure with details.
  ///
  /// [processId] is the process ID of the parent application to terminate.
  /// [force] determines the termination method for all processes:
  /// - `false` (default): Graceful termination
  /// - `true`: Force termination
  ///
  /// This method is particularly useful for security applications where you need
  /// to ensure that spawned child processes are also terminated when the parent
  /// application is closed.
  ///
  /// **Note**: This method does NOT require accessibility permissions.
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
  /// final result = await toolkit.terminateApplicationTree(1234);
  /// switch (result) {
  ///   case OperationSuccess():
  ///     print('Application and all child processes terminated');
  ///   case OperationFailure(:final message):
  ///     print('Termination failed: $message');
  /// }
  /// ```
  Future<WindowOperationResult> terminateApplicationTree(int processId,
      {bool force = false}) {
    throw UnimplementedError(
      'terminateApplicationTree() has not been implemented.',
    );
  }

  /// Gets all child process IDs for a given parent process ID.
  ///
  /// This method searches through the system process list to find all processes
  /// whose parent process ID matches the specified [processId].
  ///
  /// [processId] is the process ID of the parent process.
  ///
  /// Returns a list of process IDs that are children of the specified parent process.
  /// Returns an empty list if no child processes are found.
  ///
  /// This method is useful for understanding process relationships and for
  /// implementing comprehensive process management in security applications.
  ///
  /// Note: This method does NOT require accessibility permissions.
  ///
  /// Throws [PlatformException] with appropriate error codes:
  /// - `GET_CHILD_PROCESSES_ERROR`: Failed to retrieve child processes
  /// - `FAILED_TO_GET_PROCESS_LIST`: Unable to retrieve system process list
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final childPIDs = await toolkit.getChildProcesses(1234);
  ///   print('Child processes: $childPIDs');
  ///
  ///   // Terminate each child individually if needed
  ///   for (final childPID in childPIDs) {
  ///     await toolkit.terminateApplicationByPID(childPID);
  ///   }
  /// } catch (e) {
  ///   if (e is PlatformException) {
  ///     print('Error: ${e.code} - ${e.message}');
  ///   }
  /// }
  /// ```
  Future<List<int>> getChildProcesses(int processId) {
    throw UnimplementedError('getChildProcesses() has not been implemented.');
  }

  /// Gets all installed applications on the system.
  ///
  /// Returns a list of maps containing application properties:
  /// - `name`: Application display name (String)
  /// - `bundleId`: Bundle identifier (String)
  /// - `version`: Application version (String)
  /// - `path`: Full path to application bundle (String)
  /// - `iconPath`: Path to application icon file (String)
  ///
  /// Throws [PlatformException] if unable to retrieve application information.
  Future<List<Map<String, dynamic>>> getAllInstalledApplications() {
    throw UnimplementedError(
        'getAllInstalledApplications() has not been implemented.');
  }

  /// Gets applications filtered by name.
  ///
  /// Returns a list of maps containing application properties for applications whose
  /// name contains the specified [name] string. The search is case-insensitive
  /// and uses substring matching.
  ///
  /// Throws [PlatformException] if unable to retrieve application information.
  Future<List<Map<String, dynamic>>> getApplicationByName(String name) {
    throw UnimplementedError(
        'getApplicationByName() has not been implemented.');
  }

  /// Opens Mac App Store with search query for the specified application name.
  ///
  /// Returns `true` if the App Store was successfully opened with the search query,
  /// `false` otherwise.
  ///
  /// This method is useful when an application is not found on the system and you
  /// want to help users find and install it from the App Store.
  ///
  /// Example usage:
  /// ```dart
  /// final toolkit = MacosWindowToolkit();
  /// final result = await toolkit.getApplicationByName('NonExistentApp');
  ///
  /// switch (result) {
  ///   case ApplicationSuccess(applications: final apps):
  ///     if (apps.isEmpty) {
  ///       // App not found, offer to search in App Store
  ///       final opened = await toolkit.openAppStoreSearch('NonExistentApp');
  ///       if (opened) {
  ///         print('App Store opened for search');
  ///       }
  ///     }
  ///   case ApplicationFailure():
  ///     // Handle error
  ///     break;
  /// }
  /// ```
  ///
  /// Throws [PlatformException] if unable to open the App Store.
  Future<bool> openAppStoreSearch(String searchTerm) {
    throw UnimplementedError('openAppStoreSearch() has not been implemented.');
  }
}
