# Application Discovery API

The Application Discovery API provides type-safe methods to discover and search installed applications on macOS systems. This API uses direct file system enumeration for high performance and includes comprehensive error handling.

## Overview

- **Type Safety**: All methods return structured `ApplicationResult` objects instead of throwing exceptions
- **Rich Metadata**: Access application name, bundle ID, version, path, and icon path
- **Comprehensive Search**: Scans multiple system directories including user and system applications
- **Performance**: Direct file system access is faster than command-line tools like `mdfind`
- **Error Handling**: User-friendly error messages with actionable suggestions

## Core Types

### MacosApplicationInfo

Represents information about a single macOS application.

```dart
class MacosApplicationInfo {
  final String name;       // Application display name
  final String bundleId;   // Bundle identifier (e.g., "com.apple.Safari")
  final String version;    // Application version string
  final String path;       // Full path to application bundle
  final String iconPath;   // Path to application icon file
}
```

### ApplicationResult

Sealed class representing the result of application discovery operations.

```dart
sealed class ApplicationResult {}

class ApplicationSuccess extends ApplicationResult {
  final List<MacosApplicationInfo> applications;
}

class ApplicationFailure extends ApplicationResult {
  final ApplicationFailureReason reason;
  final String? message;
  final String? details;
  
  String get userMessage;           // User-friendly error message
  bool get canRetry;               // Whether operation can be retried
  String? get suggestedAction;     // Suggested user action
}
```

### ApplicationFailureReason

Enum representing specific failure reasons:

```dart
enum ApplicationFailureReason {
  permissionDenied,  // Permission denied to access application information
  systemError,       // System error during application scanning
  notFound,         // No applications found matching criteria
  unknown,          // Unknown failure reason
}
```

## Methods

### getAllInstalledApplications()

Retrieves all installed applications on the system.

```dart
Future<ApplicationResult> getAllInstalledApplications()
```

**Returns**: `ApplicationResult` containing either success with application list or failure with reason.

**Search Locations**:
- `/Applications` - User-installed applications
- `/System/Applications` - System applications
- `/System/Applications/Utilities` - System utilities
- `~/Applications` - User-specific applications
- `/System/Library/CoreServices` - Core system services

**Example**:

```dart
final toolkit = MacosWindowToolkit();
final result = await toolkit.getAllInstalledApplications();

switch (result) {
  case ApplicationSuccess(applications: final apps):
    print('Found ${apps.length} applications');
    for (final app in apps) {
      print('${app.name} (${app.bundleId}) v${app.version}');
    }
    
  case ApplicationFailure():
    print('Failed: ${result.userMessage}');
    if (result.canRetry) {
      print('Suggestion: ${result.suggestedAction}');
    }
}
```

### getApplicationByName(String name)

Searches for applications whose display name contains the specified string.

```dart
Future<ApplicationResult> getApplicationByName(String name)
```

**Parameters**:
- `name` (String): Search term for application name (case-insensitive)

**Returns**: `ApplicationResult` containing matching applications or failure reason.

**Search Behavior**:
- Case-insensitive substring matching
- Searches application display names only
- Returns all matching applications (can be multiple)
- Empty results are success (not failure)

**Example**:

```dart
final toolkit = MacosWindowToolkit();

// Search for Safari
final result = await toolkit.getApplicationByName('Safari');
switch (result) {
  case ApplicationSuccess(applications: final apps):
    if (apps.isNotEmpty) {
      final safari = apps.first;
      print('Found Safari at: ${safari.path}');
      print('Version: ${safari.version}');
    } else {
      print('Safari not found');
    }
    
  case ApplicationFailure():
    print('Search failed: ${result.userMessage}');
}

// Search for all code editors
final codeResult = await toolkit.getApplicationByName('Code');
if (codeResult case ApplicationSuccess(applications: final codeApps)) {
  for (final app in codeApps) {
    print('Code editor: ${app.name} (${app.bundleId})');
  }
}
```

## Error Handling

Unlike other APIs that throw exceptions, Application Discovery methods return `ApplicationResult` objects that encapsulate both success and failure states.

### Handling Different Error Types

```dart
final result = await toolkit.getAllInstalledApplications();

switch (result) {
  case ApplicationSuccess(applications: final apps):
    // Handle success
    processApplications(apps);
    
  case ApplicationFailure(reason: ApplicationFailureReason.permissionDenied):
    // Handle permission issues
    await requestPermissions();
    
  case ApplicationFailure(reason: ApplicationFailureReason.systemError):
    // Handle system errors (can retry)
    if (result.canRetry) {
      await retryOperation();
    }
    
  case ApplicationFailure(reason: ApplicationFailureReason.notFound):
    // Handle no results (rare for getAllInstalledApplications)
    showNoApplicationsMessage();
    
  case ApplicationFailure():
    // Handle unknown errors
    showGenericError(result.userMessage);
}
```

### User-Friendly Error Messages

