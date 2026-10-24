import 'dart:async';

import 'models/permission_status.dart';
import 'platform_interface/macos_window_toolkit_platform_interface.dart';

/// A singleton class that monitors permission changes using a periodic timer.
///
/// This class provides real-time monitoring of macOS permissions (screen recording
/// and accessibility) by checking their status at regular intervals and emitting
/// changes through a stream.
///
/// Polling is tied to stream listeners: when the last [permissionStream]
/// listener cancels, the periodic timer stops automatically so no platform
/// calls are made that nobody consumes. As long as watching has been
/// requested via [startWatching] (and not stopped via [stopWatching]),
/// polling resumes automatically when a new listener subscribes.
///
/// Example usage:
/// ```dart
/// final watcher = PermissionWatcher.instance;
///
/// // Start monitoring with default 2-second interval
/// watcher.startWatching();
///
/// // Listen to permission changes
/// final subscription = watcher.permissionStream.listen((permissions) {
///   final screenRecording = permissions.screenRecording;
///   final accessibility = permissions.accessibility;
///
///   if (screenRecording == false) {
///     // Handle screen recording permission loss
///     showPermissionDialog();
///   }
/// });
///
/// // Cancelling the last listener pauses polling automatically;
/// // a new listener resumes it.
/// await subscription.cancel();
///
/// // Stop monitoring entirely
/// watcher.stopWatching();
/// ```
class PermissionWatcher {
  PermissionWatcher._internal();

  /// Singleton instance
  static final PermissionWatcher instance = PermissionWatcher._internal();

  Timer? _timer;
  StreamController<PermissionStatus>? _controller;

  /// Previous permission state for change detection
  PermissionStatus? _previousState;

  /// Whether to emit only when permissions change
  bool _emitOnlyChanges = true;

  /// Polling interval, remembered so auto-resume uses the latest settings
  Duration _interval = const Duration(seconds: 2);

  /// True between [startWatching] and [stopWatching]/[dispose]. While true,
  /// polling auto-resumes when a listener subscribes after an auto-stop.
  bool _watchRequested = false;

  /// Whether the watcher is currently monitoring permissions
  ///
  /// Note: this can become false without an explicit [stopWatching] call —
  /// polling stops automatically while the stream has no listeners.
  bool get isWatching => _timer?.isActive ?? false;

  /// Stream of permission status changes
  ///
  /// Emits [PermissionStatus] objects containing:
  /// - screenRecording: bool? - Screen recording permission status
  /// - accessibility: bool? - Accessibility permission status
  /// - hasChanges: bool - Whether any permissions changed since last check
  /// - timestamp: DateTime - When the check was performed
  Stream<PermissionStatus> get permissionStream => _ensureController().stream;

  StreamController<PermissionStatus> _ensureController() {
    return _controller ??= StreamController<PermissionStatus>.broadcast(
      onListen: _handleFirstListener,
      onCancel: _handleLastListenerCancelled,
    );
  }

  void _handleFirstListener() {
    // Resume polling that was auto-stopped while nobody was listening.
    if (_watchRequested && _timer == null) {
      _startTimer();
    }
  }

  void _handleLastListenerCancelled() {
    // Last listener is gone — stop polling so no platform calls are made
    // that nobody consumes. _watchRequested stays true so the next listener
    // resumes polling with the same settings.
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _timer = Timer.periodic(_interval, (_) => _checkPermissions());
  }

  /// Starts monitoring permissions at the specified interval
  ///
  /// If monitoring is already active, the existing timer will be cancelled
  /// and a new one will be started with the new interval. This prevents
  /// multiple timers from running simultaneously.
  ///
  /// Polling starts immediately, even before any listener subscribes. If all
  /// listeners later cancel, polling pauses automatically and resumes when a
  /// new listener subscribes (until [stopWatching] is called).
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
    _timer = null;

    // Store settings for this watch request (also used by auto-resume)
    _interval = interval;
    _emitOnlyChanges = emitOnlyChanges;
    _watchRequested = true;

    // Initialize stream controller if needed
    _ensureController();

    // Perform initial check (always emit initial state)
    _checkPermissions(forceEmit: true);

    // Start periodic monitoring
    _startTimer();
  }

  /// Stops permission monitoring
  ///
  /// Cancels the active timer and withdraws the watch request, so polling
  /// does NOT resume when a new listener subscribes. The stream controller
  /// is kept alive to allow reconnection without losing listeners.
  void stopWatching() {
    _watchRequested = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Resets the watcher to its initial state
  ///
  /// Stops monitoring, closes the current stream (existing listeners receive
  /// a done event), and clears all cached state. The watcher can be reused
  /// afterwards: accessing [permissionStream] creates a fresh stream, and
  /// monitoring must be started again with [startWatching].
  void dispose() {
    _watchRequested = false;
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

      // Check for changes
      final previous = _previousState;
      final hasChanges = previous == null ||
          previous.screenRecording != screenRecording ||
          previous.accessibility != accessibility;

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
      _previousState = permissionStatus;
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
