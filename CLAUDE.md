# CLAUDE.md

This documentation is designed to help Claude Code instances understand and work with this codebase effectively.

## Project Overview

**macos_window_toolkit** is a Flutter plugin for macOS that provides window management functionality. It allows Flutter applications to retrieve information about all open windows on the system, including window properties like title, bounds, owner application, and process ID.

### Architecture Pattern

This plugin follows the standard Flutter plugin architecture with three layers:

1. **Flutter Dart Layer** (`lib/`) - Public API and platform interface
2. **Method Channel Bridge** - Communication between Dart and native code
3. **Swift Native Layer** (`macos/`) - Platform-specific implementation using macOS APIs

## Project Structure

```
macos_window_toolkit/
├── lib/                                    # Flutter Dart code
│   ├── macos_window_toolkit.dart          # Main export file
│   └── src/
│       ├── macos_window_toolkit.dart      # Main API class
│       ├── macos_window_toolkit_platform_interface.dart  # Platform interface
│       └── macos_window_toolkit_method_channel.dart      # Method channel implementation
├── macos/                                  # macOS native implementation
│   ├── Classes/
│   │   ├── MacosWindowToolkitPlugin.swift # Plugin registration and method handling
│   │   └── WindowHandler.swift           # Core window management logic
│   ├── Resources/
│   │   └── PrivacyInfo.xcprivacy         # Privacy manifest
│   └── macos_window_toolkit.podspec      # CocoaPods specification
├── example/                               # Example Flutter app
│   ├── lib/main.dart                     # Demo application
│   ├── macos/                            # macOS app configuration
│   └── integration_test/                 # Integration tests
└── test/                                 # Unit tests
```

## Key Files and Their Purposes

### Flutter Dart Layer

- **`lib/macos_window_toolkit.dart`**: Main export file that exposes the public API
- **`lib/src/macos_window_toolkit.dart`**: Contains the `MacosWindowToolkit` class with `getAllWindows()` method
- **`lib/src/macos_window_toolkit_platform_interface.dart`**: Abstract platform interface using the platform interface pattern
- **`lib/src/macos_window_toolkit_method_channel.dart`**: Method channel implementation that communicates with native code

### Swift Native Layer

- **`macos/Classes/MacosWindowToolkitPlugin.swift`**: Main plugin class that registers with Flutter and handles method calls
- **`macos/Classes/WindowHandler.swift`**: Core business logic for window management using `CGWindowListCopyWindowInfo`
- **`macos/macos_window_toolkit.podspec`**: CocoaPods specification file for dependency management

### Configuration

- **`pubspec.yaml`**: Plugin configuration with macOS platform specification
- **`example/pubspec.yaml`**: Example app dependencies and configuration
- **`macos/Resources/PrivacyInfo.xcprivacy`**: Apple privacy manifest (required for App Store)

## Development Commands

### Building and Running

```bash
# Navigate to example directory
cd example/

# Install dependencies
flutter pub get

# Run on macOS
flutter run -d macos

# Build macOS app
flutter build macos

# Clean build artifacts
flutter clean
```

### Testing

```bash
# Run unit tests (from plugin root)
flutter test

# Run integration tests (from example directory)
cd example/
flutter test integration_test/

# Run example app tests
flutter test test/
```

### Plugin Development

```bash
# Install plugin dependencies (from plugin root)
flutter pub get

# Validate pubspec and dependencies
flutter pub deps

# Check code analysis
flutter analyze

# Format code
dart format lib/ test/

# Validate CocoaPods podspec
cd macos/
pod lib lint macos_window_toolkit.podspec
```

## API Implementation Details

### Method Channel Communication

The plugin uses a single method channel with identifier `"macos_window_toolkit"`:

- **Method**: `getAllWindows`
- **Arguments**: None
- **Return**: `List<Map<String, dynamic>>` containing window information

### Window Data Structure

Each window object contains:

```dart
{
  "windowId": int,           // Unique window identifier
  "name": String,            // Window title/name
  "ownerName": String,       // Application name
  "bounds": [x, y, w, h],    // Position and size as List<double>
  "layer": int,              // Window layer level
  "isOnScreen": bool,        // Visibility status
  "processId": int           // Process ID of owning application
}
```

