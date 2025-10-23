# macOS Window Toolkit

[![pub package](https://img.shields.io/pub/v/macos_window_toolkit.svg)](https://pub.dev/packages/macos_window_toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for macOS that provides comprehensive window management and application discovery functionality. This plugin allows Flutter applications to retrieve detailed information about all open windows and installed applications on the macOS system, with type-safe APIs and structured error handling.

## Features

- 🪟 **Window Enumeration**: Get a list of all open windows on the system
- 📊 **Window Properties**: Access detailed window information including:
  - Window ID and title
  - Owner application name
  - Window bounds (position and size)
  - Window layer level
  - Visibility status
  - Process ID
  - Window role and subrole (via Accessibility API)
- 📱 **Application Discovery**: Discover and search installed applications with type-safe APIs
  - Get all installed applications system-wide
  - Search applications by name with case-insensitive matching
  - Rich application metadata (name, bundle ID, version, path, icon path)
  - Type-safe `ApplicationResult` with success/failure states
  - Comprehensive error handling with user-friendly messages
- 👀 **Real-time Permission Monitoring**: Monitor macOS permissions with live updates
  - Screen Recording permission tracking
  - Accessibility permission tracking
  - Configurable monitoring intervals
  - Type-safe permission status updates
  - Perfect integration with state management (Riverpod, Bloc, etc.)
- 🔐 **Permission Management**: Check and request macOS permissions
  - Screen recording permission
  - Accessibility permission
  - Open system preference panes
- 🚀 **High Performance**: Efficient native implementation using Core Graphics APIs
- 🛡️ **Privacy Compliant**: Includes proper privacy manifest for App Store distribution
- 🔧 **Easy Integration**: Simple API with comprehensive error handling
- ⚠️ **Enhanced Permission Detection**: Automatic detection and user-friendly handling of permission issues

## Platform Support

| Platform | Support |
|----------|---------|
| macOS    | ✅      |
| iOS      | ❌      |
| Android  | ❌      |
| Windows  | ❌      |
| Linux    | ❌      |
| Web      | ❌      |

**Minimum Requirements:**
- macOS 10.11 or later
- Flutter 3.3.0 or later
- Dart 3.8.1 or later

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  macos_window_toolkit: ^1.4.10
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Window Enumeration

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() async {
  final toolkit = MacosWindowToolkit();
  
  // Get all open windows
  final windows = await toolkit.getAllWindows();
  
  for (final window in windows) {
    print('Window: ${window.name}');
    print('App: ${window.ownerName}');
    print('Bounds: ${window.bounds}');
    print('---');
  }
}
```

### Application Discovery

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() async {
  final toolkit = MacosWindowToolkit();
  
  // Get all installed applications
  final result = await toolkit.getAllInstalledApplications();
  
  switch (result) {
    case ApplicationSuccess(applications: final apps):
      print('Found ${apps.length} applications');
      for (final app in apps) {
        print('${app.name} (${app.bundleId}) v${app.version}');
      }
    case ApplicationFailure():
      print('Failed: ${result.userMessage}');
  }
  
  // Search for specific application
  final safariResult = await toolkit.getApplicationByName('Safari');
  if (safariResult case ApplicationSuccess(applications: final safariApps)) {
    if (safariApps.isNotEmpty) {
      print('Found Safari at: ${safariApps.first.path}');
    }
  }
}
```

### Real-time Permission Monitoring

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() async {
  final toolkit = MacosWindowToolkit();
  
  // Start monitoring permissions every 2 seconds
  toolkit.startPermissionWatching();
  
  // Listen to permission changes
  toolkit.permissionStream.listen((status) {
    if (status.hasChanges) {
      print('Permission changed!');
      print('Screen Recording: ${status.screenRecording}');
      print('Accessibility: ${status.accessibility}');
      
      if (status.allPermissionsGranted) {
        print('All permissions granted! 🎉');
      } else {
        print('Missing: ${status.deniedPermissions.join(', ')}');
      }
    }
  });
}
```

## Usage

### Permission Monitoring with Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

// Create a StreamProvider for permission monitoring
final permissionProvider = StreamProvider<PermissionStatus>((ref) {
  final toolkit = MacosWindowToolkit();
  toolkit.startPermissionWatching(
    interval: const Duration(seconds: 2),
    emitOnlyChanges: true, // Only emit when permissions change
  );
  return toolkit.permissionStream;
});

// Use in your widget
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionProvider);
    
    return permissionAsync.when(
      data: (status) {
        if (status.allPermissionsGranted) {
          return MainApp(); // Show main app
        } else {
          return PermissionSetupScreen(
            missingPermissions: status.deniedPermissions,
          );
        }
      },
      loading: () => const LoadingScreen(),
      error: (error, _) => ErrorScreen(error: error),
    );
  }
}
```

### Basic Window Enumeration

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class WindowManager {
  final _toolkit = MacosWindowToolkit();
  
  Future<List<MacosWindowInfo>> getVisibleWindows() async {
    try {
      final windows = await _toolkit.getAllWindows();
      return windows.where((window) => window.isOnScreen).toList();
    } catch (e) {
      print('Error getting windows: $e');
      return [];
    }
  }
}
```

### Permission Management

```dart
final toolkit = MacosWindowToolkit();

// Check current permissions
final hasScreenRecording = await toolkit.hasScreenRecordingPermission();
final hasAccessibility = await toolkit.hasAccessibilityPermission();

// Request permissions
await toolkit.requestScreenRecordingPermission();
await toolkit.requestAccessibilityPermission();

// Open system settings
await toolkit.openScreenRecordingSettings();
await toolkit.openAccessibilitySettings();
```

### Application Discovery

```dart
final toolkit = MacosWindowToolkit();

// Get all applications with comprehensive error handling
final result = await toolkit.getAllInstalledApplications();

switch (result) {
  case ApplicationSuccess(applications: final apps):
    print('Successfully found ${apps.length} applications');
    
    // Filter applications by criteria
    final developerApps = apps.where((app) => 
      app.bundleId.contains('developer') || 
      app.name.toLowerCase().contains('xcode')
    ).toList();
    
    for (final app in developerApps) {
      print('Dev App: ${app.name}');
      print('Bundle ID: ${app.bundleId}');
      print('Version: ${app.version}');
      print('Path: ${app.path}');
      if (app.iconPath.isNotEmpty) {
        print('Icon: ${app.iconPath}');
      }
      print('---');
    }
    
  case ApplicationFailure(reason: final reason):
    print('Failed to get applications: ${reason.name}');
    print('User message: ${result.userMessage}');
    
    if (result.canRetry) {
      print('Suggested action: ${result.suggestedAction}');
      // Implement retry logic
    }
}

// Search for specific applications
final searchResult = await toolkit.getApplicationByName('Code');
if (searchResult case ApplicationSuccess(applications: final codeApps)) {
  for (final app in codeApps) {
    print('Found code editor: ${app.name} at ${app.path}');
  }
}

// App Store integration - search when app not found
final result = await toolkit.getApplicationByName('NonExistentApp');
switch (result) {
  case ApplicationSuccess(applications: final apps):
    if (apps.isEmpty) {
      print('App not found locally, searching in App Store...');
      final opened = await toolkit.openAppStoreSearch('NonExistentApp');
      if (opened) {
        print('App Store opened for search');
      }
    }
  case ApplicationFailure():
    print('Search failed: ${result.userMessage}');
}
```

### Application Information Structure

Each application object contains the following properties:

```dart
class MacosApplicationInfo {
  final String name;       // Application display name
  final String bundleId;   // Bundle identifier (e.g., "com.apple.Safari")
  final String version;    // Application version string
  final String path;       // Full path to application bundle
  final String iconPath;   // Path to application icon file
}
```

### Window Information Structure

Each window object contains the following properties:

```dart
class MacosWindowInfo {
  final int windowId;        // Unique window identifier
  final String name;         // Window title
  final String ownerName;    // Application name that owns the window
  final double x;            // X coordinate
  final double y;            // Y coordinate
  final double width;        // Width
  final double height;       // Height
  final int layer;           // Window layer level
  final bool isOnScreen;     // Whether window is visible
  final int processId;       // Process ID of the owning application
  final String? role;        // Window role (e.g., "AXWindow", "AXDialog")
  final String? subrole;     // Window subrole (e.g., "AXStandardWindow")
}
```

### Filtering Windows

```dart
// Filter by application
final chromeWindows = windows
    .where((w) => w.ownerName.contains('Chrome'))
    .toList();

// Filter by visibility
final visibleWindows = windows
    .where((w) => w.isOnScreen)
    .toList();

// Filter by size (width > 500px)
final largeWindows = windows
    .where((w) => w.bounds[2] > 500)
    .toList();
```

### Error Handling

```dart
try {
  final windows = await MacosWindowToolkit.getAllWindows();
  // Process windows
} on PlatformException catch (e) {
  switch (e.code) {
    case 'SCREEN_RECORDING_PERMISSION_DENIED':
      print('Screen recording permission required. Please enable it in System Settings.');
      break;
    case 'ACCESSIBILITY_PERMISSION_DENIED':
      print('Accessibility permission required for window management.');
      break;
    case 'REQUIRES_MACOS_14':
      print('This capture method requires macOS 14.0 or later.');
      break;
    case 'WINDOW_MINIMIZED':
      print('Cannot capture minimized window. Please restore it first.');
      break;
    default:
      print('Error: ${e.message}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Example App

The plugin includes a comprehensive example app that demonstrates all features:

```bash
cd example/
flutter run -d macos
```

The example app includes:
- Real-time window list updates
- Window search and filtering
- Detailed window information display
- Permission handling examples

## Privacy and Permissions

This plugin uses public macOS APIs that typically don't require explicit user permissions. However, some system configurations might require accessibility permissions for full functionality.

### App Sandbox Requirements

**Important**: Applications using this plugin must **disable App Sandbox** to function properly. This is because the plugin requires access to system-wide resources that are restricted in sandboxed environments.

#### Why Sandbox Must Be Disabled

The plugin uses the following APIs that require sandbox to be disabled:

1. **Window Information Access**
   - `CGWindowListCopyWindowInfo()` - Accesses window data from other applications
   - Sandboxed apps cannot read window information from other processes

2. **Accessibility API Operations**
   - `AXUIElementCreateApplication()` - Creates accessibility elements for other apps
   - `AXUIElementCopyAttributeValue()` - Reads window properties from other apps
   - `AXUIElementPerformAction()` - Performs actions (like closing windows) on other apps

3. **Process Control Operations**
   - `kill()` system calls - Terminates other processes
   - `sysctl()` - Queries system process lists
   - `NSRunningApplication` - Controls other applications

4. **Screen Capture (Legacy Support)**
   - `CGWindowListCreateImage()` - Captures screenshots of other app windows
   - Requires access to other applications' visual content

5. **Apple Events Communication**
   - Requires `com.apple.security.automation.apple-events` entitlement
   - Enables inter-app communication for window management

#### How to Disable Sandbox

To disable sandbox in your macOS app:

1. Open `macos/Runner/Release.entitlements` and `macos/Runner/DebugProfile.entitlements`
2. Set the sandbox key to `false`:

```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

3. Add Apple Events entitlement:

```xml
<key>com.apple.security.automation.apple-events</key>
<true/>
```

#### App Store Distribution

**Note**: Apps distributed through the Mac App Store typically require sandboxing. If you need App Store distribution, you may need to:
- Request special entitlements from Apple for system-level access
- Consider alternative approaches that work within sandbox restrictions
- Distribute outside the App Store

### Privacy Manifest

The plugin includes a privacy manifest (`PrivacyInfo.xcprivacy`) that declares:
- No user data collection
- No tracking functionality
- No network requests

## API Reference

### MacosWindowToolkit

The main class providing window management functionality.

#### Methods

##### `getAllWindows()`

Returns a list of all open windows on the system.

**Returns:** `Future<List<WindowInfo>>`

**Throws:** `PlatformException` if system error occurs

```dart
final windows = await MacosWindowToolkit.getAllWindows();
```

### WindowInfo

Data class representing a window's information.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `windowId` | `int` | Unique system window identifier |
| `name` | `String` | Window title or name |
| `ownerName` | `String` | Name of the application that owns the window |
| `x` | `double` | X coordinate of the window |
| `y` | `double` | Y coordinate of the window |
| `width` | `double` | Width of the window |
| `height` | `double` | Height of the window |
| `layer` | `int` | Window layer level (higher = more front) |
| `isOnScreen` | `bool` | Whether the window is currently visible |
| `processId` | `int` | Process ID of the owning application |
| `role` | `String?` | Window role (requires Accessibility permission) |
| `subrole` | `String?` | Window subrole (requires Accessibility permission) |

## Performance Considerations

- Window enumeration is performed on-demand (not cached)
- Each call returns fresh system data
- Large numbers of windows may impact performance
- Consider implementing pagination for apps with many windows

## Troubleshooting

### Common Issues

1. **Empty window list**: Check if other applications have windows open
2. **Permission errors**: Verify system accessibility permissions if needed
3. **Build errors**: Ensure minimum macOS version requirements are met

### Debug Mode

Enable verbose logging for debugging:

```bash
flutter run -d macos --verbose
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Run tests: `flutter test`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and version history.

## Support

- 📚 [Documentation](documentations/)
- 🐛 [Issue Tracker](https://github.com/kihyun/macos_window_toolkit/issues)
- 💬 [Discussions](https://github.com/kihyun/macos_window_toolkit/discussions)

---

Made with ❤️ for the Flutter community

