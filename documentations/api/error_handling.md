# Error Handling Guide

Complete reference for exception codes, error patterns, and troubleshooting in macOS Window Toolkit.

## Overview

macOS Window Toolkit uses a comprehensive error handling system that distinguishes between system-level exceptions (`PlatformException`) and application-level failure states (like `CaptureFailure`). Understanding these patterns is crucial for building robust applications that gracefully handle various error conditions.

## Error Types

### System-Level Exceptions (`PlatformException`)

Thrown when system-level operations fail or are not permitted.

### Application-Level Failures

Represented as sealed classes or enums for specific failure scenarios (e.g., `CaptureFailure`).

## Exception Codes Reference

### Window Management Errors

| Code | Description | Cause | Resolution |
|------|-------------|-------|------------|
| `SYSTEM_ERROR` | General system error | System resource issues, API failures | Retry operation, check system resources |
| `PERMISSION_DENIED` | Insufficient permissions | Missing screen recording/accessibility permissions | Request permissions via settings |
| `UNKNOWN_ERROR` | Unexpected error | Internal plugin error, API changes | Report bug, check for updates |

### Permission Management Errors

| Code | Description | Cause | Resolution |
|------|-------------|-------|------------|
| `SCREEN_RECORDING_PERMISSION_DENIED` | Screen recording permission not granted | User denied permission or not yet granted | Guide user to System Preferences |
| `ACCESSIBILITY_PERMISSION_DENIED` | Accessibility permission not granted | User denied permission or not yet granted | Guide user to System Preferences |

### Window Capture Errors

| Code | Description | Cause | Resolution |
|------|-------------|-------|------------|
| `REQUIRES_MACOS_14` | Operation requires macOS 14.0+ | Capture method not supported on current macOS | Use legacy methods or inform user |
| `WINDOW_MINIMIZED` | Window is minimized and cannot be captured | Target window is minimized to dock | Ask user to restore window |
| `UNSUPPORTED_MACOS_VERSION` | macOS version doesn't support requested operation | ScreenCaptureKit not available | Use legacy methods |
| `SCREENCAPTUREKIT_NOT_AVAILABLE` | ScreenCaptureKit framework not available | System limitation or restriction | Fall back to legacy capture |
| `CAPTURE_FAILED` | General capture operation failed | System restriction, window unavailable | Check window status, retry |

### Process Management Errors

| Code | Description | Cause | Resolution |
|------|-------------|-------|------------|
| `TERMINATE_APP_ERROR` | Application termination failed | Process protection, system restriction | Try force termination or manual intervention |
| `PROCESS_NOT_FOUND` | Process with specified ID doesn't exist | Process already terminated or invalid PID | Check process exists before operation |
| `TERMINATION_FAILED` | System call to terminate process failed | Insufficient privileges, system protection | Check process permissions |
| `TERMINATE_TREE_ERROR` | Process tree termination failed | Some child processes couldn't be terminated | Try individual termination |
| `FAILED_TO_GET_PROCESS_LIST` | Unable to retrieve system process list | System restriction, resource limitation | Check system permissions |
| `GET_CHILD_PROCESSES_ERROR` | Failed to retrieve child processes | Process access restriction | Skip inaccessible processes |

### Window Operations Errors

| Code | Description | Cause | Resolution |
|------|-------------|-------|------------|
| `CLOSE_WINDOW_ERROR` | Window closing operation failed | AppleScript failure, application doesn't support | Try alternative methods |
| `WINDOW_NOT_FOUND` | Specified window not found | Window closed, invalid window ID | Refresh window list |
| `INSUFFICIENT_WINDOW_INFO` | Not enough information to perform operation | Missing window properties | Use different window source |
| `APPLESCRIPT_EXECUTION_FAILED` | AppleScript execution failed | Script error, application incompatibility | Check application AppleScript support |

## Error Handling Patterns

### Basic Exception Handling

```dart
try {
  final windows = await toolkit.getAllWindows();
  // Process windows
} on PlatformException catch (e) {
  switch (e.code) {
    case 'SCREEN_RECORDING_PERMISSION_DENIED':
      await _handlePermissionDenied();
      break;
    case 'SYSTEM_ERROR':
      await _handleSystemError(e.message);
      break;
    default:
      await _handleUnknownError(e);
  }
} catch (e) {
  // Handle unexpected errors
  print('Unexpected error: $e');
}
```

