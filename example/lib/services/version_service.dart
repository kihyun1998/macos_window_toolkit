import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class VersionService {
  static final MacosWindowToolkit _plugin = MacosWindowToolkit();

  /// Get macOS version information
  static Future<MacosVersionInfo?> getMacOSVersionInfo() async {
    try {
      return await _plugin.getMacOSVersionInfo();
    } on PlatformException {
      return null;
    }
  }
}
