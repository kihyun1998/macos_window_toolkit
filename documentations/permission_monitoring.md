# Permission Monitoring Guide

The macOS Window Toolkit provides powerful real-time permission monitoring capabilities that allow you to track changes in macOS permissions (Screen Recording and Accessibility) with configurable intervals and emission modes.

## Quick Start

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() async {
  final toolkit = MacosWindowToolkit();
  
  // Start monitoring permissions
  toolkit.startPermissionWatching();
  
  // Listen to permission changes
  toolkit.permissionStream.listen((status) {
    print('Permissions changed: ${status.hasChanges}');
    print('Screen Recording: ${status.screenRecording}');
    print('Accessibility: ${status.accessibility}');
  });
}
```

## Core Classes

### PermissionStatus

The `PermissionStatus` class provides a type-safe way to handle permission status updates:

```dart
class PermissionStatus {
  final bool? screenRecording;  // true/false/null (error)
  final bool? accessibility;    // true/false/null (error)
  final bool hasChanges;        // Whether permissions changed since last check
  final DateTime timestamp;     // When this check was performed
  
  // Convenience getters
  bool get allPermissionsGranted;   // All permissions are true
  bool get hasAnyDenied;           // Any permission is false
  bool get hasUnknownStatus;       // Any permission is null (error)
  List<String> get deniedPermissions;   // List of denied permission names
  List<String> get grantedPermissions; // List of granted permission names
}
```

### PermissionWatcher

The `PermissionWatcher` is a singleton that manages the actual permission monitoring:

```dart
final watcher = PermissionWatcher.instance;

// Start/stop monitoring
watcher.startWatching(
  interval: Duration(seconds: 2),
  emitOnlyChanges: true,
);
watcher.stopWatching();

// Check status
bool isActive = watcher.isWatching;

// Stream of permission updates
Stream<PermissionStatus> stream = watcher.permissionStream;
```

## Configuration Options

### Monitoring Interval

Control how frequently permissions are checked:

```dart
// Check every 5 seconds (default: 2 seconds)
toolkit.startPermissionWatching(interval: Duration(seconds: 5));

// Check every 500 milliseconds (more responsive)
toolkit.startPermissionWatching(interval: Duration(milliseconds: 500));
```

### Emission Modes

Control when the stream emits updates:

```dart
// Only emit when permissions actually change (default - efficient)
toolkit.startPermissionWatching(emitOnlyChanges: true);

// Emit on every check (heartbeat mode - good for connection monitoring)
toolkit.startPermissionWatching(emitOnlyChanges: false);
```

## State Management Integration

### Riverpod Integration

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionProvider = StreamProvider<PermissionStatus>((ref) {
  final toolkit = MacosWindowToolkit();
  toolkit.startPermissionWatching();
  return toolkit.permissionStream;
});

class PermissionAwareWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionProvider);
    
    return permissionAsync.when(
      data: (status) {
        if (status.allPermissionsGranted) {
          return MainContentWidget();
        } else {
          return PermissionSetupWidget(
            missingPermissions: status.deniedPermissions,
          );
        }
      },
      loading: () => CircularProgressIndicator(),
      error: (error, _) => ErrorWidget(error),
    );
  }
}

// React to permission changes
class PermissionListener extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(permissionProvider, (previous, current) {
      current.whenData((status) {
        if (status.hasChanges) {
          if (status.screenRecording == false) {
            showPermissionLostDialog();
          }
        }
      });
    });
    
    return MyMainWidget();
  }
}
```

### Bloc Integration

```dart
class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  final MacosWindowToolkit _toolkit;
  StreamSubscription<PermissionStatus>? _subscription;

  PermissionBloc(this._toolkit) : super(PermissionInitial()) {
    on<StartPermissionMonitoring>(_onStartMonitoring);
    on<StopPermissionMonitoring>(_onStopMonitoring);
    on<PermissionStatusChanged>(_onPermissionChanged);
  }

  void _onStartMonitoring(StartPermissionMonitoring event, Emitter emit) {
    _toolkit.startPermissionWatching();
    _subscription = _toolkit.permissionStream.listen(
      (status) => add(PermissionStatusChanged(status)),
    );
  }

  void _onPermissionChanged(PermissionStatusChanged event, Emitter emit) {
    if (event.status.allPermissionsGranted) {
      emit(PermissionGranted());
    } else {
      emit(PermissionDenied(event.status.deniedPermissions));
    }
  }
  
  @override
  Future<void> close() {
    _subscription?.cancel();
    _toolkit.stopPermissionWatching();
    return super.close();
  }
}
```