### Permission-Specific Error Handling

```dart
Future<List<MacosWindowInfo>> getWindowsSafely() async {
  try {
    return await toolkit.getAllWindows();
  } on PlatformException catch (e) {
    switch (e.code) {
      case 'SCREEN_RECORDING_PERMISSION_DENIED':
        print('Screen recording permission required');
        
        // Guide user to grant permission
        final granted = await toolkit.requestScreenRecordingPermission();
        if (!granted) {
          await toolkit.openScreenRecordingSettings();
        }
        
        // Return empty list for now
        return <MacosWindowInfo>[];
        
      case 'ACCESSIBILITY_PERMISSION_DENIED':
        print('Accessibility permission required for full functionality');
        await toolkit.requestAccessibilityPermission();
        
        // Try again with limited functionality
        try {
          return await toolkit.getAllWindows();
        } catch (_) {
          return <MacosWindowInfo>[];
        }
        
      default:
        print('Window retrieval failed: ${e.code} - ${e.message}');
        return <MacosWindowInfo>[];
    }
  }
}
```

### Capture-Specific Error Handling

```dart
Future<Uint8List?> captureWindowSafely(int windowId) async {
  try {
    final result = await toolkit.captureWindowAuto(windowId);
    
    switch (result) {
      case CaptureSuccess(:final imageData):
        return imageData;
        
      case CaptureFailure(:final reason):
        return await _handleCaptureFailure(windowId, reason, result);
    }
  } on PlatformException catch (e) {
    return await _handleCaptureException(windowId, e);
  }
}

Future<Uint8List?> _handleCaptureFailure(
  int windowId,
  CaptureFailureReason reason,
  CaptureFailure failure,
) async {
  switch (reason) {
    case CaptureFailureReason.windowMinimized:
      print('Window is minimized: ${failure.userMessage}');
      if (failure.canRetry) {
        print('Suggested action: ${failure.suggestedAction}');
        // Could show dialog asking user to restore window
      }
      return null;
      
    case CaptureFailureReason.permissionDenied:
      print('Permission denied for capture');
      await toolkit.requestScreenRecordingPermission();
      return null;
      
    case CaptureFailureReason.windowNotFound:
      print('Window no longer exists');
      return null;
      
    case CaptureFailureReason.captureInProgress:
      print('Another capture in progress, waiting...');
      await Future.delayed(Duration(seconds: 1));
      
      // Retry once
      try {
        final retryResult = await toolkit.captureWindowAuto(windowId);
        if (retryResult is CaptureSuccess) {
          return retryResult.imageData;
        }
      } catch (_) {
        // Ignore retry failure
      }
      return null;
      
    default:
      print('Capture failed: ${failure.userMessage}');
      return null;
  }
}

Future<Uint8List?> _handleCaptureException(
  int windowId,
  PlatformException e,
) async {
  switch (e.code) {
    case 'UNSUPPORTED_MACOS_VERSION':
      print('ScreenCaptureKit not supported, trying legacy method...');
      try {
        final result = await toolkit.captureWindowLegacy(windowId);
        if (result is CaptureSuccess) {
          return result.imageData;
        }
      } catch (_) {
        print('Legacy capture also failed');
      }
      return null;
      
    case 'WINDOW_NOT_FOUND':
      print('Window not found for capture');
      return null;
      
    default:
      print('Capture system error: ${e.code} - ${e.message}');
      return null;
  }
}
```

### Process Management Error Handling

```dart
Future<bool> terminateProcessSafely(int processId) async {
  try {
    // Try graceful termination first
    bool success = await toolkit.terminateApplicationByPID(processId);
    if (success) {
      return true;
    }
    
    // Try force termination if graceful failed
    return await toolkit.terminateApplicationByPID(processId, force: true);
    
  } on PlatformException catch (e) {
    switch (e.code) {
      case 'PROCESS_NOT_FOUND':
        print('Process $processId no longer exists');
        return true; // Consider it successful if already gone
        
      case 'TERMINATION_FAILED':
        print('Unable to terminate process $processId: ${e.message}');
        
        // Could try alternative methods
        return await _tryAlternativeTermination(processId);
        
      case 'TERMINATE_APP_ERROR':
        print('Application termination error: ${e.message}');
        return false;
        
      default:
        print('Unexpected termination error: ${e.code} - ${e.message}');
        return false;
    }
  }
}

Future<bool> _tryAlternativeTermination(int processId) async {
  // Alternative: Try terminating entire process tree
  try {
    return await toolkit.terminateApplicationTree(processId, force: true);
  } catch (e) {
    print('Alternative termination also failed: $e');
    return false;
  }
}
```

