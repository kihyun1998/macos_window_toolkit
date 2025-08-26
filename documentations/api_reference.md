# API Reference

Complete reference documentation for macOS Window Toolkit.

## Overview

macOS Window Toolkit provides a simple yet powerful API for window management on macOS. The plugin exposes one main class (`MacosWindowToolkit`) and one data class (`WindowInfo`).

## MacosWindowToolkit

The main class providing window management functionality.

### Static Methods

#### `getAllWindows()`

Retrieves information about all open windows on the macOS system.

**Signature:**
```dart
static Future<List<WindowInfo>> getAllWindows()
```

**Returns:**
- `Future<List<WindowInfo>>` - A list of window information objects

**Throws:**
- `PlatformException` - When system errors occur
  - Code: `'SYSTEM_ERROR'` - General system error
  - Code: `'PERMISSION_DENIED'` - Insufficient permissions
  - Code: `'UNKNOWN_ERROR'` - Unexpected error

**Example:**
```dart
try {
  final windows = await MacosWindowToolkit.getAllWindows();
  print('Found ${windows.length} windows');
} on PlatformException catch (e) {
  print('Error: ${e.code} - ${e.message}');
}
```

**Performance Notes:**
- This operation queries the system directly (not cached)
- Performance scales with the number of open windows
- Typical response time: 10-50ms for 20-100 windows

**System Requirements:**
- macOS 10.11 or later
- No special permissions required for basic functionality

---

## WindowInfo

Data class representing information about a single window.

### Properties

#### `windowId`

**Type:** `int`

**Description:** Unique system identifier for the window. This ID is assigned by macOS and remains constant for the lifetime of the window.

**Usage:**
```dart
final window = windows.first;
print('Window ID: ${window.windowId}');
```

**Notes:**
- IDs are unique across all applications
- ID may be reused after a window is closed
- Useful for tracking specific windows over time

#### `name`

**Type:** `String`

**Description:** The title or name of the window as displayed in the title bar.

**Usage:**
```dart
final window = windows.first;
print('Window title: "${window.name}"');
```

**Notes:**
- May be empty for windows without titles
- Can change dynamically (e.g., browser tabs)
- Not guaranteed to be unique

**Common Values:**
- Document names: `\"Document.txt\"`
- Web pages: `\"Google - Chrome\"`
- Empty strings: `\"\"` (for system windows)

#### `ownerName`

**Type:** `String`

**Description:** The name of the application that owns this window.

**Usage:**
```dart
final window = windows.first;
print('Application: ${window.ownerName}');
```

**Examples:**
- `\"Google Chrome\"`
- `\"Finder\"`
- `\"TextEdit\"`
- `\"Xcode\"`

**Notes:**
- Always non-empty for valid windows
- Corresponds to the app name in the Dock/Applications folder
- Useful for filtering windows by application

#### `bounds`

**Type:** `List<double>`

**Description:** Window position and size as `[x, y, width, height]` in screen coordinates.

**Format:** `[x, y, width, height]`
- `bounds[0]` (x) - Horizontal position from left edge of screen
- `bounds[1]` (y) - Vertical position from top edge of screen  
- `bounds[2]` (width) - Window width in pixels
- `bounds[3]` (height) - Window height in pixels

**Usage:**
```dart
final window = windows.first;
final x = window.bounds[0];
final y = window.bounds[1];
final width = window.bounds[2];
final height = window.bounds[3];

print('Position: ($x, $y)');
print('Size: ${width}×$height');
print('Area: ${width * height} square pixels');
```

**Coordinate System:**
- Origin (0, 0) is at the top-left corner of the primary display
- Positive X extends to the right
- Positive Y extends downward
- Multi-monitor setups may have negative coordinates

**Helper Methods:**
```dart
extension WindowInfoExtensions on WindowInfo {
  double get x => bounds[0];
  double get y => bounds[1];  
  double get width => bounds[2];
  double get height => bounds[3];
  double get area => width * height;
  bool get isLandscape => width > height;
  bool get isPortrait => height > width;
}
```

#### `layer`

**Type:** `int`

**Description:** Window layer level. Higher values indicate windows that appear in front of others.

**Usage:**
```dart
final window = windows.first;
print('Window layer: ${window.layer}');
```

