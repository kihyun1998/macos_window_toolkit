
import 'macos_window_toolkit_platform_interface.dart';

class MacosWindowToolkit {
  Future<String?> getPlatformVersion() {
    return MacosWindowToolkitPlatform.instance.getPlatformVersion();
  }
}