### Native Implementation

The Swift implementation uses Core Graphics APIs:
- `CGWindowListCopyWindowInfo()` to retrieve window list
- `.optionOnScreenOnly` and `.excludeDesktopElements` options
- Extracts window properties using Core Graphics constants

## Platform Requirements

- **macOS**: 10.11 or later
- **Swift**: 5.0
- **Flutter**: 3.3.0 or later
- **Dart**: 3.8.1 or later

## Testing Strategy

### Unit Tests
- Method channel mocking
- Platform interface validation
- Data serialization testing

### Integration Tests
- Full plugin functionality testing
- Real macOS window enumeration
- Error handling validation

## Common Development Tasks

### Adding New Window Operations

1. **Update Platform Interface**: Add new method to `MacosWindowToolkitPlatform`
2. **Implement Method Channel**: Add method call handling in `MethodChannelMacosWindowToolkit`
3. **Update Main API**: Add public method to `MacosWindowToolkit` class
4. **Native Implementation**: Add Swift method to `WindowHandler` and register in plugin
5. **Update Tests**: Add corresponding unit and integration tests

### Debugging

```bash
# Enable verbose logging
flutter run -d macos --verbose

# Check native logs (use Console.app or)
log stream --predicate 'subsystem contains "flutter"'

# Debug method channel calls
flutter logs
```

### Building for Distribution

```bash
# Build release version
flutter build macos --release

# Create universal binary
flutter build macos --release --universal

# For plugin development, test with example app
cd example/
flutter build macos --release
```

## Dependencies

### Dart Dependencies
- `flutter` (SDK)
- `plugin_platform_interface: ^2.0.2`

### Development Dependencies
- `flutter_test` (SDK)
- `flutter_lints: ^5.0.0`

### Native Dependencies
- `FlutterMacOS` (via CocoaPods)
- `Cocoa` framework
- `Foundation` framework

## Privacy and Permissions

The plugin includes a privacy manifest (`PrivacyInfo.xcprivacy`) declaring:
- No user data collection
- No tracking
- No tracking domains

The window enumeration functionality may require accessibility permissions in some contexts, though the current implementation uses public APIs that typically don't require explicit permissions.

## Error Handling

The plugin implements comprehensive error handling:
- Swift errors wrapped in `WindowError` enum
- Method channel errors returned as `FlutterError`
- Dart exceptions wrapped in `PlatformException`

## Performance Considerations

- Window enumeration is performed on-demand
- Results are not cached (fresh data on each call)
- Large window lists may impact performance
- Consider pagination for applications with many windows

## Flutter Development Preferences

### Widget Architecture

**Preferred Approach**: Use class-based widget declarations with `StatelessWidget` and `StatefulWidget` instead of function-based widgets.

**✅ Preferred:**
```dart
class MyCustomWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  
  const MyCustomWidget({
    super.key,
    required this.title,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
```

**❌ Avoid:**
```dart
Widget _buildCustomWidget(String title, VoidCallback onTap) {
  return Card(
    child: ListTile(
      title: Text(title),
      onTap: onTap,
    ),
  );
}
```

**Reasons for class-based approach:**
- Better performance (widget can be const and optimizes rebuilds)
- Clearer separation of concerns
- Better IDE support and refactoring capabilities
- Easier testing and debugging
- Follows Flutter best practices and conventions
- Better widget tree visualization in Flutter Inspector

### Example App Structure

The example app follows a modular widget structure:
```
example/lib/
├── main.dart                    # Main app and page logic
└── widgets/
    ├── permission_card.dart     # Permission status display
    ├── search_controls.dart     # Search and control components
    ├── windows_list.dart        # Window list with empty states
    ├── window_card.dart         # Individual window display
    └── window_detail_sheet.dart # Window details modal
```

Each widget is implemented as a proper class extending `StatelessWidget` with clear prop definitions and const constructors where possible.

## Future Development

Potential enhancements:
- Window manipulation (move, resize, close)
- Window focus/activation
- Window event notifications
- Filtering and search capabilities
- Window screenshots/thumbnails