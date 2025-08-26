# Getting Started

This guide will help you get up and running with macOS Window Toolkit in your Flutter application.

## Prerequisites

Before you begin, ensure you have:

- **macOS 10.11** or later
- **Flutter 3.3.0** or later
- **Dart 3.8.1** or later
- A macOS development environment

## Installation

### 1. Add to pubspec.yaml

Add the plugin to your Flutter project's `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  macos_window_toolkit: ^1.0.0
```

### 2. Install the package

Run the following command in your project directory:

```bash
flutter pub get
```

### 3. Import the package

Import the plugin in your Dart code:

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';
```

## Basic Usage

### Your First Window List

Here's a simple example to get all open windows:

```dart
import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class WindowListPage extends StatefulWidget {
  @override
  _WindowListPageState createState() => _WindowListPageState();
}

class _WindowListPageState extends State<WindowListPage> {
  List<WindowInfo> windows = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWindows();
  }

  Future<void> _loadWindows() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await MacosWindowToolkit.getAllWindows();
      setState(() {
        windows = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Open Windows'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWindows,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWindows,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (windows.isEmpty) {
      return Center(
        child: Text('No windows found'),
      );
    }

    return ListView.builder(
      itemCount: windows.length,
      itemBuilder: (context, index) {
        final window = windows[index];
        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(window.name),
            subtitle: Text(window.ownerName),
            trailing: window.isOnScreen
                ? Icon(Icons.visibility, color: Colors.green)
                : Icon(Icons.visibility_off, color: Colors.grey),
            onTap: () => _showWindowDetails(window),
          ),
        );
      },
    );
  }

  void _showWindowDetails(WindowInfo window) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(window.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Application', window.ownerName),
            _buildDetailRow('Window ID', window.windowId.toString()),
            _buildDetailRow('Process ID', window.processId.toString()),
            _buildDetailRow('Layer', window.layer.toString()),
            _buildDetailRow('Visible', window.isOnScreen ? 'Yes' : 'No'),
            _buildDetailRow('Position', '(${window.bounds[0]}, ${window.bounds[1]})'),
            _buildDetailRow('Size', '${window.bounds[2]} × ${window.bounds[3]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
```

## Understanding WindowInfo

Each window in the list contains detailed information:

```dart
class WindowInfo {
  final int windowId;        // Unique identifier for the window
  final String name;         // Window title (may be empty)
  final String ownerName;    // Name of the application that owns the window
  final List<double> bounds; // [x, y, width, height] in screen coordinates
  final int layer;           // Window layer (higher = more in front)
  final bool isOnScreen;     // Whether the window is currently visible
  final int processId;       // Process ID of the owning application
}
```

### Window Bounds

The `bounds` array contains four values:
- `bounds[0]` - X position (distance from left edge of screen)
- `bounds[1]` - Y position (distance from top edge of screen)
- `bounds[2]` - Width of the window
- `bounds[3]` - Height of the window

```dart
final window = windows.first;
print('Window position: (${window.bounds[0]}, ${window.bounds[1]})');
print('Window size: ${window.bounds[2]} × ${window.bounds[3]}');
```

## Common Patterns

### Filter Visible Windows Only

```dart
final visibleWindows = await MacosWindowToolkit.getAllWindows();
final onScreenWindows = visibleWindows.where((w) => w.isOnScreen).toList();
```

### Group Windows by Application

```dart
final windows = await MacosWindowToolkit.getAllWindows();
final groupedWindows = <String, List<WindowInfo>>{};

for (final window in windows) {
  groupedWindows.putIfAbsent(window.ownerName, () => []).add(window);
}
```

### Find Largest Window

```dart
final windows = await MacosWindowToolkit.getAllWindows();
if (windows.isNotEmpty) {
  final largestWindow = windows.reduce((a, b) {
    final aArea = a.bounds[2] * a.bounds[3];
    final bArea = b.bounds[2] * b.bounds[3];
    return aArea > bArea ? a : b;
  });
  print('Largest window: ${largestWindow.name} (${largestWindow.ownerName})');
}
```

## Error Handling

Always wrap your calls in try-catch blocks:

```dart
try {
  final windows = await MacosWindowToolkit.getAllWindows();
  // Process windows
} on PlatformException catch (e) {
  print('Platform error: ${e.message}');
  // Handle platform-specific errors
} catch (e) {
  print('General error: $e');
  // Handle other errors
}
```

## Performance Tips

1. **Don't call too frequently**: Window enumeration has some overhead
2. **Filter early**: Apply filters to reduce data processing
3. **Use setState wisely**: Only update UI when necessary
4. **Consider pagination**: For apps with many windows

## Next Steps

- Read the [API Reference](api_reference.md) for complete documentation
- Check out [Advanced Usage](advanced_usage.md) for complex scenarios
- Browse [Examples](examples.md) for more code samples
- See the [Example App](../example/) for a complete implementation

## Common Issues

If you encounter problems, check the [Troubleshooting Guide](troubleshooting.md) for solutions to common issues.