## Comprehensive Error Handler

```dart
class ErrorHandler {
  static Future<T?> handleOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    T? fallbackValue,
    bool retryOnSystemError = true,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation();
        
      } on PlatformException catch (e) {
        attempts++;
        print('[$operationName] Attempt $attempts failed: ${e.code}');
        
        final handled = await _handlePlatformException(e, operationName);
        
        if (handled.shouldRetry && attempts <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempts));
          continue;
        }
        
        if (handled.hasFallback) {
          return handled.fallbackValue as T?;
        }
        
        print('[$operationName] All attempts exhausted');
        return fallbackValue;
        
      } catch (e) {
        print('[$operationName] Unexpected error: $e');
        return fallbackValue;
      }
    }
    
    return fallbackValue;
  }
  
  static Future<ErrorHandlingResult> _handlePlatformException(
    PlatformException e,
    String operationName,
  ) async {
    switch (e.code) {
      // Permission errors - guide user to fix
      case 'SCREEN_RECORDING_PERMISSION_DENIED':
        await _handleScreenRecordingPermission();
        return ErrorHandlingResult(shouldRetry: false);
        
      case 'ACCESSIBILITY_PERMISSION_DENIED':
        await _handleAccessibilityPermission();
        return ErrorHandlingResult(shouldRetry: false);
        
      // System errors - can retry
      case 'SYSTEM_ERROR':
      case 'CAPTURE_FAILED':
        return ErrorHandlingResult(shouldRetry: true);
        
      // Resource not found - don't retry
      case 'WINDOW_NOT_FOUND':
      case 'PROCESS_NOT_FOUND':
        return ErrorHandlingResult(shouldRetry: false);
        
      // Version incompatibility - try fallback
      case 'UNSUPPORTED_MACOS_VERSION':
      case 'REQUIRES_MACOS_14':
        return await _handleVersionIncompatibility(operationName);
        
      // Temporary states - can retry
      case 'WINDOW_MINIMIZED':
      case 'CAPTURE_IN_PROGRESS':
        return ErrorHandlingResult(shouldRetry: true);
        
      default:
        print('Unhandled error code: ${e.code}');
        return ErrorHandlingResult(shouldRetry: false);
    }
  }
  
  static Future<void> _handleScreenRecordingPermission() async {
    print('🔐 Screen recording permission required');
    print('   Opening System Preferences...');
    
    final toolkit = MacosWindowToolkit();
    await toolkit.openScreenRecordingSettings();
    
    // Could show user dialog here
  }
  
  static Future<void> _handleAccessibilityPermission() async {
    print('🔐 Accessibility permission required');
    print('   Opening System Preferences...');
    
    final toolkit = MacosWindowToolkit();
    await toolkit.openAccessibilitySettings();
    
    // Could show user dialog here
  }
  
  static Future<ErrorHandlingResult> _handleVersionIncompatibility(
    String operationName,
  ) async {
    print('⚠️ Operation $operationName not supported on this macOS version');
    
    // Could attempt fallback methods
    if (operationName.contains('capture')) {
      print('   Attempting legacy capture methods...');
      // Return indication that fallback should be tried
      return ErrorHandlingResult(
        shouldRetry: false,
        hasFallback: true,
        fallbackValue: 'legacy',
      );
    }
    
    return ErrorHandlingResult(shouldRetry: false);
  }
}

class ErrorHandlingResult {
  final bool shouldRetry;
  final bool hasFallback;
  final dynamic fallbackValue;
  
  ErrorHandlingResult({
    required this.shouldRetry,
    this.hasFallback = false,
    this.fallbackValue,
  });
}
```

## Usage Examples

### Safe Window Management

