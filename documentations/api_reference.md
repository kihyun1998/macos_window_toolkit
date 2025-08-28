# API Reference

Complete API reference documentation for macOS Window Toolkit.

## Overview

macOS Window Toolkit provides comprehensive window management, permission handling, window capture, and process management functionality for macOS Flutter applications. This reference documentation is organized by functional areas for easy navigation.

## Quick Reference

### Main Class
- [`MacosWindowToolkit`](#macoswindowtoolkit) - Main toolkit class with all functionality

### Core Categories
- **[Window Management](api/window_management.md)** - Finding, listing, and managing windows
- **[Permission Management](api/permission_management.md)** - Handling macOS permissions and monitoring
- **[Window Capture](api/window_capture.md)** - Capturing window screenshots with ScreenCaptureKit
- **[Process Management](api/process_management.md)** - Managing application processes
- **[System Information](api/system_info.md)** - macOS version and capability detection
- **[Error Handling](api/error_handling.md)** - Exception codes and error management

## API Categories

### 🪟 [Window Management](api/window_management.md)
Retrieve and manage window information across the system.

**Key Methods:**
- `getAllWindows()` - Get all system windows
- `getWindowsByName()` - Filter windows by title
- `getWindowsByOwnerName()` - Filter windows by application
- `getWindowById()` - Get specific window
- `isWindowAlive()` - Check if window exists
- `closeWindow()` - Close window via AppleScript

**Data Models:**
- `MacosWindowInfo` - Complete window information with position, size, transparency, etc.

---

### 🔐 [Permission Management](api/permission_management.md)
Handle macOS permissions with real-time monitoring capabilities.

**Permission Checking:**
- `hasScreenRecordingPermission()` - Check screen recording permission
- `hasAccessibilityPermission()` - Check accessibility permission

**Permission Requests:**
- `requestScreenRecordingPermission()` - Request screen recording access
- `requestAccessibilityPermission()` - Request accessibility access
- `openScreenRecordingSettings()` - Open system settings
- `openAccessibilitySettings()` - Open accessibility settings

**Real-time Monitoring:**
- `startPermissionWatching()` - Start permission monitoring
- `permissionStream` - Stream of permission changes
- `stopPermissionWatching()` - Stop monitoring
- `isPermissionWatching` - Check monitoring status

**Data Models:**
- `PermissionStatus` - Current permission state with change detection

---

### 📸 [Window Capture](api/window_capture.md)
Capture window screenshots using modern ScreenCaptureKit and legacy methods.

**Modern Capture (ScreenCaptureKit):**
- `captureWindow()` - High-quality capture (macOS 12.3+)
- `getCapturableWindows()` - List capturable windows

**Legacy Capture (CGWindowListCreateImage):**
- `captureWindowLegacy()` - Compatible capture (all macOS versions)
- `getCapturableWindowsLegacy()` - Legacy window listing

**Auto-Selection:**
- `captureWindowAuto()` - **Recommended** - Automatically selects best method
- `getCapturableWindowsAuto()` - **Recommended** - Auto window listing
- `getCaptureMethodInfo()` - Get current capture method info

**Data Models:**
- `CaptureResult` - Capture success/failure with detailed reasons
- `CapturableWindowInfo` - ScreenCaptureKit-specific window information
- `CaptureFailureReason` - Specific failure reasons (not system errors)

---

### ⚙️ [Process Management](api/process_management.md)
Manage application processes and their relationships.

**Process Termination:**
- `terminateApplicationByPID()` - Terminate single process
- `terminateApplicationTree()` - Terminate process and all children

**Process Information:**
- `getChildProcesses()` - Get child process IDs

---

### 🖥️ [System Information](api/system_info.md)
Get macOS version and capability information.

**Version Information:**
- `getMacOSVersionInfo()` - Complete macOS version details
- `getCaptureMethodInfo()` - Current capture method capabilities

**Data Models:**
- `MacosVersionInfo` - macOS version with feature availability

---

### ❌ [Error Handling](api/error_handling.md)
Comprehensive error codes and exception handling patterns.

**Exception Types:**
- `PlatformException` - System-level errors with specific codes
- `CaptureFailure` - Capture-specific failure states (not exceptions)

**Common Error Codes:**
- `SCREEN_RECORDING_PERMISSION_DENIED`
- `ACCESSIBILITY_PERMISSION_DENIED`
- `WINDOW_NOT_FOUND`
- `UNSUPPORTED_MACOS_VERSION`
- And many more...

---

## MacosWindowToolkit

The main class providing all window management functionality. Create an instance to access all methods:

```dart
final toolkit = MacosWindowToolkit();
```

### Method Summary

| Category | Methods | Description |
|----------|---------|-------------|
| **Window Management** | 6 methods | Finding and managing windows |
| **Permission Management** | 10 methods/properties | Permission handling and monitoring |
| **Window Capture** | 6 methods | Screenshot capture functionality |
| **Process Management** | 3 methods | Process control and information |
| **System Information** | 2 methods | macOS version and capabilities |

**Total: 27 public methods and properties**

## Getting Started

### Basic Usage

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() async {
  final toolkit = MacosWindowToolkit();
  
  // Get all windows
  final windows = await toolkit.getAllWindows();
  print('Found ${windows.length} windows');
  
  // Check permissions
  final hasPermission = await toolkit.hasScreenRecordingPermission();
  if (!hasPermission) {
    await toolkit.requestScreenRecordingPermission();
  }
  
  // Capture a window (recommended method)
  if (windows.isNotEmpty) {
    final result = await toolkit.captureWindowAuto(windows.first.windowId);
    switch (result) {
      case CaptureSuccess(:final imageData):
        print('Captured ${imageData.length} bytes');
      case CaptureFailure(:final reason):
        print('Capture failed: ${reason.name}');
    }
  }
}
```

### Real-time Permission Monitoring

```dart
final toolkit = MacosWindowToolkit();

// Start monitoring
toolkit.startPermissionWatching();

// Listen for changes
toolkit.permissionStream.listen((status) {
  if (status.hasChanges) {
    print('Permissions changed!');
    print('Screen Recording: ${status.screenRecording}');
    print('Accessibility: ${status.accessibility}');
  }
});
```

## Platform Requirements

- **macOS**: 10.11 or later
- **Flutter**: 3.3.0 or later
- **Dart**: 3.8.1 or later

## Thread Safety

All methods are thread-safe and can be called from any isolate.

## Performance Notes

- Window enumeration: ~10-50ms for 20-100 windows
- Permission checks: ~1-5ms per check
- ScreenCaptureKit capture: ~50-200ms depending on window size
- Legacy capture: ~100-500ms depending on window size

---

## Navigation

- **[Window Management API →](api/window_management.md)**
- **[Permission Management API →](api/permission_management.md)**
- **[Window Capture API →](api/window_capture.md)**
- **[Process Management API →](api/process_management.md)**
- **[System Information API →](api/system_info.md)**
- **[Error Handling Guide →](api/error_handling.md)**

---

*For more detailed information about each API category, click on the links above or navigate to the specific documentation files.*