import 'dart:async';

import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class WindowService {
  static final MacosWindowToolkit _plugin = MacosWindowToolkit();

  static Timer? _refreshTimer;
  static bool _autoRefreshEnabled = false;

  /// Get all windows from the system
  static Future<List<MacosWindowInfo>> getAllWindows() async {
    try {
      return await _plugin.getAllWindows();
    } on PlatformException catch (e) {
      // Handle screen recording permission errors specifically
      if (e.code == 'SCREEN_RECORDING_PERMISSION_DENIED') {
        // Return empty list but let the caller handle the error
        rethrow;
      }
      rethrow;
    }
  }

  /// Get all windows with named titles only (excludes empty names)
  static Future<List<MacosWindowInfo>> getNamedWindows() async {
    try {
      return await _plugin.getAllWindows(excludeEmptyNames: true);
    } on PlatformException catch (e) {
      // Handle screen recording permission errors specifically
      if (e.code == 'SCREEN_RECORDING_PERMISSION_DENIED') {
        // Return empty list but let the caller handle the error
        rethrow;
      }
      rethrow;
    }
  }

  /// Filter windows based on search query
  static List<MacosWindowInfo> filterWindows(
    List<MacosWindowInfo> windows,
    String query,
  ) {
    if (query.isEmpty) return windows;

    final lowerQuery = query.toLowerCase();
    return windows.where((window) {
      return window.name.toLowerCase().contains(lowerQuery) ||
          window.ownerName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Start auto-refresh timer
  static void startAutoRefresh({
    required Duration interval,
    required VoidCallback onRefresh,
  }) {
    stopAutoRefresh();
    _autoRefreshEnabled = true;
    _refreshTimer = Timer.periodic(interval, (_) => onRefresh());
  }

  /// Stop auto-refresh timer
  static void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _autoRefreshEnabled = false;
  }

  /// Check if auto-refresh is enabled
  static bool get isAutoRefreshEnabled => _autoRefreshEnabled;

  /// Toggle auto-refresh state
  static void toggleAutoRefresh({
    Duration interval = const Duration(seconds: 2),
    required VoidCallback onRefresh,
  }) {
    if (_autoRefreshEnabled) {
      stopAutoRefresh();
    } else {
      startAutoRefresh(interval: interval, onRefresh: onRefresh);
    }
  }

  /// Format bytes to human readable format
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Get sharing state text representation
  static String getSharingStateText(int sharingState) {
    switch (sharingState) {
      case 0:
        return 'None';
      case 1:
        return 'ReadOnly';
      case 2:
        return 'ReadWrite';
      default:
        return 'Unknown($sharingState)';
    }
  }

  /// Clean up resources
  static void dispose() {
    stopAutoRefresh();
  }
}