```dart
class SafeWindowManager {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<List<MacosWindowInfo>> getWindows() async {
    return await ErrorHandler.handleOperation(
      'getAllWindows',
      () => toolkit.getAllWindows(),
      fallbackValue: <MacosWindowInfo>[],
    ) ?? <MacosWindowInfo>[];
  }
  
  Future<bool> closeWindow(int windowId) async {
    try {
      return await toolkit.closeWindow(windowId);
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'WINDOW_NOT_FOUND':
          print('Window already closed');
          return true; // Consider success
          
        case 'APPLESCRIPT_EXECUTION_FAILED':
          print('AppleScript failed, window may not support closing');
          return false;
          
        case 'ACCESSIBILITY_PERMISSION_DENIED':
          print('Need accessibility permission for window closing');
          await toolkit.requestAccessibilityPermission();
          return false;
          
        default:
          print('Failed to close window: ${e.code} - ${e.message}');
          return false;
      }
    }
  }
}
```

### Robust Capture System

```dart
class RobustCaptureSystem {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<CaptureAttemptResult> captureWithFallback(int windowId) async {
    // Try auto-selection method first
    try {
      final result = await toolkit.captureWindowAuto(windowId);
      switch (result) {
        case CaptureSuccess(:final imageData):
          return CaptureAttemptResult.success(imageData, 'auto');
          
        case CaptureFailure(:final reason):
          return await _handleCaptureFailure(windowId, reason);
      }
    } on PlatformException catch (e) {
      return await _handleCaptureException(windowId, e);
    }
  }
  
  Future<CaptureAttemptResult> _handleCaptureFailure(
    int windowId,
    CaptureFailureReason reason,
  ) async {
    switch (reason) {
      case CaptureFailureReason.windowMinimized:
        return CaptureAttemptResult.failure(
          'Window is minimized. Please restore the window.',
          canRetry: true,
        );
        
      case CaptureFailureReason.permissionDenied:
        // Try to fix permission issue
        await toolkit.requestScreenRecordingPermission();
        return CaptureAttemptResult.failure(
          'Screen recording permission required.',
          canRetry: true,
        );
        
      case CaptureFailureReason.windowNotFound:
        return CaptureAttemptResult.failure(
          'Window no longer exists.',
          canRetry: false,
        );
        
      case CaptureFailureReason.unsupportedVersion:
        // Try legacy method
        try {
          final result = await toolkit.captureWindowLegacy(windowId);
          if (result is CaptureSuccess) {
            return CaptureAttemptResult.success(result.imageData, 'legacy');
          }
        } catch (_) {
          // Legacy also failed
        }
        
        return CaptureAttemptResult.failure(
          'Capture not supported on this macOS version.',
          canRetry: false,
        );
        
      default:
        return CaptureAttemptResult.failure(
          'Capture failed: ${reason.name}',
          canRetry: false,
        );
    }
  }
  
  Future<CaptureAttemptResult> _handleCaptureException(
    int windowId,
    PlatformException e,
  ) async {
    switch (e.code) {
      case 'UNSUPPORTED_MACOS_VERSION':
        return await _tryLegacyCapture(windowId);
        
      case 'SCREENCAPTUREKIT_NOT_AVAILABLE':
        return await _tryLegacyCapture(windowId);
        
      default:
        return CaptureAttemptResult.failure(
          'System error: ${e.message}',
          canRetry: true,
        );
    }
  }
  
  Future<CaptureAttemptResult> _tryLegacyCapture(int windowId) async {
    try {
      final result = await toolkit.captureWindowLegacy(windowId);
      if (result is CaptureSuccess) {
        return CaptureAttemptResult.success(result.imageData, 'legacy');
      } else {
        return CaptureAttemptResult.failure(
          'Legacy capture also failed.',
          canRetry: false,
        );
      }
    } catch (e) {
      return CaptureAttemptResult.failure(
        'All capture methods failed.',
        canRetry: false,
      );
    }
  }
}

class CaptureAttemptResult {
  final bool isSuccess;
  final Uint8List? imageData;
  final String? method;
  final String? errorMessage;
  final bool canRetry;
  
  CaptureAttemptResult._({
    required this.isSuccess,
    this.imageData,
    this.method,
    this.errorMessage,
    this.canRetry = false,
  });
  
  factory CaptureAttemptResult.success(Uint8List imageData, String method) {
    return CaptureAttemptResult._(
      isSuccess: true,
      imageData: imageData,
      method: method,
    );
  }
  
  factory CaptureAttemptResult.failure(String error, {bool canRetry = false}) {
    return CaptureAttemptResult._(
      isSuccess: false,
      errorMessage: error,
      canRetry: canRetry,
    );
  }
}
```