## Common Patterns

### Permission Gate Widget

```dart
class PermissionGate extends StatefulWidget {
  final Widget child;
  
  const PermissionGate({required this.child, super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  final _toolkit = MacosWindowToolkit();
  
  @override
  void initState() {
    super.initState();
    _toolkit.startPermissionWatching();
  }
  
  @override
  void dispose() {
    _toolkit.stopPermissionWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PermissionStatus>(
      stream: _toolkit.permissionStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        
        if (status == null) {
          return LoadingScreen();
        }
        
        if (status.allPermissionsGranted) {
          return widget.child;
        }
        
        return PermissionSetupScreen(
          deniedPermissions: status.deniedPermissions,
          onPermissionsGranted: () {
            // Will automatically transition when permissions are detected
          },
        );
      },
    );
  }
}
```

### Reactive Permission UI

```dart
class PermissionStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final toolkit = MacosWindowToolkit();
    
    return StreamBuilder<PermissionStatus>(
      stream: toolkit.permissionStream,
      builder: (context, snapshot) {
        final status = snapshot.data;
        
        if (status == null) return SizedBox.shrink();
        
        return Container(
          padding: EdgeInsets.all(8),
          color: status.allPermissionsGranted ? Colors.green : Colors.red,
          child: Row(
            children: [
              Icon(
                status.allPermissionsGranted 
                  ? Icons.check_circle 
                  : Icons.warning,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                status.allPermissionsGranted
                  ? 'All permissions granted'
                  : 'Missing: ${status.deniedPermissions.join(', ')}',
                style: TextStyle(color: Colors.white),
              ),
              Spacer(),
              Text(
                'Last checked: ${status.timestamp.toString().substring(11, 19)}',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## Error Handling

Permission monitoring can fail for various reasons. Handle errors gracefully:

```dart
toolkit.permissionStream.listen(
  (status) {
    if (status.hasUnknownStatus) {
      // Some permissions couldn't be checked (null values)
      print('Permission check failed at ${status.timestamp}');
      
      if (status.screenRecording == null) {
        print('Screen recording permission check failed');
      }
      if (status.accessibility == null) {
        print('Accessibility permission check failed');
      }
    }
  },
  onError: (error) {
    print('Permission monitoring error: $error');
    // Consider restarting monitoring or showing error to user
  },
);
```

## Best Practices

### 1. Choose Appropriate Intervals

```dart
// For security-critical applications (more responsive)
toolkit.startPermissionWatching(interval: Duration(seconds: 1));

// For regular applications (balanced)
toolkit.startPermissionWatching(interval: Duration(seconds: 2));

// For background monitoring (less resource usage)
toolkit.startPermissionWatching(interval: Duration(seconds: 10));
```

### 2. Use emitOnlyChanges Wisely

```dart
// For UI updates (efficient)
toolkit.startPermissionWatching(emitOnlyChanges: true);

// For heartbeat monitoring or "last checked" timestamps
toolkit.startPermissionWatching(emitOnlyChanges: false);
```

### 3. Clean Up Resources

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _toolkit = MacosWindowToolkit();
  StreamSubscription<PermissionStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    _toolkit.startPermissionWatching();
    _subscription = _toolkit.permissionStream.listen(_handlePermissionChange);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _toolkit.stopPermissionWatching();
    super.dispose();
  }

  void _handlePermissionChange(PermissionStatus status) {
    // Handle permission changes
  }
}
```

### 4. Handle App Lifecycle

```dart
class MyApp extends StatefulWidget with WidgetsBindingObserver {
  final _toolkit = MacosWindowToolkit();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _toolkit.startPermissionWatching();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toolkit.stopPermissionWatching();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Optionally stop monitoring when app goes to background
        _toolkit.stopPermissionWatching();
        break;
      case AppLifecycleState.resumed:
        // Restart monitoring when app comes to foreground
        _toolkit.startPermissionWatching();
        break;
    }
  }
}
```

## Performance Considerations

1. **Single Timer**: The plugin ensures only one timer is active at a time, preventing resource waste
2. **Configurable Intervals**: Choose intervals based on your use case
3. **Change Detection**: Use `emitOnlyChanges: true` for efficient UI updates
4. **Proper Cleanup**: Always stop monitoring when not needed to conserve resources

## Security Considerations

1. **User Control**: Always provide users with clear start/stop controls
2. **Transparency**: Show monitoring status clearly in the UI
3. **Privacy**: Only monitor permissions when necessary for functionality
4. **Documentation**: Clearly document why and when you monitor permissions