```dart
void handleApplicationError(ApplicationFailure failure) {
  // Show user-friendly message
  print('Error: ${failure.userMessage}');
  
  // Show suggested action if available
  if (failure.suggestedAction != null) {
    print('Try: ${failure.suggestedAction}');
  }
  
  // Enable retry button if applicable
  if (failure.canRetry) {
    showRetryButton();
  }
}
```

## Performance Considerations

### Optimization Tips

1. **Cache Results**: Application lists don't change frequently
```dart
class ApplicationCache {
  static List<MacosApplicationInfo>? _cachedApps;
  static DateTime? _lastUpdate;
  
  static Future<List<MacosApplicationInfo>?> getCachedApps() async {
    if (_cachedApps != null && _lastUpdate != null) {
      final age = DateTime.now().difference(_lastUpdate!);
      if (age.inMinutes < 30) { // Cache for 30 minutes
        return _cachedApps;
      }
    }
    return null;
  }
  
  static void updateCache(List<MacosApplicationInfo> apps) {
    _cachedApps = apps;
    _lastUpdate = DateTime.now();
  }
}
```

2. **Background Loading**: Load applications in background
```dart
class ApplicationService {
  static final StreamController<ApplicationResult> _controller = 
      StreamController<ApplicationResult>.broadcast();
  
  static Stream<ApplicationResult> get applicationStream => _controller.stream;
  
  static Future<void> loadApplicationsInBackground() async {
    final toolkit = MacosWindowToolkit();
    final result = await toolkit.getAllInstalledApplications();
    _controller.add(result);
  }
}
```

3. **Filtering After Load**: Filter in memory instead of multiple searches
```dart
final result = await toolkit.getAllInstalledApplications();
if (result case ApplicationSuccess(applications: final allApps)) {
  // Filter developer tools
  final devApps = allApps.where((app) =>
    app.bundleId.contains('developer') ||
    app.name.toLowerCase().contains('xcode')
  ).toList();
  
  // Filter by category
  final browsers = allApps.where((app) =>
    ['Safari', 'Chrome', 'Firefox', 'Edge'].any((browser) =>
      app.name.toLowerCase().contains(browser.toLowerCase())
    )
  ).toList();
}
```

## Integration Patterns

### With State Management (Riverpod)

```dart
final applicationProvider = FutureProvider<ApplicationResult>((ref) async {
  final toolkit = MacosWindowToolkit();
  return await toolkit.getAllInstalledApplications();
});

class ApplicationListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationAsync = ref.watch(applicationProvider);
    
    return applicationAsync.when(
      data: (result) {
        switch (result) {
          case ApplicationSuccess(applications: final apps):
            return ApplicationListView(applications: apps);
          case ApplicationFailure():
            return ErrorWidget(
              message: result.userMessage,
              canRetry: result.canRetry,
              onRetry: () => ref.invalidate(applicationProvider),
            );
        }
      },
      loading: () => const LoadingWidget(),
      error: (error, _) => ErrorWidget(message: error.toString()),
    );
  }
}
```

### Search Implementation

```dart
class ApplicationSearchDelegate extends SearchDelegate<MacosApplicationInfo?> {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<ApplicationResult>(
      future: toolkit.getApplicationByName(query),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final result = snapshot.data!;
          switch (result) {
            case ApplicationSuccess(applications: final apps):
              return ListView.builder(
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return ListTile(
                    title: Text(app.name),
                    subtitle: Text(app.bundleId),
                    onTap: () => close(context, app),
                  );
                },
              );
            case ApplicationFailure():
              return Center(child: Text(result.userMessage));
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
```

## Security Considerations

- **No Permissions Required**: Application discovery uses public APIs and doesn't require special permissions
- **Read-Only Access**: Only reads application bundle information, doesn't modify anything
- **Privacy Compliant**: Doesn't access user data or track application usage
- **Sandbox Compatible**: Works in sandboxed environments (App Store apps)

## Version Compatibility

- **macOS**: 10.11+ (all supported macOS versions)
- **Flutter**: 3.3.0+
- **Dart**: 3.8.1+

## Migration from Raw Maps

If migrating from older versions that returned raw maps:

```dart
// Old approach (v1.1.5 and earlier)
try {
  final List<Map<String, dynamic>> apps = await toolkit.getAllInstalledApplications();
  for (final app in apps) {
    print('${app['name']} (${app['bundleId']})');
  }
} catch (e) {
  print('Error: $e');
}

// New approach (v1.1.6+)
final result = await toolkit.getAllInstalledApplications();
switch (result) {
  case ApplicationSuccess(applications: final apps):
    for (final app in apps) {
      print('${app.name} (${app.bundleId})');
    }
  case ApplicationFailure():
    print('Error: ${result.userMessage}');
}
```

The new approach provides:
- **Compile-time type safety**
- **Better error handling**
- **More descriptive error messages**
- **Structured failure reasons**
- **Retry guidance**