**Typical Values:**
- `0` - Normal application windows
- `24` - Floating windows
- `1000+` - Always-on-top windows
- `2000+` - System UI elements

**Notes:**
- Not guaranteed to be unique
- Can change when windows are brought to front
- Useful for z-order sorting

#### `isOnScreen`

**Type:** `bool`

**Description:** Whether the window is currently visible on screen.

**Usage:**
```dart
final window = windows.first;
if (window.isOnScreen) {
  print('Window is visible');
} else {
  print('Window is hidden');
}
```

**False When:**
- Window is minimized to the Dock
- Window is hidden (Cmd+H)
- Window is on a different Space/Desktop
- Window is completely obscured by other windows

**True When:**
- Any portion of the window is visible
- Window is partially off-screen but still visible

#### `processId`

**Type:** `int`

**Description:** Process ID (PID) of the application that owns this window.

**Usage:**
```dart
final window = windows.first;
print('Process ID: ${window.processId}');
```

**Uses:**
- Correlating windows with running processes
- System monitoring and debugging
- Process management operations

**Notes:**
- Multiple windows can have the same PID
- PID is assigned by the operating system
- Can be used with system APIs for process information

---

## Data Structures

### WindowInfo Constructor

```dart
WindowInfo({
  required this.windowId,
  required this.name,
  required this.ownerName,  
  required this.bounds,
  required this.layer,
  required this.isOnScreen,
  required this.processId,
});
```

### WindowInfo JSON Serialization

While not exposed publicly, the plugin uses the following JSON structure internally:

```json
{
  \"windowId\": 123,
  \"name\": \"Document.txt\",
  \"ownerName\": \"TextEdit\",
  \"bounds\": [100.0, 200.0, 800.0, 600.0],
  \"layer\": 0,
  \"isOnScreen\": true,
  \"processId\": 1234
}
```

---

## Error Handling

### PlatformException Codes

#### `SYSTEM_ERROR`

**Description:** General system error occurred while querying window information.

**Possible Causes:**
- Insufficient system resources
- macOS API failure
- Internal plugin error

**Handling:**
```dart
} on PlatformException catch (e) {
  if (e.code == 'SYSTEM_ERROR') {
    // Retry after delay or show user-friendly error
    print('System error: ${e.message}');
  }
}
```

#### `PERMISSION_DENIED`

**Description:** Insufficient permissions to access window information.

**Possible Causes:**
- Accessibility permissions not granted
- Security restrictions
- Sandboxing limitations

**Handling:**
```dart
} on PlatformException catch (e) {
  if (e.code == 'PERMISSION_DENIED') {
    // Guide user to grant permissions
    _showPermissionDialog();
  }
}
```

#### `UNKNOWN_ERROR`

**Description:** An unexpected error occurred.

**Handling:**
```dart
} on PlatformException catch (e) {
  if (e.code == 'UNKNOWN_ERROR') {
    // Log error and show generic message
    print('Unexpected error: ${e.message}');
  }
}
```

### Best Practices

1. **Always use try-catch** when calling `getAllWindows()`
2. **Handle specific error codes** for better user experience
3. **Provide fallback behavior** when windows can't be retrieved
4. **Log errors** for debugging purposes

```dart
Future<List<WindowInfo>> _safeGetAllWindows() async {
  try {
    return await MacosWindowToolkit.getAllWindows();
  } on PlatformException catch (e) {
    // Log the error
    debugPrint('Failed to get windows: ${e.code} - ${e.message}');
    
    // Return empty list as fallback
    return [];
  } catch (e) {
    debugPrint('Unexpected error getting windows: $e');
    return [];
  }
}
```

---

## Platform Channel Details

For advanced users and contributors:

### Channel Identifier
`\"macos_window_toolkit\"`

### Method Names
- `\"getAllWindows\"` - Retrieve all window information

### Arguments
None required for current API.

### Return Format
List of Maps with the following structure:
```dart
List<Map<String, dynamic>>
```

Each map contains the window properties as defined in the WindowInfo class.

---

## Thread Safety

- All methods are safe to call from any isolate
- Window information is retrieved synchronously from the system
- No shared state between method calls

## Memory Considerations

- Window list is created fresh on each call
- No caching is performed by the plugin
- Memory usage scales with the number of open windows
- Typical memory usage: ~1KB per 100 windows