## User-Friendly Error Messages

```dart
class UserErrorMessages {
  static String getHumanReadableError(PlatformException e) {
    switch (e.code) {
      case 'SCREEN_RECORDING_PERMISSION_DENIED':
        return 'This app needs screen recording permission to access window information. '
               'You can grant this in System Preferences > Privacy & Security > Screen Recording.';
      
      case 'ACCESSIBILITY_PERMISSION_DENIED':
        return 'This app needs accessibility permission to control windows. '
               'You can grant this in System Preferences > Privacy & Security > Accessibility.';
      
      case 'WINDOW_MINIMIZED':
        return 'The selected window is minimized. Please restore it from the Dock and try again.';
      
      case 'WINDOW_NOT_FOUND':
        return 'The window you\'re trying to access has been closed or is no longer available.';
      
      case 'PROCESS_NOT_FOUND':
        return 'The application you\'re trying to control is no longer running.';
      
      case 'UNSUPPORTED_MACOS_VERSION':
        return 'This feature requires a newer version of macOS. Please update your system for the best experience.';
      
      case 'REQUIRES_MACOS_14':
        return 'This advanced feature requires macOS 14.0 or later.';
      
      case 'APPLESCRIPT_EXECUTION_FAILED':
        return 'Unable to control this window. The application may not support this operation.';
      
      case 'TERMINATION_FAILED':
        return 'Unable to close the application. It may be protected by the system or require administrator privileges.';
      
      case 'SYSTEM_ERROR':
        return 'A system error occurred. Please try again, or restart the application if the problem persists.';
      
      default:
        return 'An unexpected error occurred: ${e.message ?? e.code}';
    }
  }
  
  static String getSuggestion(String errorCode) {
    switch (errorCode) {
      case 'SCREEN_RECORDING_PERMISSION_DENIED':
        return 'Open System Preferences and enable screen recording for this app';
      
      case 'ACCESSIBILITY_PERMISSION_DENIED':
        return 'Open System Preferences and enable accessibility for this app';
      
      case 'WINDOW_MINIMIZED':
        return 'Restore the window from the Dock or use Cmd+Tab';
      
      case 'UNSUPPORTED_MACOS_VERSION':
        return 'Update to macOS 12.3+ for enhanced features';
      
      case 'APPLESCRIPT_EXECUTION_FAILED':
        return 'Try using the application\'s own close button';
      
      default:
        return 'Try the operation again or restart the app';
    }
  }
}
```

## Error Logging and Debugging

```dart
class ErrorLogger {
  static void logError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    
    print('=== ERROR LOG ===');
    print('Time: $timestamp');
    print('Operation: $operation');
    
    if (error is PlatformException) {
      print('Type: PlatformException');
      print('Code: ${error.code}');
      print('Message: ${error.message}');
      print('Details: ${error.details}');
    } else {
      print('Type: ${error.runtimeType}');
      print('Error: $error');
    }
    
    if (context != null) {
      print('Context:');
      context.forEach((key, value) {
        print('  $key: $value');
      });
    }
    
    if (stackTrace != null) {
      print('Stack trace:');
      print(stackTrace.toString());
    }
    
    print('================');
  }
  
  static Future<void> logSystemInfo() async {
    try {
      final toolkit = MacosWindowToolkit();
      final versionInfo = await toolkit.getMacOSVersionInfo();
      final captureInfo = await toolkit.getCaptureMethodInfo();
      
      print('=== SYSTEM INFO ===');
      print('macOS: ${versionInfo.versionString}');
      print('ScreenCaptureKit: ${versionInfo.isScreenCaptureKitAvailable}');
      print('Capture method: ${captureInfo['captureMethod']}');
      print('Window list method: ${captureInfo['windowListMethod']}');
      print('==================');
    } catch (e) {
      print('Failed to log system info: $e');
    }
  }
}

// Usage in error handling
try {
  final windows = await toolkit.getAllWindows();
} catch (e, stackTrace) {
  ErrorLogger.logError(
    'getAllWindows',
    e,
    stackTrace: stackTrace,
    context: {
      'windowCount': 'unknown',
      'permissionGranted': 'unknown',
    },
  );
  
  // Continue with error handling...
}
```

