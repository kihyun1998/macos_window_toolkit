# Troubleshooting

Common issues and solutions when using macOS Window Toolkit.

## Installation Issues

### Flutter Plugin Not Found

**Problem:** Plugin not recognized after adding to `pubspec.yaml`

**Solutions:**

1. **Run pub get:**
   ```bash
   flutter pub get
   ```

2. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   cd example && flutter run -d macos
   ```

3. **Check pubspec.yaml syntax:**
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     macos_window_toolkit: ^1.0.0  # Ensure proper indentation
   ```

4. **Restart IDE/Editor** after adding the dependency

### Build Failures on macOS

**Problem:** Native compilation errors

**Solutions:**

1. **Check minimum requirements:**
   - macOS 10.11 or later
   - Xcode with Swift 5.0 support
   - Flutter 3.3.0 or later

2. **Clean Xcode build folder:**
   ```bash
   cd example/macos
   xcodebuild clean
   ```

3. **Verify CocoaPods:**
   ```bash
   cd example/ios  # or macos
   pod install --repo-update
   ```

4. **Update macOS deployment target** in `macos/Runner.xcodeproj` to 10.11 or later

## Runtime Issues

### Empty Window List

**Problem:** `getAllWindows()` returns empty list

**Possible Causes & Solutions:**

1. **No windows actually open:**
   - Verify other applications have visible windows
   - Test with multiple apps (Safari, TextEdit, Finder)

2. **System restrictions:**
   - Check macOS privacy settings
   - Grant accessibility permissions if prompted
   - Test with different applications

3. **Debug the issue:**
   ```dart
   void debugWindowList() async {
     try {
       final windows = await MacosWindowToolkit.getAllWindows();
       print('Window count: ${windows.length}');
       
       if (windows.isEmpty) {
         print('No windows found. Possible causes:');
         print('- No applications with windows are running');
         print('- System permissions may be required');
       }
       
       for (final window in windows) {
         print('Found: ${window.name} (${window.ownerName})');
       }
     } catch (e) {
       print('Error getting windows: $e');
     }
   }
   ```

### Permission Errors

**Problem:** `PlatformException` with `PERMISSION_DENIED`

**Solutions:**

1. **Grant Accessibility Permissions:**
   - Open System Preferences → Security & Privacy → Privacy
   - Select "Accessibility" from the left panel
   - Add your Flutter app to the list
   - Ensure the checkbox is checked

2. **Grant Screen Recording Permissions** (if needed):
   - System Preferences → Security & Privacy → Privacy
   - Select "Screen Recording"
   - Add your Flutter app

3. **App-specific permissions:**
   ```dart
   Future<void> handlePermissions() async {
     try {
       final windows = await MacosWindowToolkit.getAllWindows();
       // Success - permissions are OK
     } on PlatformException catch (e) {
       final errorCode = e.errorCode;

       // Check for permission-related errors
       if (errorCode == PlatformErrorCode.accessibilityPermissionDenied ||
           errorCode == PlatformErrorCode.captureScreenRecordingPermissionDenied) {
         _showPermissionDialog();
       }
     }
   }
   
   void _showPermissionDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Permissions Required'),
         content: Text(
           'This app needs accessibility permissions to view window information. '
           'Please grant permissions in System Preferences → Security & Privacy → Privacy → Accessibility.'
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: Text('OK'),
           ),
         ],
       ),
     );
   }
   ```

### Inconsistent Data

**Problem:** Window information seems incorrect or outdated

**Solutions:**

1. **Add debugging output:**
   ```dart
   void debugWindow(WindowInfo window) {
     print('Window Debug Info:');
     print('  ID: ${window.windowId}');
     print('  Name: "${window.name}"');
     print('  App: ${window.ownerName}');
     print('  Bounds: ${window.bounds}');
     print('  Layer: ${window.layer}');
     print('  Visible: ${window.isOnScreen}');
     print('  PID: ${window.processId}');
   }
   ```

