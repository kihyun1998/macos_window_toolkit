# macOS Window Toolkit

[![pub package](https://img.shields.io/pub/v/macos_window_toolkit.svg)](https://pub.dev/packages/macos_window_toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for macOS window management, screen capture, and application discovery.

## Features

- 🪟 **Window Management** - Get, search, filter, close, and focus windows
- 📸 **Screen Capture** - Capture windows with ScreenCaptureKit or legacy methods
- 📱 **App Discovery** - Find and manage installed applications
- 🔐 **Permission Management** - Handle screen recording and accessibility permissions
- 🎯 **Process Control** - Terminate applications and manage process trees
- ⚡️ **Real-time Monitoring** - Monitor permission changes with streams

## Installation

```yaml
dependencies:
  macos_window_toolkit: ^1.5.1
```

## Setup (Required)

### 1. Disable App Sandbox

Edit `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.app-sandbox</key>
<false/>
<key>com.apple.security.automation.apple-events</key>
<true/>
```

### 2. Request Permissions at Runtime

```dart
final toolkit = MacosWindowToolkit();

// Request screen recording permission (for window names and capture)
await toolkit.requestScreenRecordingPermission();

// Request accessibility permission (for window control and process management)
await toolkit.requestAccessibilityPermission();
```

## Quick Start

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

final toolkit = MacosWindowToolkit();

// Get all windows
final windows = await toolkit.getAllWindows();
for (final window in windows) {
  print('${window.name} - ${window.ownerName}');
}

// Search windows
final chromeWindows = await toolkit.getWindowsByOwnerName('Chrome');

// Close a window
final result = await toolkit.closeWindow(windowId);

// Capture a window
final capture = await toolkit.captureWindow(windowId);
if (capture case CaptureSuccess(imageData: final data)) {
  // Save or display image data
}

// Find installed apps
final apps = await toolkit.getAllInstalledApplications();
if (apps case ApplicationSuccess(applications: final appList)) {
  print('Found ${appList.length} apps');
}
```

## API Reference

### Window Management (9 methods)

| Method | Description |
|--------|-------------|
| `getAllWindows()` | Get all open windows |
| `getWindowsByName(String name)` | Search windows by title |
| `getWindowsByOwnerName(String owner)` | Search by app name |
| `getWindowById(int id)` | Find window by ID |
| `getWindowsByProcessId(int pid)` | Find windows by process |
| `getWindowsAdvanced({...})` | Advanced filtering (14 parameters) |
| `isWindowAlive(int id)` | Check if window exists |
| `closeWindow(int id)` | Close a window (requires Accessibility) |
| `focusWindow(int id)` | Focus/bring window to front (requires Accessibility) |

### Screen Capture (2 methods)

| Method | Description |
|--------|-------------|
| `captureWindow(int id, {...})` | Capture window using ScreenCaptureKit (macOS 14.0+) |
| `getCapturableWindows()` | List capturable windows using ScreenCaptureKit (macOS 12.3+) |

### Permission Management (7 methods)

| Method | Description |
|--------|-------------|
| `hasScreenRecordingPermission()` | Check screen recording permission |
| `requestScreenRecordingPermission()` | Request screen recording permission |
| `openScreenRecordingSettings()` | Open system settings |
| `hasAccessibilityPermission()` | Check accessibility permission |
| `requestAccessibilityPermission()` | Request accessibility permission |
| `openAccessibilitySettings()` | Open system settings |
| `permissionStream` | Stream for monitoring permission changes |

### Application Management (5 methods)

| Method | Description |
|--------|-------------|
| `getAllInstalledApplications()` | Get all installed apps |
| `getApplicationByName(String name)` | Search apps by name |
| `openAppStoreSearch(String term)` | Open App Store search |
| `terminateApplicationByPID(int pid)` | Terminate app (requires Accessibility) |
| `terminateApplicationTree(int pid)` | Terminate app and children (requires Accessibility) |

### System Info (2 methods)

| Method | Description |
|--------|-------------|
| `getMacOSVersionInfo()` | Get macOS version and capabilities |
| `getChildProcesses(int pid)` | Get child process IDs |

## Permission Requirements

| Feature | Screen Recording | Accessibility |
|---------|------------------|---------------|
| Get window list | ❌ | ❌ |
| Get window **names** | ✅ | ❌ |
| Window capture | ✅ | ❌ |
| Close/focus windows | ❌ | ✅ |
| Terminate processes | ❌ | ✅ |
| Window role/subrole | ❌ | ✅ |

## Data Models

### MacosWindowInfo
```dart
class MacosWindowInfo {
  final int windowId;
  final String name;           // Empty if no screen recording permission
  final String ownerName;
  final double x, y, width, height;
  final int layer;
  final bool isOnScreen;
  final int processId;
  final String? role;          // Requires accessibility permission
  final String? subrole;       // Requires accessibility permission
}
```

### MacosApplicationInfo
```dart
class MacosApplicationInfo {
  final String name;
  final String bundleId;
  final String version;
  final String path;
  final String iconPath;
}
```

## Examples

### Permission Monitoring with Stream
```dart
toolkit.startPermissionWatching(
  interval: Duration(seconds: 2),
  emitOnlyChanges: true,
);

toolkit.permissionStream.listen((status) {
  print('Screen Recording: ${status.screenRecording}');
  print('Accessibility: ${status.accessibility}');
  if (status.allPermissionsGranted) {
    print('All ready!');
  }
});
```

### Advanced Window Filtering
```dart
final windows = await toolkit.getWindowsAdvanced(
  ownerName: 'Chrome',
  ownerNameCaseSensitive: false,
  isOnScreen: true,
  width: 800,  // Exact width
);
```

### Error Handling
```dart
try {
  final windows = await toolkit.getAllWindows();
} on PlatformException catch (e) {
  switch (e.code) {
    case 'SCREEN_RECORDING_PERMISSION_DENIED':
      await toolkit.openScreenRecordingSettings();
    case 'ACCESSIBILITY_PERMISSION_DENIED':
      await toolkit.openAccessibilitySettings();
  }
}
```

## Requirements

- macOS 10.15+ (14.0+ required for window capture)
- Flutter 3.10.0+
- Dart 3.0.0+
- **App Sandbox must be disabled**

## App Store Distribution

⚠️ **Not recommended** for App Store distribution due to sandbox requirements. This plugin requires system-level access that conflicts with App Store sandboxing policies. Consider:
- Distributing outside the App Store
- Requesting special entitlements from Apple (rarely approved)

## Example App

```bash
cd example/
flutter run -d macos
```

## Documentation

- [Full API Reference](documentations/api/)
- [Changelog](CHANGELOG.md)
- [Issue Tracker](https://github.com/kihyun1998/macos_window_toolkit/issues)

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

Made with ❤️ for the Flutter community
