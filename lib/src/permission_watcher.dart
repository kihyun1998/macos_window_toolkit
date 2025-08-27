import 'dart:async';

import 'macos_window_toolkit_platform_interface.dart';
import 'models/permission_status.dart';

/// A singleton class that monitors permission changes using a periodic timer.
///
/// This class provides real-time monitoring of macOS permissions (screen recording
/// and accessibility) by checking their status at regular intervals and emitting
/// changes through a stream.
///
/// Example usage:
/// ```dart
/// final watcher = PermissionWatcher.instance;
///
/// // Start monitoring with default 2-second interval
/// watcher.startWatching();
///
/// // Listen to permission changes
/// watcher.permissionStream.listen((permissions) {
///   final screenRecording = permissions['screenRecording'];
///   final accessibility = permissions['accessibility'];
///
///   if (screenRecording == false) {
///     // Handle screen recording permission loss
///     showPermissionDialog();
///   }
/// });
///
/// // Stop monitoring
/// watcher.stopWatching();
/// ```
class PermissionWatcher {
  PermissionWatcher._internal();

  /// Singleton instance
  static final PermissionWatcher instance = PermissionWatcher._internal();

  Timer? _timer;
  StreamController<PermissionStatus>? _controller;

  /// Previous permission state for change detection
  Map<String, bool?>? _previousState;

  /// Whether to emit only when permissions change
  bool _emitOnlyChanges = true;

  /// Whether the watcher is currently monitoring permissions
  bool get isWatching => _timer?.isActive ?? false;

  /// Stream of permission status changes
  ///
  /// Emits [PermissionStatus] objects containing:
  /// - screenRecording: bool? - Screen recording permission status
  /// - accessibility: bool? - Accessibility permission status
  /// - hasChanges: bool - Whether any permissions changed since last check
  /// - timestamp: DateTime - When the check was performed
  Stream<PermissionStatus> get permissionStream {
    _controller ??= StreamController<PermissionStatus>.broadcast();
    return _controller!.stream;
  }

  /// Starts monitoring permissions at the specified interval
  ///
  /// If monitoring is already active, the existing timer will be cancelled
  /// and a new one will be started with the new interval. This prevents
  /// multiple timers from running simultaneously.
  ///
  /// [interval] The frequency to check permissions (default: 2 seconds)
  /// [emitOnlyChanges] If true, only emits when permissions change. If false,
  /// emits on every check regardless of changes (default: true for efficiency)
  void startWatching({
    Duration interval = const Duration(seconds: 2),
    bool emitOnlyChanges = true,
  }) {
    // Cancel existing timer to prevent duplicates
    _timer?.cancel();

    // Store emit preference
    _emitOnlyChanges = emitOnlyChanges;

    // Initialize stream controller if needed
    _controller ??= StreamController<PermissionStatus>.broadcast();

    // Perform initial check (always emit initial state)
    _checkPermissions(forceEmit: true);

    // Start periodic monitoring
    _timer = Timer.periodic(interval, (_) => _checkPermissions());
  }

  /// Stops permission monitoring
  ///
  /// Cancels the active timer and cleans up resources. The stream controller
  /// is kept alive to allow reconnection without losing listeners.
  void stopWatching() {
    _timer?.cancel();
    _timer = null;
  }

  /// Performs cleanup and disposes all resources
  ///
  /// This should be called when the watcher is no longer needed to prevent
  /// memory leaks. After calling dispose(), the watcher cannot be reused.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _controller?.close();
    _controller = null;
    _previousState = null;
  }

  /// Checks current permission status and emits changes if detected
  ///
  /// [forceEmit] If true, always emits the current state regardless of changes
  Future<void> _checkPermissions({bool forceEmit = false}) async {
    try {
      final screenRecording = await MacosWindowToolkitPlatform.instance
          .hasScreenRecordingPermission();
      final accessibility = await MacosWindowToolkitPlatform.instance
          .hasAccessibilityPermission();

      final currentState = <String, bool?>{
        'screenRecording': screenRecording,
        'accessibility': accessibility,
      };

      // Check for changes
      final hasChanges =
          _previousState == null ||
          _previousState!['screenRecording'] != screenRecording ||
          _previousState!['accessibility'] != accessibility;

      // Create typed permission status
      final permissionStatus = PermissionStatus(
        screenRecording: screenRecording,
        accessibility: accessibility,
        hasChanges: hasChanges,
        timestamp: DateTime.now(),
      );

      // Decide whether to emit based on settings
      final shouldEmit = forceEmit || !_emitOnlyChanges || hasChanges;

      if (shouldEmit) {
        _controller?.add(permissionStatus);
      }

      // Update previous state for next comparison
      _previousState = currentState;
    } catch (e) {
      // Emit error state
      final errorStatus = PermissionStatus(
        screenRecording: null,
        accessibility: null,
        hasChanges: true,
        timestamp: DateTime.now(),
      );
      _controller?.add(errorStatus);
    }
  }
}
