# Window Management API

Complete reference for window discovery, filtering, and management operations.

## Overview

The Window Management API provides comprehensive functionality for discovering and interacting with windows across the macOS system. This includes retrieving window information, filtering windows by various criteria, checking window status, and performing window operations.

## Quick Reference

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| [`getAllWindows()`](#getallwindows) | Get all system windows | `excludeEmptyNames` | `Future<List<MacosWindowInfo>>` |
| [`getWindowsByName()`](#getwindowsbyname) | Filter windows by title | `name` | `Future<List<MacosWindowInfo>>` |
| [`getWindowsByOwnerName()`](#getwindowsbyownername) | Filter windows by application | `ownerName` | `Future<List<MacosWindowInfo>>` |
| [`getWindowById()`](#getwindowbyid) | Get specific window | `windowId` | `Future<List<MacosWindowInfo>>` |
| [`getWindowsByProcessId()`](#getwindowsbyprocessid) | Filter windows by process | `processId` | `Future<List<MacosWindowInfo>>` |
| [`isWindowAlive()`](#iswindowalive) | Check window existence | `windowId` | `Future<bool>` |
| [`closeWindow()`](#closewindow) | Close window via AppleScript | `windowId` | `Future<bool>` |

## Methods

### `getAllWindows()`

Retrieves information about all windows currently open on the system.

**Signature:**
```dart
Future<List<MacosWindowInfo>> getAllWindows({
  bool excludeEmptyNames = false,
})
```

**Parameters:**
- `excludeEmptyNames` (optional) - If `true`, windows with empty or missing names will be filtered out. Defaults to `false`.

**Returns:**
- `Future<List<MacosWindowInfo>>` - List of all windows with complete information

**Throws:**
- `PlatformException` - If unable to retrieve window information

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Get all windows including those with empty names
final allWindows = await toolkit.getAllWindows();
print('Found ${allWindows.length} total windows');

// Get only windows with non-empty names
final namedWindows = await toolkit.getAllWindows(excludeEmptyNames: true);
print('Found ${namedWindows.length} named windows');

for (final window in namedWindows) {
  print('Window: ${window.name} (${window.ownerName})');
  print('Position: (${window.x}, ${window.y})');
  print('Size: ${window.width} x ${window.height}');
  if (window.alpha != null) {
    print('Transparency: ${window.alpha}');
  }
}
```

**Performance Notes:**
- Fresh data retrieved from system on each call (not cached)
- Typical response time: 10-50ms for 20-100 windows
- Performance scales linearly with number of open windows

---

### `getWindowsByName()`

Retrieves windows filtered by name (window title).

**Signature:**
```dart
Future<List<MacosWindowInfo>> getWindowsByName(String name)
```

**Parameters:**
- `name` - Window title substring to search for (case-sensitive)

**Returns:**
- `Future<List<MacosWindowInfo>>` - List of windows whose title contains the specified string

**Throws:**
- `PlatformException` - If unable to retrieve window information

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Find all Chrome windows
final chromeWindows = await toolkit.getWindowsByName('Chrome');
print('Found ${chromeWindows.length} Chrome windows');

// Find all windows with "Untitled" in the name
final untitledWindows = await toolkit.getWindowsByName('Untitled');
for (final window in untitledWindows) {
  print('Untitled window in ${window.ownerName}: "${window.name}"');
}

// Find specific document
final docWindows = await toolkit.getWindowsByName('MyDocument.txt');
if (docWindows.isNotEmpty) {
  print('Found document at (${docWindows.first.x}, ${docWindows.first.y})');
}
```

**Notes:**
- Search is case-sensitive
- Uses substring matching, not exact match
- Empty string will return all windows with non-empty names

---

### `getWindowsByOwnerName()`

Retrieves windows filtered by owner name (application name).

**Signature:**
```dart
Future<List<MacosWindowInfo>> getWindowsByOwnerName(String ownerName)
```

**Parameters:**
- `ownerName` - Application name substring to search for (case-sensitive)

**Returns:**
- `Future<List<MacosWindowInfo>>` - List of windows owned by applications matching the name

**Throws:**
- `PlatformException` - If unable to retrieve window information

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Find all Safari windows
final safariWindows = await toolkit.getWindowsByOwnerName('Safari');
for (final window in safariWindows) {
  print('Safari window: "${window.name}"');
}

// Find all Finder windows
final finderWindows = await toolkit.getWindowsByOwnerName('Finder');
print('Open Finder windows: ${finderWindows.length}');

// Find all Microsoft Office applications
final officeWindows = await toolkit.getWindowsByOwnerName('Microsoft');
for (final window in officeWindows) {
  print('Office app: ${window.ownerName} - "${window.name}"');
}
```

**Common Application Names:**
- `"Google Chrome"`
- `"Safari"`
- `"Finder"`
- `"TextEdit"`
- `"Xcode"`
- `"Visual Studio Code"`
- `"Microsoft Word"`

---

### `getWindowById()`

Retrieves a specific window by its window ID.

**Signature:**
```dart
Future<List<MacosWindowInfo>> getWindowById(int windowId)
```

**Parameters:**
- `windowId` - Unique window identifier

**Returns:**
- `Future<List<MacosWindowInfo>>` - List containing the window with the specified ID, or empty list if not found

**Throws:**
- `PlatformException` - If unable to retrieve window information

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Get specific window
final windows = await toolkit.getWindowById(12345);
if (windows.isNotEmpty) {
  final window = windows.first;
  print('Found window: "${window.name}" in ${window.ownerName}');
  print('Position: (${window.x}, ${window.y})');
  print('Size: ${window.width} x ${window.height}');
} else {
  print('Window with ID 12345 not found');
}

// Check if window exists (alternative to isWindowAlive)
final exists = (await toolkit.getWindowById(windowId)).isNotEmpty;
if (exists) {
  print('Window still exists');
}
```

**Notes:**
- Returns a list for consistency with other methods, but will contain at most one window
- Window IDs are unique across all applications
- Window ID may be reused after a window is closed

---

### `getWindowsByProcessId()`

Retrieves windows filtered by process ID.

**Signature:**
```dart
Future<List<MacosWindowInfo>> getWindowsByProcessId(int processId)
```

**Parameters:**
- `processId` - Process ID of the application

**Returns:**
- `Future<List<MacosWindowInfo>>` - List of windows owned by the specified process

**Throws:**
- `PlatformException` - If unable to retrieve window information

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Get all windows from a specific process
final appWindows = await toolkit.getWindowsByProcessId(1234);
print('Process 1234 has ${appWindows.length} windows');

// Find process ID from existing window, then get all its windows
final allWindows = await toolkit.getAllWindows();
if (allWindows.isNotEmpty) {
  final firstWindow = allWindows.first;
  final processWindows = await toolkit.getWindowsByProcessId(firstWindow.processId);
  print('${firstWindow.ownerName} has ${processWindows.length} windows total');
}

// Group windows by application
final windowsByApp = <int, List<MacosWindowInfo>>{};
for (final window in allWindows) {
  windowsByApp.putIfAbsent(window.processId, () => []).add(window);
}
print('Found ${windowsByApp.length} applications with windows');
```

**Use Cases:**
- Finding all windows for a specific application
- Grouping windows by application
- Process-based window management

---

### `isWindowAlive()`

Checks if a window with the specified ID is currently alive/exists.

**Signature:**
```dart
Future<bool> isWindowAlive(int windowId)
```

**Parameters:**
- `windowId` - Unique window identifier to check

**Returns:**
- `Future<bool>` - `true` if the window exists, `false` otherwise

**Throws:**
- Generally does not throw exceptions; returns `false` for invalid IDs

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Check if window is still alive before operations
final windowId = 12345;
final isAlive = await toolkit.isWindowAlive(windowId);

if (isAlive) {
  print('Window $windowId is still available');
  
  // Safe to perform operations
  final result = await toolkit.captureWindow(windowId);
  // ... handle result
} else {
  print('Window $windowId no longer exists');
}

// Monitor window lifecycle
Timer.periodic(Duration(seconds: 1), (timer) async {
  if (!await toolkit.isWindowAlive(windowId)) {
    print('Window $windowId was closed');
    timer.cancel();
  }
});
```

**Performance:**
- Very fast operation (~1-2ms)
- Lightweight existence check without retrieving full window information
- Suitable for frequent polling

**Use Cases:**
- Validating window IDs before operations
- Monitoring window lifecycle
- Preventing operations on closed windows

---

### `closeWindow()`

Closes a window by its window ID using AppleScript.

**Signature:**
```dart
Future<bool> closeWindow(int windowId)
```

**Parameters:**
- `windowId` - Unique window identifier of the window to close

**Returns:**
- `Future<bool>` - `true` if the window was successfully closed, `false` otherwise

**Throws:**
- `PlatformException` with specific error codes:
  - `CLOSE_WINDOW_ERROR` - General window closing error
  - `WINDOW_NOT_FOUND` - Window with specified ID was not found
  - `INSUFFICIENT_WINDOW_INFO` - Not enough window information to close
  - `APPLESCRIPT_EXECUTION_FAILED` - AppleScript execution failed

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Close specific window
try {
  final success = await toolkit.closeWindow(12345);
  if (success) {
    print('Window closed successfully');
  } else {
    print('Failed to close window (may require user interaction)');
  }
} on PlatformException catch (e) {
  switch (e.code) {
    case 'WINDOW_NOT_FOUND':
      print('Window no longer exists');
      break;
    case 'APPLESCRIPT_EXECUTION_FAILED':
      print('AppleScript failed: ${e.message}');
      break;
    default:
      print('Error closing window: ${e.code} - ${e.message}');
  }
}

// Close all untitled documents
final untitledWindows = await toolkit.getWindowsByName('Untitled');
for (final window in untitledWindows) {
  try {
    final closed = await toolkit.closeWindow(window.windowId);
    if (closed) {
      print('Closed "${window.name}" in ${window.ownerName}');
    }
  } catch (e) {
    print('Failed to close "${window.name}": $e');
  }
}
```

**Important Notes:**
- Uses AppleScript to interact with application UI
- May require accessibility permissions on some systems
- Success depends on application's AppleScript support and window structure
- Some applications may show confirmation dialogs before closing
- Not all windows can be closed (e.g., system windows, modal dialogs)

**Limitations:**
- Doesn't work with all applications
- May be blocked by modal dialogs
- Requires application to support window closing via AppleScript
- User may need to interact with confirmation dialogs

---

## MacosWindowInfo Data Model

Complete information about a macOS window.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `windowId` | `int` | Unique system window identifier |
| `name` | `String` | Window title/name |
| `ownerName` | `String` | Application name that owns the window |
| `x` | `double` | X coordinate (left edge) |
| `y` | `double` | Y coordinate (top edge) |
| `width` | `double` | Window width in pixels |
| `height` | `double` | Window height in pixels |
| `layer` | `int` | Window layer level (higher = more front) |
| `isOnScreen` | `bool` | Whether window is currently visible |
| `processId` | `int` | Process ID of owning application |
| `storeType` | `int?` | Window store type (system internal) |
| `sharingState` | `int?` | Sharing state (0=None, 1=ReadOnly, 2=ReadWrite) |
| `alpha` | `double?` | Transparency (0.0=transparent, 1.0=opaque) |
| `memoryUsage` | `int?` | Memory usage in bytes |
| `isInVideoMemory` | `bool?` | Whether stored in video memory |
| `role` | `String?` | Window role via Accessibility API (e.g., "AXWindow", "AXDialog") |
| `subrole` | `String?` | Window subrole via Accessibility API (e.g., "AXStandardWindow", "AXFloatingWindow") |

### Constructor

```dart
const MacosWindowInfo({
  required this.windowId,
  required this.name,
  required this.ownerName,
  required this.x,
  required this.y,
  required this.width,
  required this.height,
  required this.layer,
  required this.isOnScreen,
  required this.processId,
  this.storeType,
  this.sharingState,
  this.alpha,
  this.memoryUsage,
  this.isInVideoMemory,
  this.role,
  this.subrole,
});
```

### Example Usage

```dart
final window = windows.first;

// Basic properties
print('Window: "${window.name}"');
print('App: ${window.ownerName}');
print('ID: ${window.windowId}');

// Position and size
print('Position: (${window.x}, ${window.y})');
print('Size: ${window.width} × ${window.height}');
print('Area: ${window.width * window.height} square pixels');

// Visibility and layering
print('Visible: ${window.isOnScreen}');
print('Layer: ${window.layer}');

// Advanced properties (may be null)
if (window.alpha != null) {
  final transparency = ((1.0 - window.alpha!) * 100).round();
  print('Transparency: ${transparency}%');
}

if (window.memoryUsage != null) {
  final mb = (window.memoryUsage! / (1024 * 1024)).toStringAsFixed(2);
  print('Memory usage: ${mb} MB');
}

if (window.isInVideoMemory != null) {
  print('Video memory: ${window.isInVideoMemory}');
}

// Window type information (requires Accessibility permission)
if (window.role != null) {
  print('Window role: ${window.role}');
}

if (window.subrole != null) {
  print('Window subrole: ${window.subrole}');
}
```

### Coordinate System

- Origin (0, 0) is at the top-left corner of the primary display
- Positive X extends to the right
- Positive Y extends downward
- Multi-monitor setups may have negative coordinates
- All measurements are in pixels

### Window States

#### `isOnScreen` Values

| Value | Meaning |
|-------|---------|
| `true` | Any portion of the window is visible |
| `false` | Window is hidden, minimized, or on different Space |

**False when:**
- Window is minimized to the Dock
- Window is hidden (Cmd+H)
- Window is on a different Space/Desktop
- Window is completely obscured by other windows

#### `layer` Values

| Range | Meaning |
|-------|---------|
| 0 | Normal application windows |
| 24 | Floating windows |
| 1000+ | Always-on-top windows |
| 2000+ | System UI elements |

## Best Practices

### Performance Optimization

```dart
// Cache window lists when possible
List<MacosWindowInfo>? cachedWindows;

Future<List<MacosWindowInfo>> getWindows() async {
  cachedWindows ??= await toolkit.getAllWindows();
  return cachedWindows!;
}

// Refresh cache when needed
void refreshCache() {
  cachedWindows = null;
}
```

### Error Handling

```dart
Future<List<MacosWindowInfo>> safeGetWindows() async {
  try {
    return await toolkit.getAllWindows();
  } on PlatformException catch (e) {
    print('Window enumeration failed: ${e.code} - ${e.message}');
    return <MacosWindowInfo>[];
  }
}
```

### Window Filtering

```dart
// Filter by multiple criteria
final windows = await toolkit.getAllWindows();

// Large windows only
final largeWindows = windows
    .where((w) => w.width > 500 && w.height > 300)
    .toList();

// Visible browser windows
final browserWindows = windows
    .where((w) => w.isOnScreen)
    .where((w) => w.ownerName.contains('Chrome') || 
                  w.ownerName.contains('Safari'))
    .toList();

// Windows by application
final windowsByApp = <String, List<MacosWindowInfo>>{};
for (final window in windows) {
  windowsByApp.putIfAbsent(window.ownerName, () => []).add(window);
}
```

### Window Monitoring

```dart
// Monitor specific window
void monitorWindow(int windowId) {
  Timer.periodic(Duration(seconds: 1), (timer) async {
    if (!await toolkit.isWindowAlive(windowId)) {
      print('Window $windowId was closed');
      timer.cancel();
      return;
    }
    
    final windows = await toolkit.getWindowById(windowId);
    if (windows.isNotEmpty) {
      final window = windows.first;
      print('Window at (${window.x}, ${window.y})');
    }
  });
}
```

## Thread Safety

All window management methods are thread-safe and can be called from any isolate.

## Related APIs

- **[Permission Management](permission_management.md)** - Handle screen recording permissions
- **[Window Capture](window_capture.md)** - Capture window screenshots
- **[Process Management](process_management.md)** - Manage window processes
- **[Error Handling](error_handling.md)** - Handle window-related errors

---

[← Back to API Reference](../api_reference.md)