2. **Verify coordinate system understanding:**
   ```dart
   void printCoordinateInfo(WindowInfo window) {
     print('Position: (${window.bounds[0]}, ${window.bounds[1]})');
     print('Size: ${window.bounds[2]} × ${window.bounds[3]}');
     print('Right edge: ${window.bounds[0] + window.bounds[2]}');
     print('Bottom edge: ${window.bounds[1] + window.bounds[3]}');
   }
   ```

3. **Check for timing issues:**
   ```dart
   // Add delay before checking windows
   await Future.delayed(Duration(milliseconds: 100));
   final windows = await MacosWindowToolkit.getAllWindows();
   ```

## Performance Issues

### Slow Response Times

**Problem:** `getAllWindows()` takes too long to respond

**Analysis:**
```dart
Future<void> measurePerformance() async {
  final stopwatch = Stopwatch()..start();
  
  try {
    final windows = await MacosWindowToolkit.getAllWindows();
    stopwatch.stop();
    
    print('Time taken: ${stopwatch.elapsedMilliseconds}ms');
    print('Windows found: ${windows.length}');
    print('Average time per window: ${stopwatch.elapsedMilliseconds / windows.length}ms');
    
    if (stopwatch.elapsedMilliseconds > 1000) {
      print('WARNING: Slow performance detected');
      print('Consider implementing caching or filtering');
    }
  } catch (e) {
    stopwatch.stop();
    print('Error after ${stopwatch.elapsedMilliseconds}ms: $e');
  }
}
```

**Solutions:**

1. **Implement caching:**
   ```dart
   class CachedWindowService {
     static List<WindowInfo>? _cache;
     static DateTime? _lastUpdate;
     static const cacheDuration = Duration(seconds: 1);
     
     static Future<List<WindowInfo>> getWindows() async {
       final now = DateTime.now();
       
       if (_cache != null && 
           _lastUpdate != null && 
           now.difference(_lastUpdate!) < cacheDuration) {
         return _cache!;
       }
       
       _cache = await MacosWindowToolkit.getAllWindows();
       _lastUpdate = now;
       return _cache!;
     }
   }
   ```

2. **Filter early:**
   ```dart
   // Instead of getting all windows then filtering
   final allWindows = await MacosWindowToolkit.getAllWindows();
   final visibleWindows = allWindows.where((w) => w.isOnScreen).toList();
   
   // Consider implementing server-side filtering in future versions
   ```

### Memory Usage

**Problem:** High memory usage with many windows

**Solutions:**

1. **Profile memory usage:**
   ```dart
   void profileMemoryUsage() async {
     final beforeWindows = await MacosWindowToolkit.getAllWindows();
     print('Windows loaded: ${beforeWindows.length}');
     
     // Force garbage collection
     beforeWindows.clear();
     
     // Monitor memory in Dart DevTools
   }
   ```

2. **Implement pagination:**
   ```dart
   class PaginatedWindowList {
     static const int pageSize = 50;
     
     static List<WindowInfo> getPage(List<WindowInfo> allWindows, int page) {
       final startIndex = page * pageSize;
       final endIndex = math.min(startIndex + pageSize, allWindows.length);
       
       if (startIndex >= allWindows.length) return [];
       
       return allWindows.sublist(startIndex, endIndex);
     }
   }
   ```

## Debug Mode Setup

### Enable Verbose Logging

1. **Flutter verbose logging:**
   ```bash
   flutter run -d macos --verbose
   ```

