# Window Capture API

Complete reference for window screenshot capture using modern ScreenCaptureKit and legacy methods.

## Overview

The Window Capture API provides comprehensive functionality for capturing window screenshots on macOS. It supports both modern ScreenCaptureKit (macOS 12.3+) and legacy CGWindowListCreateImage methods, with automatic method selection for optimal compatibility and quality.

## Quick Reference

### Capture Methods
| Method | Description | Requirements | Returns |
|--------|-------------|--------------|---------|
| [`captureWindowAuto()`](#capturewindowauto) | **Recommended** - Auto-selects best method | macOS 10.11+ | `Future<CaptureResult>` |
| [`captureWindow()`](#capturewindow) | High-quality ScreenCaptureKit capture | macOS 12.3+ | `Future<CaptureResult>` |
| [`captureWindowLegacy()`](#capturewindowlegacy) | Legacy CGWindowListCreateImage | macOS 10.5+ | `Future<CaptureResult>` |

### Window Discovery
| Method | Description | Requirements | Returns |
|--------|-------------|--------------|---------|
| [`getCapturableWindowsAuto()`](#getcapturablewindowsauto) | **Recommended** - Auto-selects best method | macOS 10.11+ | `Future<List<CapturableWindowInfo>>` |
| [`getCapturableWindows()`](#getcapturablewindows) | ScreenCaptureKit window listing | macOS 12.3+ | `Future<List<CapturableWindowInfo>>` |
| [`getCapturableWindowsLegacy()`](#getcapturablewindowslegacy) | Legacy window listing | macOS 10.5+ | `Future<List<CapturableWindowInfo>>` |

### System Information
| Method | Description | Returns |
|--------|-------------|---------|
| [`getCaptureMethodInfo()`](#getcapturemethodinfo) | Get current capture capabilities | `Future<Map<String, dynamic>>` |

## Auto-Selection Methods (Recommended)

### `captureWindowAuto()`

Captures a window using the best available method with automatic selection.

**Signature:**
```dart
Future<CaptureResult> captureWindowAuto(
  int windowId, {
  bool excludeTitlebar = false,
  double? customTitlebarHeight,
})
```

**Parameters:**
- `windowId` - Unique window identifier from window listing methods
- `excludeTitlebar` (optional) - If `true`, removes titlebar from capture. Defaults to `false`.
- `customTitlebarHeight` (optional) - Custom titlebar height in points. Uses 28pt default if null.

**Returns:**
- `Future<CaptureResult>` - Success with image data or failure with detailed reason

**Method Selection Logic:**
- Uses **ScreenCaptureKit** on macOS 14.0+ for optimal quality
- Falls back to **CGWindowListCreateImage** on older versions or if ScreenCaptureKit fails
- Automatically handles compatibility without version checks

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Get capturable windows (recommended way)
final windows = await toolkit.getCapturableWindowsAuto();
if (windows.isEmpty) {
  print('No capturable windows found');
  return;
}

// Capture first window
final window = windows.first;
final result = await toolkit.captureWindowAuto(window.windowId);

switch (result) {
  case CaptureSuccess(:final imageData):
    print('Captured ${imageData.length} bytes');
    
    // Save to file
    final file = File('captured_window.png');
    await file.writeAsBytes(imageData);
    print('Saved to ${file.path}');
    
    // Display in Flutter
    final image = Image.memory(imageData);
    // Use image in widget tree
    
  case CaptureFailure(:final reason, :final message):
    print('Capture failed: ${reason.name}');
    if (message != null) print('Details: $message');
    
    // Handle specific failures
    switch (reason) {
      case CaptureFailureReason.windowMinimized:
        print('Please restore the window from dock');
        break;
      case CaptureFailureReason.permissionDenied:
        print('Screen recording permission required');
        await toolkit.requestScreenRecordingPermission();
        break;
      case CaptureFailureReason.windowNotFound:
        print('Window was closed or no longer exists');
        break;
      default:
        print('Capture failed: ${result.userMessage}');
    }
}
```

**Advanced Usage with Titlebar Removal:**
```dart
// Capture without titlebar (standard height)
final result = await toolkit.captureWindowAuto(
  windowId,
  excludeTitlebar: true,
);

// Capture with custom titlebar height
final result = await toolkit.captureWindowAuto(
  windowId,
  excludeTitlebar: true,
  customTitlebarHeight: 32.0, // Larger titlebar
);
```

**Performance:**
- ScreenCaptureKit: ~50-200ms depending on window size
- Legacy method: ~100-500ms depending on window size
- Automatically uses fastest available method

---

### `getCapturableWindowsAuto()`

Gets list of capturable windows using the best available method.

**Signature:**
```dart
Future<List<CapturableWindowInfo>> getCapturableWindowsAuto()
```

**Returns:**
- `Future<List<CapturableWindowInfo>>` - List of windows optimized for capture

**Method Selection Logic:**
- Uses **ScreenCaptureKit** on macOS 12.3+ for better window information
- Falls back to **CGWindowListCopyWindowInfo** on older versions

**Example:**
```dart
final toolkit = MacosWindowToolkit();

try {
  final windows = await toolkit.getCapturableWindowsAuto();
  
  print('Found ${windows.length} capturable windows:');
  for (final window in windows) {
    print('');
    print('Title: "${window.title}"');
    print('App: ${window.ownerName}');
    print('Bundle: ${window.bundleIdentifier}'); // May be empty on legacy method
    print('Size: ${window.frame.width} × ${window.frame.height}');
    print('Position: (${window.frame.x}, ${window.frame.y})');
    print('Visible: ${window.isOnScreen}');
    print('Window ID: ${window.windowId}');
  }
  
  // Filter for specific applications
  final chromeWindows = windows
      .where((w) => w.ownerName.contains('Chrome'))
      .toList();
  print('\nFound ${chromeWindows.length} Chrome windows');
  
} catch (e) {
  print('Failed to get capturable windows: $e');
}
```

**Filtering Examples:**
```dart
final windows = await toolkit.getCapturableWindowsAuto();

// Only visible windows
final visibleWindows = windows
    .where((w) => w.isOnScreen)
    .toList();

// Large windows only
final largeWindows = windows
    .where((w) => w.frame.width > 500 && w.frame.height > 300)
    .toList();

// Specific applications
final appWindows = windows
    .where((w) => w.bundleIdentifier == 'com.apple.finder')
    .toList();

// Sort by size (largest first)
windows.sort((a, b) {
  final aArea = a.frame.width * a.frame.height;
  final bArea = b.frame.width * b.frame.height;
  return bArea.compareTo(aArea);
});
```

---

## ScreenCaptureKit Methods (Modern)

### `captureWindow()`

Captures a window using ScreenCaptureKit for high-quality results.

**Signature:**
```dart
Future<CaptureResult> captureWindow(
  int windowId, {
  bool excludeTitlebar = false,
  double? customTitlebarHeight,
})
```

**Requirements:**
- macOS 12.3 or later
- Screen recording permission

**Returns:**
- `Future<CaptureResult>` - Success with high-quality image data or detailed failure

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Check if ScreenCaptureKit is available
final versionInfo = await toolkit.getMacOSVersionInfo();
if (!versionInfo.isScreenCaptureKitAvailable) {
  print('ScreenCaptureKit not available, use captureWindowLegacy() instead');
  return;
}

// Get ScreenCaptureKit windows
final windows = await toolkit.getCapturableWindows();
if (windows.isEmpty) {
  print('No ScreenCaptureKit windows available');
  return;
}

final result = await toolkit.captureWindow(windows.first.windowId);
switch (result) {
  case CaptureSuccess(:final imageData):
    print('High-quality capture: ${imageData.length} bytes');
    
  case CaptureFailure(:final reason):
    print('ScreenCaptureKit capture failed: ${reason.name}');
    
    // Fallback to legacy method
    print('Falling back to legacy capture...');
    final legacyResult = await toolkit.captureWindowLegacy(windows.first.windowId);
    // Handle legacy result...
}
```

**Quality Benefits:**
- Better color accuracy
- Improved performance for large windows
- More accurate window bounds
- Better handling of transparency

---

### `getCapturableWindows()`

Gets list of capturable windows using ScreenCaptureKit.

**Signature:**
```dart
Future<List<CapturableWindowInfo>> getCapturableWindows()
```

**Requirements:**
- macOS 12.3 or later

**Returns:**
- `Future<List<CapturableWindowInfo>>` - List with complete window information including bundle identifiers

**Throws:**
- `PlatformException` with error codes:
  - `UNSUPPORTED_MACOS_VERSION` - macOS version doesn't support ScreenCaptureKit
  - `SCREENCAPTUREKIT_NOT_AVAILABLE` - ScreenCaptureKit framework unavailable
  - `CAPTURE_FAILED` - Failed to retrieve windows

**Example:**
```dart
final toolkit = MacosWindowToolkit();

try {
  final windows = await toolkit.getCapturableWindows();
  
  // ScreenCaptureKit provides bundle identifiers
  for (final window in windows) {
    print('App: ${window.ownerName} (${window.bundleIdentifier})');
    print('Window: "${window.title}"');
    
    // Use bundle identifier for precise filtering
    if (window.bundleIdentifier == 'com.google.Chrome') {
      print('This is definitely Chrome');
    }
  }
  
} on PlatformException catch (e) {
  switch (e.code) {
    case 'UNSUPPORTED_MACOS_VERSION':
      print('ScreenCaptureKit requires macOS 12.3+');
      // Use legacy method instead
      final legacyWindows = await toolkit.getCapturableWindowsLegacy();
      break;
      
    case 'SCREENCAPTUREKIT_NOT_AVAILABLE':
      print('ScreenCaptureKit framework not available');
      break;
      
    default:
      print('Error: ${e.message}');
  }
}
```

---

## Legacy Methods (Compatible)

### `captureWindowLegacy()`

Captures a window using CGWindowListCreateImage for maximum compatibility.

**Signature:**
```dart
Future<CaptureResult> captureWindowLegacy(
  int windowId, {
  bool excludeTitlebar = false,
  double? customTitlebarHeight,
})
```

**Requirements:**
- macOS 10.5 or later (virtually all systems)
- Screen recording permission (on macOS 10.15+)

**Returns:**
- `Future<CaptureResult>` - Success with compatible image data or failure reason

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Legacy method works on all macOS versions
final windows = await toolkit.getCapturableWindowsLegacy();
if (windows.isEmpty) {
  print('No windows available for capture');
  return;
}

final result = await toolkit.captureWindowLegacy(windows.first.windowId);
switch (result) {
  case CaptureSuccess(:final imageData):
    print('Legacy capture successful: ${imageData.length} bytes');
    
    // Image format is always PNG
    final file = File('legacy_capture.png');
    await file.writeAsBytes(imageData);
    
  case CaptureFailure(:final reason):
    print('Legacy capture failed: ${reason.name}');
    print('User message: ${result.userMessage}');
    
    if (result.canRetry) {
      print('Suggested action: ${result.suggestedAction}');
    }
}
```

**Performance Characteristics:**
- Slower than ScreenCaptureKit but more compatible
- Works well for smaller windows
- May have performance issues with very large windows
- Always produces PNG format

---

### `getCapturableWindowsLegacy()`

Gets list of capturable windows using CGWindowListCopyWindowInfo.

**Signature:**
```dart
Future<List<CapturableWindowInfo>> getCapturableWindowsLegacy()
```

**Requirements:**
- macOS 10.5 or later

**Returns:**
- `Future<List<CapturableWindowInfo>>` - List with basic window information

**Notes:**
- `bundleIdentifier` field will be empty (not available in legacy API)
- Broader compatibility but less detailed information

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Legacy method always succeeds (doesn't throw exceptions)
final windows = await toolkit.getCapturableWindowsLegacy();

print('Legacy method found ${windows.length} windows:');
for (final window in windows) {
  print('Title: "${window.title}"');
  print('App: ${window.ownerName}');
  print('Bundle: ${window.bundleIdentifier}'); // Will be empty string
  print('Size: ${window.frame.width} × ${window.frame.height}');
}

// Use application name for filtering (instead of bundle ID)
final finderWindows = windows
    .where((w) => w.ownerName == 'Finder')
    .toList();
```

---

## System Information

### `getCaptureMethodInfo()`

Gets information about capture capabilities and methods on the current system.

**Signature:**
```dart
Future<Map<String, dynamic>> getCaptureMethodInfo()
```

**Returns:**
- `Future<Map<String, dynamic>>` - Detailed capability information

**Returned Information:**
- `captureMethod` - Method used by auto-selection ("ScreenCaptureKit" or "CGWindowListCreateImage")
- `windowListMethod` - Window listing method ("ScreenCaptureKit" or "CGWindowListCopyWindowInfo")
- `macOSVersion` - Current macOS version string
- `isScreenCaptureKitAvailable` - Whether ScreenCaptureKit is available (bool)
- `supportsModernCapture` - Whether modern capture is supported (bool)
- `supportsModernWindowList` - Whether modern window listing is supported (bool)

**Example:**
```dart
final toolkit = MacosWindowToolkit();
final info = await toolkit.getCaptureMethodInfo();

print('=== Capture Method Information ===');
print('Capture method: ${info['captureMethod']}');
print('Window list method: ${info['windowListMethod']}');
print('macOS version: ${info['macOSVersion']}');
print('ScreenCaptureKit available: ${info['isScreenCaptureKitAvailable']}');
print('Modern capture supported: ${info['supportsModernCapture']}');
print('Modern window list supported: ${info['supportsModernWindowList']}');

// Show user-friendly information
if (info['supportsModernCapture'] == true) {
  print('✅ Using high-quality ScreenCaptureKit capture');
} else {
  print('⚠️ Using compatible CGWindowListCreateImage capture');
  print('Consider updating to macOS 12.3+ for better quality');
}

// Use for feature detection
if (info['isScreenCaptureKitAvailable'] == true) {
  // Enable ScreenCaptureKit-specific features
  enableAdvancedCaptureFeatures();
} else {
  // Hide unsupported features
  hideModernCaptureOptions();
}
```

**Use Cases:**
- Debugging capture issues
- User feedback about system capabilities
- Feature detection for UI
- Performance optimization decisions

---

## Data Models

### CaptureResult (Sealed Class)

Represents the result of a capture operation using pattern matching.

#### `CaptureSuccess`

**Properties:**
- `imageData` (`Uint8List`) - PNG image data bytes

**Example:**
```dart
switch (result) {
  case CaptureSuccess(:final imageData):
    print('Success! ${imageData.length} bytes captured');
    
    // Save to file
    await File('capture.png').writeAsBytes(imageData);
    
    // Display in Flutter
    Widget buildImage() => Image.memory(imageData);
    
    // Get image info
    final codec = await ui.instantiateImageCodec(imageData);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    print('Image size: ${image.width} × ${image.height}');
}
```

#### `CaptureFailure`

**Properties:**
- `reason` (`CaptureFailureReason`) - Specific failure reason
- `message` (`String?`) - Optional detailed message
- `details` (`String?`) - Optional technical details

**Methods:**
- `userMessage` (`String`) - User-friendly failure message
- `canRetry` (`bool`) - Whether failure can be retried after user action
- `suggestedAction` (`String?`) - Suggested action to resolve failure

**Example:**
```dart
switch (result) {
  case CaptureFailure(:final reason, :final message):
    print('Capture failed: ${reason.name}');
    
    // User-friendly message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Capture Failed'),
        content: Text(result.userMessage),
        actions: [
          if (result.canRetry && result.suggestedAction != null) ...[
            TextButton(
              onPressed: () {
                // Show suggested action
                print('Suggested: ${result.suggestedAction}');
              },
              child: Text('Help'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
    
    // Handle specific reasons
    switch (reason) {
      case CaptureFailureReason.windowMinimized:
        // Guide user to restore window
        break;
      case CaptureFailureReason.permissionDenied:
        await toolkit.requestScreenRecordingPermission();
        break;
      case CaptureFailureReason.windowNotFound:
        // Refresh window list
        await refreshWindowList();
        break;
      // ... handle other reasons
    }
}
```

### CaptureFailureReason (Enum)

Specific reasons for capture failure (not system errors).

| Value | Description | Can Retry | Suggested Action |
|-------|-------------|-----------|------------------|
| `windowMinimized` | Window is minimized | ✅ | Restore window from dock |
| `windowNotFound` | Window no longer exists | ❌ | - |
| `unsupportedVersion` | macOS version not supported | ❌ | - |
| `permissionDenied` | Screen recording permission denied | ✅ | Grant permission in settings |
| `captureInProgress` | Another capture in progress | ✅ | Wait for completion |
| `windowNotCapturable` | Window cannot be captured | ❌ | - |
| `unknown` | Unknown capture state | ❌ | - |

### CapturableWindowInfo

Window information optimized for capture operations.

**Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `windowId` | `int` | Unique window identifier for capture |
| `title` | `String` | Window title/name |
| `ownerName` | `String` | Application name |
| `bundleIdentifier` | `String` | App bundle ID (empty in legacy method) |
| `frame` | `CapturableWindowFrame` | Position and size information |
| `isOnScreen` | `bool` | Whether window is visible |

**Constructor:**
```dart
const CapturableWindowInfo({
  required this.windowId,
  required this.title,
  required this.ownerName,
  required this.bundleIdentifier,
  required this.frame,
  required this.isOnScreen,
});
```

### CapturableWindowFrame

Position and size information for capturable windows.

**Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `x` | `double` | X coordinate (left edge) |
| `y` | `double` | Y coordinate (top edge) |
| `width` | `double` | Window width |
| `height` | `double` | Window height |

**Example Usage:**
```dart
final window = windows.first;
final frame = window.frame;

print('Window bounds: (${frame.x}, ${frame.y}, ${frame.width}, ${frame.height})');
print('Window area: ${frame.width * frame.height} square pixels');
print('Aspect ratio: ${(frame.width / frame.height).toStringAsFixed(2)}');

// Check if window is large enough for capture
if (frame.width >= 100 && frame.height >= 100) {
  // Proceed with capture
  final result = await toolkit.captureWindowAuto(window.windowId);
} else {
  print('Window too small for meaningful capture');
}
```

## Complete Usage Examples

### Basic Window Capture Application

```dart
class WindowCaptureApp extends StatefulWidget {
  @override
  _WindowCaptureAppState createState() => _WindowCaptureAppState();
}

class _WindowCaptureAppState extends State<WindowCaptureApp> {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  List<CapturableWindowInfo> windows = [];
  bool isLoading = false;
  Uint8List? capturedImage;
  
  @override
  void initState() {
    super.initState();
    _loadWindows();
  }
  
  Future<void> _loadWindows() async {
    setState(() => isLoading = true);
    
    try {
      // Check permissions first
      final hasPermission = await toolkit.hasScreenRecordingPermission();
      if (!hasPermission) {
        final granted = await toolkit.requestScreenRecordingPermission();
        if (!granted) {
          _showPermissionDialog();
          return;
        }
      }
      
      // Load capturable windows (recommended method)
      final loadedWindows = await toolkit.getCapturableWindowsAuto();
      
      setState(() {
        windows = loadedWindows
            .where((w) => w.isOnScreen) // Only visible windows
            .where((w) => w.title.isNotEmpty) // Only named windows
            .toList();
      });
      
    } catch (e) {
      _showError('Failed to load windows: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  Future<void> _captureWindow(CapturableWindowInfo window) async {
    setState(() => isLoading = true);
    
    try {
      // Use recommended auto-selection method
      final result = await toolkit.captureWindowAuto(
        window.windowId,
        excludeTitlebar: true, // Remove titlebar for cleaner capture
      );
      
      switch (result) {
        case CaptureSuccess(:final imageData):
          setState(() => capturedImage = imageData);
          
          // Optionally save to file
          final file = File('captures/window_${window.windowId}_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.create(recursive: true);
          await file.writeAsBytes(imageData);
          
          _showSuccess('Captured window: "${window.title}"');
          
        case CaptureFailure(:final reason):
          _showError('Capture failed: ${result.userMessage}');
          
          // Handle specific failures
          if (reason == CaptureFailureReason.windowMinimized) {
            _showRetryDialog(window, 'Please restore the window and try again');
          } else if (reason == CaptureFailureReason.permissionDenied) {
            _showPermissionDialog();
          }
      }
      
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Window Capture'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWindows,
          ),
        ],
      ),
      body: Row(
        children: [
          // Window list
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Capturable Windows (${windows.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: windows.length,
                          itemBuilder: (context, index) {
                            final window = windows[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(
                                  window.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(window.ownerName),
                                    Text(
                                      '${window.frame.width.round()} × ${window.frame.height.round()}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _captureWindow(window),
                                  child: Text('Capture'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Captured image display
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: capturedImage != null
                  ? Column(
                      children: [
                        Expanded(
                          child: Image.memory(
                            capturedImage!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Image size: ${capturedImage!.length} bytes',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                        'Select a window to capture',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
          'Screen recording permission is required to capture windows. '
          'Please grant permission in System Preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await toolkit.openScreenRecordingSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  void _showRetryDialog(CapturableWindowInfo window, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retry Capture'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _captureWindow(window);
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Batch Window Capture

```dart
class BatchCaptureService {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<Map<String, Uint8List>> captureAllWindows({
    bool visibleOnly = true,
    bool excludeTitlebar = true,
    String? filterByApp,
  }) async {
    final captures = <String, Uint8List>{};
    
    // Get windows to capture
    final windows = await toolkit.getCapturableWindowsAuto();
    var filteredWindows = windows;
    
    if (visibleOnly) {
      filteredWindows = filteredWindows.where((w) => w.isOnScreen).toList();
    }
    
    if (filterByApp != null) {
      filteredWindows = filteredWindows
          .where((w) => w.ownerName.toLowerCase().contains(filterByApp.toLowerCase()))
          .toList();
    }
    
    print('Capturing ${filteredWindows.length} windows...');
    
    for (final window in filteredWindows) {
      try {
        final result = await toolkit.captureWindowAuto(
          window.windowId,
          excludeTitlebar: excludeTitlebar,
        );
        
        switch (result) {
          case CaptureSuccess(:final imageData):
            final key = '${window.ownerName}_${window.windowId}';
            captures[key] = imageData;
            print('✅ Captured: ${window.title} (${imageData.length} bytes)');
            
          case CaptureFailure(:final reason):
            print('❌ Failed to capture "${window.title}": ${reason.name}');
        }
        
        // Small delay to avoid overwhelming the system
        await Future.delayed(Duration(milliseconds: 100));
        
      } catch (e) {
        print('❌ Error capturing "${window.title}": $e');
      }
    }
    
    print('Batch capture complete: ${captures.length}/${filteredWindows.length} successful');
    return captures;
  }
  
  Future<void> saveCapturesBatch(
    Map<String, Uint8List> captures,
    String directory,
  ) async {
    final dir = Directory(directory);
    await dir.create(recursive: true);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    for (final entry in captures.entries) {
      final filename = '${entry.key}_$timestamp.png';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(entry.value);
      print('Saved: ${file.path}');
    }
  }
}

// Usage
final batchCapture = BatchCaptureService();

// Capture all Chrome windows
final chromeCaptures = await batchCapture.captureAllWindows(
  filterByApp: 'Chrome',
  excludeTitlebar: true,
);

// Save all captures
await batchCapture.saveCapturesBatch(
  chromeCaptures,
  'captures/chrome_windows',
);
```

## Best Practices

### Method Selection

```dart
// ✅ Recommended: Use auto-selection methods
final windows = await toolkit.getCapturableWindowsAuto();
final result = await toolkit.captureWindowAuto(windowId);

// ❌ Not recommended: Manual version checking
final versionInfo = await toolkit.getMacOSVersionInfo();
if (versionInfo.isScreenCaptureKitAvailable) {
  final windows = await toolkit.getCapturableWindows();
} else {
  final windows = await toolkit.getCapturableWindowsLegacy();
}
```

### Error Handling

```dart
Future<Uint8List?> safeCaptureWindow(int windowId) async {
  try {
    // Check if window still exists
    final isAlive = await toolkit.isWindowAlive(windowId);
    if (!isAlive) {
      print('Window no longer exists');
      return null;
    }
    
    final result = await toolkit.captureWindowAuto(windowId);
    switch (result) {
      case CaptureSuccess(:final imageData):
        return imageData;
        
      case CaptureFailure(:final reason):
        print('Capture failed: ${reason.name}');
        
        // Retry for certain failures
        if (result.canRetry && reason == CaptureFailureReason.captureInProgress) {
          await Future.delayed(Duration(seconds: 1));
          return safeCaptureWindow(windowId); // Recursive retry
        }
        
        return null;
    }
  } catch (e) {
    print('Unexpected capture error: $e');
    return null;
  }
}
```

### Performance Optimization

```dart
class CaptureCache {
  final Map<int, CachedCapture> _cache = {};
  
  Future<Uint8List?> getCachedCapture(
    int windowId,
    Duration maxAge,
  ) async {
    final cached = _cache[windowId];
    if (cached != null && 
        DateTime.now().difference(cached.timestamp) < maxAge) {
      return cached.imageData;
    }
    
    // Capture new image
    final result = await toolkit.captureWindowAuto(windowId);
    switch (result) {
      case CaptureSuccess(:final imageData):
        _cache[windowId] = CachedCapture(imageData, DateTime.now());
        return imageData;
      case CaptureFailure():
        return null;
    }
  }
  
  void clearCache() => _cache.clear();
}

class CachedCapture {
  final Uint8List imageData;
  final DateTime timestamp;
  
  CachedCapture(this.imageData, this.timestamp);
}
```

## Performance Notes

### Capture Method Performance

| Method | macOS Version | Performance | Quality |
|--------|---------------|-------------|---------|
| ScreenCaptureKit | 12.3+ | ⚡ Fast | 🎯 High |
| CGWindowListCreateImage | 10.5+ | ⏳ Slower | ✅ Good |

### Window Size Impact

| Window Size | ScreenCaptureKit | Legacy Method |
|-------------|------------------|---------------|
| Small (< 500×300) | ~50ms | ~100ms |
| Medium (500×300 - 1920×1080) | ~100ms | ~300ms |
| Large (> 1920×1080) | ~200ms | ~500ms |

### Memory Usage

- PNG image data: ~3-4 bytes per pixel
- 1920×1080 window: ~8MB memory
- Consider processing images in chunks for large batches

## Thread Safety

All window capture methods are thread-safe and can be called from any isolate.

## Related APIs

- **[Window Management](window_management.md)** - Find windows to capture
- **[Permission Management](permission_management.md)** - Handle screen recording permissions
- **[System Information](system_info.md)** - Check capture method availability
- **[Error Handling](error_handling.md)** - Handle capture errors

---

[← Back to API Reference](../api_reference.md)