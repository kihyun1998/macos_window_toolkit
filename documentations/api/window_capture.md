# Window Capture API

Complete reference for window screenshot capture using ScreenCaptureKit.

## Overview

The Window Capture API captures window screenshots on macOS with ScreenCaptureKit. It can remove the titlebar, crop a region of the window and resize the result, and it lists the windows ScreenCaptureKit can capture.

ScreenCaptureKit is the only capture method. Capturing a window needs macOS 14.0 or later; listing capturable windows needs macOS 12.3 or later. Both need Screen Recording permission. On an older macOS, capture is unavailable and there is no other method to fall back to.

## Quick Reference

### Capture Methods
| Method | Description | Requirements | Returns |
|--------|-------------|--------------|---------|
| [`captureWindow()`](#capturewindow) | Captures a window as PNG data | macOS 14.0+, Screen Recording | `Future<CaptureResult>` |
| [`isWindowFullScreen()`](#iswindowfullscreen) | Checks whether a window is fullscreen | macOS 14.0+, Screen Recording | `Future<bool>` |

### Window Discovery
| Method | Description | Requirements | Returns |
|--------|-------------|--------------|---------|
| [`getCapturableWindows()`](#getcapturablewindows) | Lists the windows ScreenCaptureKit can capture | macOS 12.3+, Screen Recording | `Future<List<CapturableWindowInfo>>` |

### Availability Check
| Method | Description | Returns |
|--------|-------------|---------|
| [`getMacOSVersionInfo()`](#checking-availability) | macOS version, to check whether capture is available | `Future<MacosVersionInfo>` |

## ScreenCaptureKit Methods

### `captureWindow()`

Captures a window using ScreenCaptureKit.

**Signature:**
```dart
Future<CaptureResult> captureWindow(
  int windowId, {
  bool excludeTitlebar = false,
  double? customTitlebarHeight,
  int? targetWidth,
  int? targetHeight,
  bool preserveAspectRatio = false,
  int? cropContentWidth,
  int? cropContentHeight,
  int? cropX,
  int? cropY,
  int? cropWidth,
  int? cropHeight,
  bool resizeCroppedToWindowSize = true,
})
```

**Requirements:**
- macOS 14.0 or later
- Screen recording permission

**Parameters:**
- `windowId` - Unique window identifier, from `getCapturableWindows()`, `getAllWindows()` or `getWindowById()`
- `excludeTitlebar` (optional) - If `true`, removes the titlebar from the capture. Defaults to `false`. No titlebar is removed from a fullscreen window.
- `customTitlebarHeight` (optional) - Titlebar height to remove, in points. Uses the 28pt default if null. Must be non-negative and not larger than the window height.
- `targetWidth` (optional) - Width of the output image. If specified with `targetHeight`, the image is resized.
- `targetHeight` (optional) - Height of the output image. If specified with `targetWidth`, the image is resized.
- `preserveAspectRatio` (optional) - If `true`, keeps the aspect ratio and fills the remaining area with black. If `false`, resizes to the exact dimensions. Defaults to `false`.
- `cropContentWidth`, `cropContentHeight` (optional) - Crop a region of this size from the center of the image. Takes precedence over the rectangle crop.
- `cropX`, `cropY`, `cropWidth`, `cropHeight` (optional) - Crop this rectangle from the image.
- `resizeCroppedToWindowSize` (optional) - Transparent borders are always cropped from the capture. If `true`, the image is resized back to the window size afterwards. Defaults to `true`.

Crop values are clamped to the image. Size and crop values are not validated: zero or negative values make the capture fail.

**Output:**
- PNG image data
- The image size is the window frame in points; no display scale factor is applied
- Processing order: titlebar removal, transparent border crop, custom crop, resize

**Returns:**
- `Future<CaptureResult>` - Success with image data, or failure with a reason

**Throws:**
- `PlatformException` only for system errors (invalid arguments, system failures)

**Example:**
```dart
final toolkit = MacosWindowToolkit();

final windows = await toolkit.getCapturableWindows();
if (windows.isEmpty) {
  print('No capturable windows found');
  return;
}

final window = windows.first;
final result = await toolkit.captureWindow(window.windowId);

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
      case CaptureFailureReason.unsupportedVersion:
        print('Window capture requires macOS 14.0 or later');
        break;
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

**Titlebar Removal:**
```dart
// Capture without titlebar (standard height)
final result = await toolkit.captureWindow(
  windowId,
  excludeTitlebar: true,
);

// Capture with custom titlebar height
final result = await toolkit.captureWindow(
  windowId,
  excludeTitlebar: true,
  customTitlebarHeight: 32.0, // Larger titlebar
);
```

**Resizing:**
```dart
// Resize to specific dimensions (may distort)
final result = await toolkit.captureWindow(
  windowId,
  targetWidth: 1920,
  targetHeight: 1080,
);

// Resize maintaining aspect ratio with letterboxing
final result = await toolkit.captureWindow(
  windowId,
  targetWidth: 1920,
  targetHeight: 1080,
  preserveAspectRatio: true, // Black bars added to maintain aspect ratio
);

// Create thumbnail
final thumbnail = await toolkit.captureWindow(
  windowId,
  targetWidth: 200,
  targetHeight: 150,
  preserveAspectRatio: true,
);

// Combine with titlebar removal
final resized = await toolkit.captureWindow(
  windowId,
  excludeTitlebar: true,
  targetWidth: 800,
  targetHeight: 600,
  preserveAspectRatio: true,
);
```

**Cropping:**
```dart
// Crop a 600 × 400 region from the center
final centered = await toolkit.captureWindow(
  windowId,
  cropContentWidth: 600,
  cropContentHeight: 400,
);

// Crop a rectangle starting at (100, 50)
final region = await toolkit.captureWindow(
  windowId,
  cropX: 100,
  cropY: 50,
  cropWidth: 400,
  cropHeight: 300,
);

// Keep the size left after cropping transparent borders
final trimmed = await toolkit.captureWindow(
  windowId,
  resizeCroppedToWindowSize: false,
);
```

---

### `getCapturableWindows()`

Gets the list of windows that ScreenCaptureKit can capture.

**Signature:**
```dart
Future<List<CapturableWindowInfo>> getCapturableWindows()
```

**Requirements:**
- macOS 12.3 or later
- Screen recording permission

**Returns:**
- `Future<List<CapturableWindowInfo>>` - List with window information including bundle identifiers. Windows with an empty title are left out.

**Throws:**
- `PlatformException` with error codes:
  - `UNSUPPORTED_MACOS_VERSION` - macOS version doesn't support ScreenCaptureKit
  - `SCREEN_RECORDING_PERMISSION_DENIED` - Screen recording permission is not granted
  - `CAPTURE_FAILED` - Failed to retrieve windows

**Example:**
```dart
final toolkit = MacosWindowToolkit();

try {
  final windows = await toolkit.getCapturableWindows();

  print('Found ${windows.length} capturable windows:');
  for (final window in windows) {
    print('');
    print('Title: "${window.title}"');
    print('App: ${window.ownerName}');
    print('Bundle: ${window.bundleIdentifier}');
    print('Size: ${window.frame.width} × ${window.frame.height}');
    print('Position: (${window.frame.x}, ${window.frame.y})');
    print('Visible: ${window.isOnScreen}');
    print('Window ID: ${window.windowId}');
  }

  // Use bundle identifier for precise filtering
  final chromeWindows = windows
      .where((w) => w.bundleIdentifier == 'com.google.Chrome')
      .toList();
  print('\nFound ${chromeWindows.length} Chrome windows');

} on PlatformException catch (e) {
  switch (e.code) {
    case 'UNSUPPORTED_MACOS_VERSION':
      print('Listing capturable windows requires macOS 12.3+');
      break;

    case 'SCREEN_RECORDING_PERMISSION_DENIED':
      print('Screen recording permission required');
      break;

    default:
      print('Error: ${e.message}');
  }
}
```

**Filtering Examples:**
```dart
final windows = await toolkit.getCapturableWindows();

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

### `isWindowFullScreen()`

Checks whether a window is in fullscreen mode, using the window's current frame from ScreenCaptureKit. This also works for windows on other Spaces.

**Signature:**
```dart
Future<bool> isWindowFullScreen(int windowId)
```

**Requirements:**
- macOS 14.0 or later
- Screen recording permission

**Returns:**
- `Future<bool>` - `true` if the window is fullscreen, `false` otherwise

**Throws:**
- `PlatformException` with error codes:
  - `SCREEN_RECORDING_PERMISSION_DENIED` - Screen recording permission is not granted
  - `INVALID_WINDOW_ID` - No window with this ID
  - `UNSUPPORTED_MACOS_VERSION` / `REQUIRES_MACOS_14` - macOS version is too old
  - `FULLSCREEN_CHECK_FAILED` - Any other failure

**Example:**
```dart
final toolkit = MacosWindowToolkit();

try {
  final isFullScreen = await toolkit.isWindowFullScreen(windowId);
  if (isFullScreen) {
    print('Window is in fullscreen mode');
  }
} on PlatformException catch (e) {
  print('Fullscreen check failed: ${e.code}');
}
```

---

## Checking Availability

Use `getMacOSVersionInfo()` to decide whether to offer capture at all. `isScreenCaptureKitAvailable` is `true` on macOS 12.3+, which is enough for `getCapturableWindows()`; `captureWindow()` needs macOS 14.0. You can also call `captureWindow()` directly and handle `CaptureFailureReason.unsupportedVersion`.

**Example:**
```dart
final toolkit = MacosWindowToolkit();
final versionInfo = await toolkit.getMacOSVersionInfo();

print('macOS version: ${versionInfo.versionString}');
print('ScreenCaptureKit available: ${versionInfo.isScreenCaptureKitAvailable}');

final canCapture = versionInfo.majorVersion >= 14;

if (canCapture) {
  // Enable capture features
  enableCaptureFeatures();
} else {
  // Hide unsupported features
  hideCaptureOptions();
}
```

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
- `errorCode` (`int?`) - Native `NSError` code, when there is one
- `errorDomain` (`String?`) - Native `NSError` domain, when there is one

**Getters:**
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
      case CaptureFailureReason.unsupportedVersion:
        // Capture requires macOS 14.0+; hide capture features
        break;
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
| `windowNotFound` | Window no longer exists, or ScreenCaptureKit does not list it | ❌ | - |
| `unsupportedVersion` | macOS is older than 14.0 | ❌ | - |
| `permissionDenied` | Screen recording permission denied | ✅ | Grant permission in settings |
| `captureInProgress` | Another capture in progress (not currently produced) | ✅ | Wait for completion |
| `windowNotCapturable` | Window cannot be captured (not currently produced) | ❌ | - |
| `unknown` | Unknown capture state | ❌ | - |

`captureInProgress` and `windowNotCapturable` exist in the enum, but the native side does not return them at present.

### CapturableWindowInfo

Window information optimized for capture operations.

**Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `windowId` | `int` | Unique window identifier for capture |
| `title` | `String` | Window title/name |
| `ownerName` | `String` | Application name |
| `bundleIdentifier` | `String` | App bundle ID |
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
print('Window area: ${frame.width * frame.height} square points');
print('Aspect ratio: ${(frame.width / frame.height).toStringAsFixed(2)}');

// Check if window is large enough for capture
if (frame.width >= 100 && frame.height >= 100) {
  // Proceed with capture
  final result = await toolkit.captureWindow(window.windowId);
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
      
      // Load capturable windows
      final loadedWindows = await toolkit.getCapturableWindows();
      
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
      final result = await toolkit.captureWindow(
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
          // Handle specific failures
          if (reason == CaptureFailureReason.unsupportedVersion) {
            _showError('Window capture requires macOS 14.0 or later');
          } else if (reason == CaptureFailureReason.windowMinimized) {
            _showRetryDialog(window, 'Please restore the window and try again');
          } else if (reason == CaptureFailureReason.permissionDenied) {
            _showPermissionDialog();
          } else {
            _showError('Capture failed: ${result.userMessage}');
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
    final windows = await toolkit.getCapturableWindows();
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
        final result = await toolkit.captureWindow(
          window.windowId,
          excludeTitlebar: excludeTitlebar,
        );
        
        switch (result) {
          case CaptureSuccess(:final imageData):
            final key = '${window.ownerName}_${window.windowId}';
            captures[key] = imageData;
            print('✅ Captured: ${window.title} (${imageData.length} bytes)');
            
          case CaptureFailure(reason: CaptureFailureReason.unsupportedVersion):
            print('❌ Window capture requires macOS 14.0 or later');
            return captures;

          case CaptureFailure(reason: CaptureFailureReason.permissionDenied):
            print('❌ Screen recording permission required');
            return captures;

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
    
    final result = await toolkit.captureWindow(windowId);
    switch (result) {
      case CaptureSuccess(:final imageData):
        return imageData;
        
      case CaptureFailure(reason: CaptureFailureReason.unsupportedVersion):
        // No other capture method exists below macOS 14.0
        print('Window capture requires macOS 14.0 or later');
        return null;

      case CaptureFailure(:final reason):
        print('Capture failed: ${reason.name}');

        // Failures the user can resolve
        if (result.canRetry && result.suggestedAction != null) {
          print('Suggested action: ${result.suggestedAction}');
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
    final result = await toolkit.captureWindow(windowId);
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

### Memory Usage

- PNG image data: ~3-4 bytes per pixel
- 1920×1080 window: ~8MB memory
- Consider processing images in chunks for large batches

## Thread Safety

All window capture methods are thread-safe and can be called from any isolate.

## Related APIs

- **[Window Management](window_management.md)** - Find windows to capture
- **[Permission Management](permission_management.md)** - Handle screen recording permissions
- **[System Information](system_info.md)** - Check the macOS version for capture availability
- **[Error Handling](error_handling.md)** - Handle capture errors

---

[← Back to API Reference](../api_reference.md)