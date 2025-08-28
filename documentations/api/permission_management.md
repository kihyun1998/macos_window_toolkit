# Permission Management API

Complete reference for macOS permission handling and real-time monitoring.

## Overview

The Permission Management API provides comprehensive functionality for handling macOS permissions required by the toolkit, including screen recording and accessibility permissions. It features both one-time permission checks and real-time monitoring capabilities with change detection.

## Quick Reference

### Permission Checking
| Method | Description | Returns |
|--------|-------------|---------|
| [`hasScreenRecordingPermission()`](#hasscreenrecordingpermission) | Check screen recording permission | `Future<bool>` |
| [`hasAccessibilityPermission()`](#hasaccessibilitypermission) | Check accessibility permission | `Future<bool>` |

### Permission Requests
| Method | Description | Returns |
|--------|-------------|---------|
| [`requestScreenRecordingPermission()`](#requestscreenrecordingpermission) | Request screen recording access | `Future<bool>` |
| [`requestAccessibilityPermission()`](#requestaccessibilitypermission) | Request accessibility access | `Future<bool>` |
| [`openScreenRecordingSettings()`](#openscreenrecordingsettings) | Open system settings | `Future<bool>` |
| [`openAccessibilitySettings()`](#openaccessibilitysettings) | Open accessibility settings | `Future<bool>` |

### Real-time Monitoring
| Method/Property | Description | Type |
|-----------------|-------------|------|
| [`startPermissionWatching()`](#startpermissionwatching) | Start permission monitoring | `void` |
| [`stopPermissionWatching()`](#stoppermissionwatching) | Stop monitoring | `void` |
| [`permissionStream`](#permissionstream) | Stream of permission changes | `Stream<PermissionStatus>` |
| [`isPermissionWatching`](#ispermissionwatching) | Check monitoring status | `bool` |

## Permission Checking Methods

### `hasScreenRecordingPermission()`

Checks if the app has screen recording permission.

**Signature:**
```dart
Future<bool> hasScreenRecordingPermission()
```

**Returns:**
- `Future<bool>` - `true` if permission is granted, `false` otherwise

**Throws:**
- Generally does not throw exceptions; returns `false` on error

**Example:**
```dart
final toolkit = MacosWindowToolkit();

final hasPermission = await toolkit.hasScreenRecordingPermission();
if (hasPermission) {
  print('Screen recording permission granted');
  // Window names will be available
  final windows = await toolkit.getAllWindows();
  // ... process windows
} else {
  print('Screen recording permission denied');
  // Window names may be empty or unavailable
}
```

**Platform Notes:**
- On macOS 10.14 (Mojave) and earlier, always returns `true`
- On macOS 10.15 (Catalina) and later, checks actual permission status
- Required for accessing window names and some window properties

**Performance:**
- Very fast operation (~1-2ms)
- Safe to call frequently

---

### `hasAccessibilityPermission()`

Checks if the app has accessibility permission.

**Signature:**
```dart
Future<bool> hasAccessibilityPermission()
```

**Returns:**
- `Future<bool>` - `true` if permission is granted, `false` otherwise

**Throws:**
- Generally does not throw exceptions; returns `false` on error

**Example:**
```dart
final toolkit = MacosWindowToolkit();

final hasPermission = await toolkit.hasAccessibilityPermission();
if (hasPermission) {
  print('Accessibility permission granted');
  // Can perform window operations
  await toolkit.closeWindow(windowId);
} else {
  print('Accessibility permission required for window operations');
  // Request permission first
  await toolkit.requestAccessibilityPermission();
}
```

**Required For:**
- `closeWindow()` operations
- Advanced window manipulations
- Some window property access

**Performance:**
- Very fast operation (~1-2ms)
- Safe to call frequently

---

## Permission Request Methods

### `requestScreenRecordingPermission()`

Requests screen recording permission from the user.

**Signature:**
```dart
Future<bool> requestScreenRecordingPermission()
```

**Returns:**
- `Future<bool>` - `true` if permission is granted, `false` if denied

**Throws:**
- Generally does not throw exceptions; returns `false` on failure

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Check current status first
final hasPermission = await toolkit.hasScreenRecordingPermission();
if (!hasPermission) {
  print('Requesting screen recording permission...');
  
  final granted = await toolkit.requestScreenRecordingPermission();
  if (granted) {
    print('Permission granted! You may need to restart the app.');
    // App restart may be required for permission to take effect
  } else {
    print('Permission denied. Window names may not be available.');
    
    // Guide user to manually enable permission
    final opened = await toolkit.openScreenRecordingSettings();
    if (opened) {
      print('Please enable screen recording permission and restart the app');
    }
  }
} else {
  print('Screen recording permission already granted');
}
```

**Important Notes:**
- System dialog only appears once per app session
- If user has already seen and dismissed the dialog, subsequent calls won't show it again
- App restart may be required for permission changes to take effect
- On macOS 10.14 and earlier, always returns `true`

**User Experience:**
- Shows native macOS permission dialog
- User can click "Open System Preferences" for direct access to settings
- Permission denial is remembered until app restart

---

### `requestAccessibilityPermission()`

Requests accessibility permission from the user.

**Signature:**
```dart
Future<bool> requestAccessibilityPermission()
```

**Returns:**
- `Future<bool>` - `true` if permission is granted, `false` if denied or not yet granted

**Throws:**
- Generally does not throw exceptions; returns `false` on failure

**Example:**
```dart
final toolkit = MacosWindowToolkit();

final hasPermission = await toolkit.hasAccessibilityPermission();
if (!hasPermission) {
  print('Requesting accessibility permission...');
  
  final granted = await toolkit.requestAccessibilityPermission();
  if (granted) {
    print('Accessibility permission granted!');
  } else {
    print('Accessibility permission denied or not yet granted.');
    print('Please enable accessibility in System Preferences.');
    
    // Open settings for user
    await toolkit.openAccessibilitySettings();
  }
} else {
  print('Accessibility permission already granted');
}
```

**Important Notes:**
- Unlike screen recording, accessibility permission requires manual user action
- System dialog guides users to System Preferences, but permission must be enabled manually
- App restart may be required after granting permission
- Permission changes may take effect immediately in some cases

**Manual Steps Required:**
1. User sees permission dialog
2. User clicks to open System Preferences
3. User manually enables accessibility for the app
4. User may need to restart the app

---

### `openScreenRecordingSettings()`

Opens the Screen Recording section in System Preferences.

**Signature:**
```dart
Future<bool> openScreenRecordingSettings()
```

**Returns:**
- `Future<bool>` - `true` if System Preferences was opened successfully, `false` otherwise

**Throws:**
- Generally does not throw exceptions; returns `false` on failure

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Use when system dialog doesn't appear or user needs manual setup
final hasPermission = await toolkit.hasScreenRecordingPermission();
if (!hasPermission) {
  // Try requesting permission first
  final granted = await toolkit.requestScreenRecordingPermission();
  
  if (!granted) {
    print('System dialog didn\'t appear or was denied');
    print('Opening Screen Recording settings...');
    
    final opened = await toolkit.openScreenRecordingSettings();
    if (opened) {
      print('Please enable screen recording permission for this app');
      print('and restart the application');
    } else {
      print('Unable to open System Preferences');
      print('Please manually navigate to:');
      print('System Preferences > Privacy & Security > Screen Recording');
    }
  }
}
```

**Fallback Behavior:**
1. First attempts to open specific Screen Recording settings page
2. Falls back to general Privacy & Security settings
3. As last resort, opens System Preferences main window

**Use Cases:**
- When `requestScreenRecordingPermission()` doesn't show dialog
- For manual permission setup guidance
- When user needs to review or modify existing permissions

---

### `openAccessibilitySettings()`

Opens the Accessibility section in System Preferences.

**Signature:**
```dart
Future<bool> openAccessibilitySettings()
```

**Returns:**
- `Future<bool>` - `true` if System Preferences was opened successfully, `false` otherwise

**Throws:**
- Generally does not throw exceptions; returns `false` on failure

**Example:**
```dart
final toolkit = MacosWindowToolkit();

final hasPermission = await toolkit.hasAccessibilityPermission();
if (!hasPermission) {
  print('Opening Accessibility settings...');
  
  final opened = await toolkit.openAccessibilitySettings();
  if (opened) {
    print('Please enable accessibility permission for this app');
    print('and restart the application');
    print('');
    print('Instructions:');
    print('1. Find your app in the list');
    print('2. Check the box next to your app name');
    print('3. Restart your app');
  } else {
    print('Unable to open System Preferences');
    print('Please manually navigate to:');
    print('System Preferences > Privacy & Security > Accessibility');
  }
}
```

**Fallback Behavior:**
1. First attempts to open specific Accessibility settings page  
2. Falls back to general Privacy & Security settings
3. As last resort, opens System Preferences main window

---

## Real-time Permission Monitoring

### `startPermissionWatching()`

Starts monitoring permissions at the specified interval.

**Signature:**
```dart
void startPermissionWatching({
  Duration interval = const Duration(seconds: 2),
  bool emitOnlyChanges = true,
})
```

**Parameters:**
- `interval` (optional) - Frequency to check permissions. Defaults to 2 seconds.
- `emitOnlyChanges` (optional) - If `true` (default), only emits when permissions change. If `false`, emits on every check.

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Start monitoring with default settings (2-second interval, changes only)
toolkit.startPermissionWatching();

// Start monitoring with custom interval
toolkit.startPermissionWatching(
  interval: Duration(seconds: 5),
);

// Start monitoring with heartbeat (emit even without changes)
toolkit.startPermissionWatching(
  interval: Duration(seconds: 3),
  emitOnlyChanges: false,
);

// Listen to permission changes
toolkit.permissionStream.listen((status) {
  if (status.hasChanges) {
    print('Permission status changed!');
    print('Screen Recording: ${status.screenRecording}');
    print('Accessibility: ${status.accessibility}');
    
    if (!status.screenRecording) {
      // Handle screen recording permission loss
      showPermissionDialog(context);
    }
  }
});
```

**Behavior:**
- If monitoring is already active, cancels existing timer and starts new one
- Prevents multiple timers from running simultaneously
- Emits initial status immediately when starting

**Interval Guidelines:**
- **1-2 seconds**: Responsive, good for user-facing applications
- **3-5 seconds**: Balanced, good for most use cases  
- **10+ seconds**: Efficient, good for background monitoring

---

### `stopPermissionWatching()`

Stops permission monitoring.

**Signature:**
```dart
void stopPermissionWatching()
```

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Start monitoring
toolkit.startPermissionWatching();

// Later, stop monitoring to save resources
toolkit.stopPermissionWatching();

// Check if monitoring is still active
if (toolkit.isPermissionWatching) {
  print('Still monitoring permissions');
} else {
  print('Permission monitoring stopped');
}
```

**Notes:**
- Cancels active timer and stops permission checks
- Stream remains available for reconnection
- Can call `startPermissionWatching()` again to resume

---

### `permissionStream`

Stream of permission status changes.

**Type:** `Stream<PermissionStatus>`

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Must start watching before stream emits values
toolkit.startPermissionWatching();

// Basic usage
toolkit.permissionStream.listen((status) {
  print('Screen recording: ${status.screenRecording}');
  print('Accessibility: ${status.accessibility}');
  print('Has changes: ${status.hasChanges}');
  print('All granted: ${status.allPermissionsGranted}');
});

// React to permission changes only
toolkit.permissionStream
    .where((status) => status.hasChanges)
    .listen((status) {
      print('Permissions changed at ${status.timestamp}');
      
      // Handle specific changes
      if (status.screenRecording == false) {
        navigateToPermissionSetup();
      }
      
      if (status.allPermissionsGranted) {
        print('All permissions granted! 🎉');
      } else {
        final missing = status.deniedPermissions.join(', ');
        print('Missing permissions: $missing');
      }
    });

// Handle errors (when permission status is null)
toolkit.permissionStream.listen((status) {
  if (status.hasUnknownStatus) {
    print('Permission check error occurred');
    // Handle error state
  }
});
```

**Integration with State Management:**

#### Riverpod Integration
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionProvider = StreamProvider<PermissionStatus>((ref) {
  final toolkit = MacosWindowToolkit();
  toolkit.startPermissionWatching(
    interval: Duration(seconds: 2),
    emitOnlyChanges: true,
  );
  return toolkit.permissionStream;
});

// In widget
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionProvider);
    
    return permissionAsync.when(
      data: (status) {
        if (status.allPermissionsGranted) {
          return MainApp();
        } else {
          return PermissionSetupScreen(
            missingPermissions: status.deniedPermissions,
          );
        }
      },
      loading: () => LoadingScreen(),
      error: (error, _) => ErrorScreen(error: error),
    );
  }
}
```

#### Bloc Integration
```dart
class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  late StreamSubscription _subscription;

  PermissionBloc() : super(PermissionInitial()) {
    toolkit.startPermissionWatching();
    _subscription = toolkit.permissionStream.listen((status) {
      add(PermissionStatusUpdated(status));
    });
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    toolkit.stopPermissionWatching();
    return super.close();
  }
}
```

---

### `isPermissionWatching`

Whether permission monitoring is currently active.

**Type:** `bool`

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Check before starting to avoid duplicate monitoring
if (!toolkit.isPermissionWatching) {
  toolkit.startPermissionWatching();
  print('Started permission monitoring');
} else {
  print('Permission monitoring already active');
}

// Show status in UI
Widget buildStatusIndicator() {
  return Row(
    children: [
      Icon(toolkit.isPermissionWatching 
           ? Icons.visibility 
           : Icons.visibility_off),
      Text(toolkit.isPermissionWatching 
           ? 'Permission monitoring: ON' 
           : 'Permission monitoring: OFF'),
    ],
  );
}

// Toggle monitoring
void toggleMonitoring() {
  if (toolkit.isPermissionWatching) {
    toolkit.stopPermissionWatching();
  } else {
    toolkit.startPermissionWatching();
  }
}
```

**Use Cases:**
- Preventing duplicate monitoring setup
- Showing monitoring status in UI
- Conditional logic based on monitoring state
- Resource management

---

## PermissionStatus Data Model

Represents the current status of macOS permissions with change detection.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `screenRecording` | `bool?` | Screen recording permission status |
| `accessibility` | `bool?` | Accessibility permission status |
| `hasChanges` | `bool` | Whether permissions changed since last check |
| `timestamp` | `DateTime` | When this permission check was performed |

### Permission Values

| Value | Meaning |
|-------|---------|
| `true` | Permission granted |
| `false` | Permission denied |
| `null` | Permission status unknown (error occurred) |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `allPermissionsGranted` | `bool` | Whether all required permissions are granted |
| `hasAnyDenied` | `bool` | Whether any permission is denied |
| `hasUnknownStatus` | `bool` | Whether any permission status is unknown |
| `deniedPermissions` | `List<String>` | List of denied permission names |
| `grantedPermissions` | `List<String>` | List of granted permission names |

### Constructor

```dart
const PermissionStatus({
  required this.screenRecording,
  required this.accessibility,
  required this.hasChanges,
  required this.timestamp,
});
```

### Example Usage

```dart
toolkit.permissionStream.listen((status) {
  print('=== Permission Status ===');
  print('Screen Recording: ${status.screenRecording}');
  print('Accessibility: ${status.accessibility}');
  print('Has Changes: ${status.hasChanges}');
  print('Timestamp: ${status.timestamp}');
  print('');
  
  // Computed properties
  print('All Granted: ${status.allPermissionsGranted}');
  print('Any Denied: ${status.hasAnyDenied}');
  print('Unknown Status: ${status.hasUnknownStatus}');
  print('');
  
  // Permission lists
  if (status.grantedPermissions.isNotEmpty) {
    print('Granted: ${status.grantedPermissions.join(', ')}');
  }
  
  if (status.deniedPermissions.isNotEmpty) {
    print('Denied: ${status.deniedPermissions.join(', ')}');
  }
  
  // Handle different states
  if (status.allPermissionsGranted) {
    enableAllFeatures();
  } else if (status.hasAnyDenied) {
    showPermissionPrompt(status.deniedPermissions);
  } else if (status.hasUnknownStatus) {
    showErrorMessage('Unable to check permissions');
  }
});
```

### Methods

#### `copyWith()`

Creates a copy with updated values.

```dart
PermissionStatus copyWith({
  bool? screenRecording,
  bool? accessibility,
  bool? hasChanges,
  DateTime? timestamp,
})
```

**Example:**
```dart
final updatedStatus = currentStatus.copyWith(
  screenRecording: true,
  hasChanges: true,
  timestamp: DateTime.now(),
);
```

## Complete Usage Examples

### Basic Permission Setup

```dart
class PermissionManager {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<bool> setupPermissions() async {
    print('Checking permissions...');
    
    // Check current permissions
    final screenRecording = await toolkit.hasScreenRecordingPermission();
    final accessibility = await toolkit.hasAccessibilityPermission();
    
    print('Screen Recording: $screenRecording');
    print('Accessibility: $accessibility');
    
    bool allGranted = true;
    
    // Request screen recording permission
    if (!screenRecording) {
      print('Requesting screen recording permission...');
      final granted = await toolkit.requestScreenRecordingPermission();
      
      if (!granted) {
        print('Opening screen recording settings...');
        await toolkit.openScreenRecordingSettings();
        allGranted = false;
      }
    }
    
    // Request accessibility permission
    if (!accessibility) {
      print('Requesting accessibility permission...');
      final granted = await toolkit.requestAccessibilityPermission();
      
      if (!granted) {
        print('Opening accessibility settings...');
        await toolkit.openAccessibilitySettings();
        allGranted = false;
      }
    }
    
    return allGranted;
  }
}
```

### Real-time Permission Monitoring with UI

```dart
class PermissionMonitor extends StatefulWidget {
  @override
  _PermissionMonitorState createState() => _PermissionMonitorState();
}

class _PermissionMonitorState extends State<PermissionMonitor> {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  late StreamSubscription<PermissionStatus> _subscription;
  PermissionStatus? _currentStatus;
  
  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }
  
  void _startMonitoring() {
    toolkit.startPermissionWatching(
      interval: Duration(seconds: 2),
      emitOnlyChanges: false, // Show all updates
    );
    
    _subscription = toolkit.permissionStream.listen((status) {
      setState(() {
        _currentStatus = status;
      });
      
      if (status.hasChanges) {
        _showPermissionChangeDialog(status);
      }
    });
  }
  
  void _showPermissionChangeDialog(PermissionStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissions Changed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Screen Recording: ${status.screenRecording}'),
            Text('Accessibility: ${status.accessibility}'),
            if (status.deniedPermissions.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Missing: ${status.deniedPermissions.join(', ')}'),
            ],
          ],
        ),
        actions: [
          if (!status.allPermissionsGranted) ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (!status.screenRecording) {
                  await toolkit.openScreenRecordingSettings();
                }
                if (!status.accessibility) {
                  await toolkit.openAccessibilitySettings();
                }
              },
              child: Text('Open Settings'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final status = _currentStatus;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Permission Monitor'),
        actions: [
          IconButton(
            icon: Icon(toolkit.isPermissionWatching 
                      ? Icons.pause 
                      : Icons.play_arrow),
            onPressed: () {
              setState(() {
                if (toolkit.isPermissionWatching) {
                  toolkit.stopPermissionWatching();
                } else {
                  _startMonitoring();
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monitoring status
            Card(
              child: ListTile(
                leading: Icon(toolkit.isPermissionWatching 
                             ? Icons.visibility 
                             : Icons.visibility_off),
                title: Text('Permission Monitoring'),
                subtitle: Text(toolkit.isPermissionWatching 
                              ? 'Active' 
                              : 'Stopped'),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Permission status
            if (status != null) ...[
              Text('Current Status', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 8),
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPermissionRow('Screen Recording', status.screenRecording),
                      _buildPermissionRow('Accessibility', status.accessibility),
                      SizedBox(height: 8),
                      Text('Last updated: ${status.timestamp.toString().substring(0, 19)}'),
                      Text('Has changes: ${status.hasChanges}'),
                      
                      if (!status.allPermissionsGranted) ...[
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _requestMissingPermissions(status),
                          child: Text('Request Missing Permissions'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text('Waiting for permission status...'),
              CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPermissionRow(String name, bool? granted) {
    IconData icon;
    Color color;
    String statusText;
    
    if (granted == true) {
      icon = Icons.check_circle;
      color = Colors.green;
      statusText = 'Granted';
    } else if (granted == false) {
      icon = Icons.cancel;
      color = Colors.red;
      statusText = 'Denied';
    } else {
      icon = Icons.help;
      color = Colors.orange;
      statusText = 'Unknown';
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text('$name: $statusText'),
        ],
      ),
    );
  }
  
  Future<void> _requestMissingPermissions(PermissionStatus status) async {
    if (status.screenRecording != true) {
      final granted = await toolkit.requestScreenRecordingPermission();
      if (!granted) {
        await toolkit.openScreenRecordingSettings();
      }
    }
    
    if (status.accessibility != true) {
      final granted = await toolkit.requestAccessibilityPermission();
      if (!granted) {
        await toolkit.openAccessibilitySettings();
      }
    }
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    toolkit.stopPermissionWatching();
    super.dispose();
  }
}
```

## Best Practices

### Permission Flow Design

```dart
class PermissionFlow {
  static Future<bool> ensurePermissions(
    BuildContext context,
    MacosWindowToolkit toolkit,
  ) async {
    // Check current permissions
    final screenRecording = await toolkit.hasScreenRecordingPermission();
    final accessibility = await toolkit.hasAccessibilityPermission();
    
    if (screenRecording && accessibility) {
      return true; // All permissions granted
    }
    
    // Show permission explanation
    final proceed = await _showPermissionExplanation(context);
    if (!proceed) return false;
    
    // Request missing permissions
    bool allGranted = true;
    
    if (!screenRecording) {
      allGranted &= await _requestScreenRecording(context, toolkit);
    }
    
    if (!accessibility) {
      allGranted &= await _requestAccessibility(context, toolkit);
    }
    
    return allGranted;
  }
  
  static Future<bool> _showPermissionExplanation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissions Required'),
        content: Text(
          'This app needs screen recording and accessibility permissions '
          'to function properly. These permissions allow the app to:\n\n'
          '• View window information\n'
          '• Capture window screenshots\n'
          '• Perform window operations\n\n'
          'Your privacy is protected - no data is collected or transmitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }
}
```

### Error Handling

```dart
Future<PermissionStatus?> safeGetPermissionStatus(
  MacosWindowToolkit toolkit,
) async {
  try {
    // Start monitoring to get current status
    toolkit.startPermissionWatching();
    
    // Wait for first status update
    final status = await toolkit.permissionStream.first
        .timeout(Duration(seconds: 5));
    
    return status;
  } catch (e) {
    print('Failed to get permission status: $e');
    return null;
  }
}
```

### Resource Management

```dart
class PermissionService {
  static final _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();
  
  final MacosWindowToolkit _toolkit = MacosWindowToolkit();
  StreamSubscription<PermissionStatus>? _subscription;
  
  void startMonitoring() {
    if (_subscription != null) return; // Already monitoring
    
    _toolkit.startPermissionWatching();
    _subscription = _toolkit.permissionStream.listen(_handlePermissionChange);
  }
  
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _toolkit.stopPermissionWatching();
  }
  
  void _handlePermissionChange(PermissionStatus status) {
    if (status.hasChanges) {
      // Notify other parts of the app
      eventBus.fire(PermissionChangedEvent(status));
    }
  }
}
```

## Thread Safety

All permission management methods are thread-safe and can be called from any isolate.

## Related APIs

- **[Window Management](window_management.md)** - Requires screen recording permission
- **[Window Capture](window_capture.md)** - Requires screen recording permission
- **[Error Handling](error_handling.md)** - Handle permission-related errors

---

[← Back to API Reference](../api_reference.md)