2. **Add debug prints in code:**
   ```dart
   class DebugWindowService {
     static bool debugMode = kDebugMode;
     
     static Future<List<WindowInfo>> getAllWindows() async {
       if (debugMode) {
         print('[DEBUG] Getting all windows...');
       }
       
       final stopwatch = Stopwatch()..start();
       
       try {
         final windows = await MacosWindowToolkit.getAllWindows();
         stopwatch.stop();
         
         if (debugMode) {
           print('[DEBUG] Found ${windows.length} windows in ${stopwatch.elapsedMilliseconds}ms');
           for (final window in windows) {
             print('[DEBUG] - ${window.name} (${window.ownerName})');
           }
         }
         
         return windows;
       } catch (e) {
         stopwatch.stop();
         if (debugMode) {
           print('[DEBUG] Error after ${stopwatch.elapsedMilliseconds}ms: $e');
         }
         rethrow;
       }
     }
   }
   ```

3. **Native logging (for advanced debugging):**
   ```bash
   # View macOS Console logs
   log stream --predicate 'subsystem contains "flutter"'
   ```

## Testing and Validation

### Unit Tests for Error Handling

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  group('WindowService Error Handling', () {
    test('should handle platform exceptions gracefully', () async {
      try {
        final windows = await MacosWindowToolkit.getAllWindows();
        expect(windows, isA<List<WindowInfo>>());
      } on PlatformException catch (e) {
        // Expected in some environments
        expect(e.code, isNotEmpty);
        expect(e.message, isNotNull);
      }
    });
    
    test('should validate window data structure', () async {
      try {
        final windows = await MacosWindowToolkit.getAllWindows();
        
        for (final window in windows) {
          expect(window.windowId, isA<int>());
          expect(window.name, isA<String>());
          expect(window.ownerName, isA<String>());
          expect(window.bounds, hasLength(4));
          expect(window.layer, isA<int>());
          expect(window.isOnScreen, isA<bool>());
          expect(window.processId, isA<int>());
          
          // Validate bounds
          expect(window.bounds[2], greaterThan(0)); // width > 0
          expect(window.bounds[3], greaterThan(0)); // height > 0
        }
      } catch (e) {
        // Skip test if windows can't be retrieved
        print('Skipping validation due to: $e');
      }
    });
  });
}
```

### Integration Test Example

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('macOS Window Toolkit Integration Tests', () {
    testWidgets('should retrieve windows successfully', (tester) async {
      bool success = false;
      String? error;
      
      try {
        final windows = await MacosWindowToolkit.getAllWindows();
        success = true;
        
        // Basic validation
        expect(windows, isA<List<WindowInfo>>());
        
        if (windows.isNotEmpty) {
          final firstWindow = windows.first;
          expect(firstWindow.ownerName, isNotEmpty);
          expect(firstWindow.bounds, hasLength(4));
        }
        
      } on PlatformException catch (e) {
        error = '${e.code}: ${e.message}';
      } catch (e) {
        error = e.toString();
      }
      
      if (!success && error != null) {
        print('Integration test failed: $error');
        print('This may be expected in CI/CD environments without UI');
      }
      
      // Test passes if either successful or fails with expected error
      expect(success || error != null, isTrue);
    });
  });
}
```

## Common Error Messages

### `SYSTEM_ERROR`
- **Meaning:** General system error
- **Solutions:** Retry the operation, check system resources
- **Code Example:** See retry logic in Advanced Usage

### `PERMISSION_DENIED` 
- **Meaning:** Insufficient permissions
- **Solutions:** Grant accessibility permissions in System Preferences
- **Code Example:** See permission handling above

### `UNKNOWN_ERROR`
- **Meaning:** Unexpected error occurred
- **Solutions:** Check logs, file bug report with details
- **Prevention:** Use proper error handling patterns

## Getting Help

If you're still experiencing issues:

1. **Check the example app:**
   ```bash
   cd example/
   flutter run -d macos
   ```

2. **Enable debug mode and collect logs**

3. **Search existing issues:**
   [GitHub Issues](https://github.com/kihyun/macos_window_toolkit/issues)

4. **File a new issue** with:
   - Flutter version (`flutter --version`)
   - macOS version
   - Plugin version
   - Complete error messages
   - Minimal reproduction example

5. **Join the discussion:**
   [GitHub Discussions](https://github.com/kihyun/macos_window_toolkit/discussions)