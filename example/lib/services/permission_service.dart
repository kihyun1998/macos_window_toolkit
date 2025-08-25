import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class PermissionService {
  static final MacosWindowToolkit _plugin = MacosWindowToolkit();
  
  /// Check screen recording permission
  static Future<bool?> checkScreenRecordingPermission() async {
    try {
      return await _plugin.hasScreenRecordingPermission();
    } on PlatformException {
      return null;
    }
  }
  
  /// Check accessibility permission
  static Future<bool?> checkAccessibilityPermission() async {
    try {
      return await _plugin.hasAccessibilityPermission();
    } on PlatformException {
      return null;
    }
  }
  
  /// Request screen recording permission
  static Future<bool?> requestScreenRecordingPermission() async {
    try {
      return await _plugin.requestScreenRecordingPermission();
    } on PlatformException {
      return null;
    }
  }
  
  /// Request accessibility permission
  static Future<bool?> requestAccessibilityPermission() async {
    try {
      return await _plugin.requestAccessibilityPermission();
    } on PlatformException {
      return null;
    }
  }
  
  /// Open screen recording settings
  static Future<bool?> openScreenRecordingSettings() async {
    try {
      return await _plugin.openScreenRecordingSettings();
    } on PlatformException {
      return null;
    }
  }
  
  /// Open accessibility settings
  static Future<bool?> openAccessibilitySettings() async {
    try {
      return await _plugin.openAccessibilitySettings();
    } on PlatformException {
      return null;
    }
  }
  
  /// Get the most critical missing permission
  static PermissionType? getMostCriticalMissingPermission({
    required bool? hasScreenRecording,
    required bool? hasAccessibility,
  }) {
    if (hasScreenRecording == false) {
      return PermissionType.screenRecording;
    }
    if (hasAccessibility == false) {
      return PermissionType.accessibility;
    }
    return null;
  }
  
  /// Check if any permission is missing
  static bool hasAnyMissingPermission({
    required bool? hasScreenRecording,
    required bool? hasAccessibility,
  }) {
    return hasScreenRecording == false || hasAccessibility == false;
  }
}

enum PermissionType {
  screenRecording,
  accessibility,
}