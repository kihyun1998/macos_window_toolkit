# macOS Window Toolkit

[![pub package](https://img.shields.io/pub/v/macos_window_toolkit.svg)](https://pub.dev/packages/macos_window_toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for macOS that provides comprehensive window management functionality. This plugin allows Flutter applications to retrieve detailed information about all open windows on the macOS system, including window properties like title, bounds, owner application, and process ID.

## Features

- 🪟 **Window Enumeration**: Get a list of all open windows on the system
- 📊 **Window Properties**: Access detailed window information including:
  - Window ID and title
  - Owner application name
  - Window bounds (position and size)
  - Window layer level
  - Visibility status
  - Process ID
- 🚀 **High Performance**: Efficient native implementation using Core Graphics APIs
- 🛡️ **Privacy Compliant**: Includes proper privacy manifest for App Store distribution
- 🔧 **Easy Integration**: Simple API with comprehensive error handling

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
  macos_window_toolkit: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() async {
  // Get all open windows
  final windows = await MacosWindowToolkit.getAllWindows();
  
  for (final window in windows) {
    print('Window: ${window.name}');
    print('App: ${window.ownerName}');
    print('Bounds: ${window.bounds}');
    print('---');
  }
}
```

## Usage

### Basic Window Enumeration

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class WindowManager {
  static Future<List<WindowInfo>> getVisibleWindows() async {
    try {
      final windows = await MacosWindowToolkit.getAllWindows();
      return windows.where((window) => window.isOnScreen).toList();
    } catch (e) {
      print('Error getting windows: $e');
      return [];
    }
  }
}
```

### Window Information Structure

Each window object contains the following properties:

```dart
class WindowInfo {
  final int windowId;        // Unique window identifier
  final String name;         // Window title
  final String ownerName;    // Application name that owns the window
  final List<double> bounds; // [x, y, width, height]
  final int layer;           // Window layer level
  final bool isOnScreen;     // Whether window is visible
  final int processId;       // Process ID of the owning application
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
    case 'PERMISSION_DENIED':
      print('Permission denied to access window information');
      break;
    case 'SYSTEM_ERROR':
      print('System error occurred: ${e.message}');
      break;
    default:
      print('Unknown error: ${e.message}');
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
| `bounds` | `List<double>` | Window bounds as [x, y, width, height] |
| `layer` | `int` | Window layer level (higher = more front) |
| `isOnScreen` | `bool` | Whether the window is currently visible |
| `processId` | `int` | Process ID of the owning application |

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

- 📚 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/kihyun/macos_window_toolkit/issues)
- 💬 [Discussions](https://github.com/kihyun/macos_window_toolkit/discussions)

---

Made with ❤️ for the Flutter community