## Testing Error Conditions

```dart
class ErrorConditionTester {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<void> testAllErrorConditions() async {
    print('🧪 Testing error conditions...');
    
    await _testPermissionErrors();
    await _testWindowErrors();
    await _testCaptureErrors();
    await _testProcessErrors();
  }
  
  Future<void> _testPermissionErrors() async {
    print('\n📋 Testing permission errors...');
    
    // This will likely fail if permissions not granted
    try {
      final windows = await toolkit.getAllWindows();
      print('✅ getAllWindows succeeded (${windows.length} windows)');
    } on PlatformException catch (e) {
      print('❌ getAllWindows failed: ${e.code}');
    }
  }
  
  Future<void> _testWindowErrors() async {
    print('\n🪟 Testing window errors...');
    
    // Test with invalid window ID
    try {
      final windows = await toolkit.getWindowById(-1);
      print('✅ Invalid window ID handled gracefully (${windows.length} results)');
    } catch (e) {
      print('❌ Invalid window ID caused error: $e');
    }
    
    // Test window close on non-existent window
    try {
      final success = await toolkit.closeWindow(999999);
      print('✅ Close non-existent window: $success');
    } on PlatformException catch (e) {
      print('❌ Close non-existent window error: ${e.code}');
    }
  }
  
  Future<void> _testCaptureErrors() async {
    print('\n📸 Testing capture errors...');
    
    // Test capture with invalid window ID
    try {
      final result = await toolkit.captureWindowAuto(-1);
      switch (result) {
        case CaptureSuccess():
          print('❓ Unexpected capture success for invalid ID');
        case CaptureFailure(:final reason):
          print('✅ Capture failure handled: ${reason.name}');
      }
    } on PlatformException catch (e) {
      print('✅ Capture exception handled: ${e.code}');
    }
  }
  
  Future<void> _testProcessErrors() async {
    print('\n⚙️ Testing process errors...');
    
    // Test terminate non-existent process
    try {
      final success = await toolkit.terminateApplicationByPID(-1);
      print('✅ Terminate invalid PID: $success');
    } on PlatformException catch (e) {
      print('✅ Terminate invalid PID error: ${e.code}');
    }
  }
}
```

## Best Practices Summary

### Error Handling Strategy

1. **Always use try-catch** for all toolkit operations
2. **Handle specific error codes** rather than generic exceptions
3. **Provide user-friendly messages** instead of technical error codes
4. **Implement fallback mechanisms** when possible
5. **Log errors appropriately** for debugging
6. **Test error conditions** during development

### Error Recovery Patterns

```dart
// ✅ Good: Specific error handling with fallback
try {
  return await toolkit.captureWindowAuto(windowId);
} on PlatformException catch (e) {
  if (e.code == 'UNSUPPORTED_MACOS_VERSION') {
    return await toolkit.captureWindowLegacy(windowId);
  }
  rethrow;
}

// ❌ Avoid: Generic error handling without specificity
try {
  return await toolkit.captureWindowAuto(windowId);
} catch (e) {
  print('Something went wrong: $e');
  return null;
}
```

### User Experience

```dart
// ✅ Good: Actionable error messages
void showPermissionError() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Permission Required'),
      content: Text(UserErrorMessages.getHumanReadableError(e)),
      actions: [
        TextButton(
          onPressed: () => toolkit.openScreenRecordingSettings(),
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}

// ❌ Avoid: Technical error messages
void showError(PlatformException e) {
  print('Error: ${e.code}');
}
```

## Thread Safety

All error handling mechanisms are thread-safe and work across isolates.

## Related APIs

- **[Window Management](window_management.md)** - Window-specific errors
- **[Permission Management](permission_management.md)** - Permission-related errors  
- **[Window Capture](window_capture.md)** - Capture failure states
- **[Process Management](process_management.md)** - Process operation errors
- **[System Information](system_info.md)** - Version compatibility errors

---

[← Back to API Reference](../api_reference.md)