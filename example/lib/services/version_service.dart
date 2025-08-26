import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class VersionService {
  static final MacosWindowToolkit _plugin = MacosWindowToolkit();

  /// Get macOS version information
  static Future<MacosVersionInfo?> getMacOSVersionInfo() async {
    try {
      return await _plugin.getMacOSVersionInfo();
    } on PlatformException catch (e) {
      // Log error but don't throw - this is non-critical functionality
      print('Error getting version info: ${e.message}');
      return null;
    }
  }
}
