import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';
import 'package:macos_window_toolkit/macos_window_toolkit_platform_interface.dart';
import 'package:macos_window_toolkit/macos_window_toolkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMacosWindowToolkitPlatform
    with MockPlatformInterfaceMixin
    implements MacosWindowToolkitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MacosWindowToolkitPlatform initialPlatform = MacosWindowToolkitPlatform.instance;

  test('$MethodChannelMacosWindowToolkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMacosWindowToolkit>());
  });

  test('getPlatformVersion', () async {
    MacosWindowToolkit macosWindowToolkitPlugin = MacosWindowToolkit();
    MockMacosWindowToolkitPlatform fakePlatform = MockMacosWindowToolkitPlatform();
    MacosWindowToolkitPlatform.instance = fakePlatform;

    expect(await macosWindowToolkitPlugin.getPlatformVersion(), '42');
  });
}
