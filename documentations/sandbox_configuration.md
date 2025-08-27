# Sandbox Configuration

This document explains why and how to disable macOS App Sandbox when using the macOS Window Toolkit plugin.

## Overview

The macOS Window Toolkit plugin requires **App Sandbox to be disabled** to function properly. This is due to the system-level APIs used by the plugin that require unrestricted access to other applications and system resources.

## Why Sandbox Must Be Disabled

### Core API Requirements

The plugin uses several macOS APIs that are incompatible with sandboxed environments:

#### 1. Window Information Access
- **API**: `CGWindowListCopyWindowInfo()`
- **Purpose**: Retrieves information about all open windows on the system
- **Restriction**: Sandboxed apps cannot access window data from other processes
- **Usage**: Core functionality for window enumeration

#### 2. Accessibility API Operations
- **APIs**: 
  - `AXUIElementCreateApplication()` - Creates accessibility elements for other apps
  - `AXUIElementCopyAttributeValue()` - Reads window properties from other apps  
  - `AXUIElementPerformAction()` - Performs actions on other app windows
- **Purpose**: Window manipulation (closing windows, getting detailed properties)
- **Restriction**: Requires system-wide accessibility access
- **Usage**: Window closing functionality

#### 3. Process Control Operations
- **APIs**:
  - `kill()` system calls - Terminates other processes
  - `sysctl()` - Queries system process lists
  - `NSRunningApplication` - Controls other applications
- **Purpose**: Application termination and process management
- **Restriction**: Process control requires unrestricted system access
- **Usage**: Application termination features

#### 4. Screen Capture (Legacy Support)
- **API**: `CGWindowListCreateImage()`
- **Purpose**: Captures screenshots of other application windows
- **Restriction**: Requires access to other applications' visual content
- **Usage**: Window screenshot functionality

#### 5. Apple Events Communication
- **Entitlement**: `com.apple.security.automation.apple-events`
- **Purpose**: Inter-app communication for window management
- **Restriction**: Requires explicit entitlement for Apple Events
- **Usage**: Advanced window control operations

## Configuration Steps

### 1. Disable App Sandbox

Edit your entitlements files to disable sandbox:

**File**: `macos/Runner/Release.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

**File**: `macos/Runner/DebugProfile.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

### 2. Required Entitlements

The following entitlements are required for full functionality:

| Entitlement | Required | Purpose |
|-------------|----------|---------|
| `com.apple.security.app-sandbox` | **false** | Disable sandbox to access system resources |
| `com.apple.security.automation.apple-events` | **true** | Enable Apple Events for inter-app communication |
| `com.apple.security.cs.allow-jit` | true | Allow JIT compilation (debug builds) |
| `com.apple.security.network.server` | true | Allow network server capabilities (debug builds) |

### 3. Verification

After configuration, verify that your app can access system windows:

```dart
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void verifyConfiguration() async {
  try {
    final toolkit = MacosWindowToolkit();
    final windows = await toolkit.getAllWindows();
    
    if (windows.isNotEmpty) {
      print('✅ Sandbox disabled successfully');
      print('Found ${windows.length} windows');
    } else {
      print('⚠️ No windows found - check configuration');
    }
  } catch (e) {
    print('❌ Configuration error: $e');
  }
}
```

## Distribution Considerations

### Mac App Store

**Important**: Apps distributed through the Mac App Store typically **require** sandboxing. Using this plugin will likely prevent App Store distribution unless:

1. **Special Entitlements**: Request special entitlements from Apple for system-level access
2. **Alternative Implementation**: Implement sandbox-compatible alternatives
3. **External Distribution**: Distribute outside the Mac App Store

### Direct Distribution

For apps distributed directly (not through App Store):
- ✅ No sandbox restrictions
- ✅ Full plugin functionality available  
- ✅ No additional approval process required

### Enterprise Distribution

For enterprise/internal distribution:
- ✅ No sandbox restrictions typically required
- ✅ Full system access available
- ⚠️ May require additional security approval processes

## Security Implications

### Risks of Disabling Sandbox

Disabling App Sandbox removes several security protections:

1. **File System Access**: App can access any file the user can access
2. **Network Access**: Unrestricted network communications
3. **System Resources**: Access to system-wide resources and other apps
4. **Process Control**: Ability to control other applications

### Mitigation Strategies

1. **Principle of Least Privilege**: Only use system APIs when necessary
2. **User Consent**: Clearly communicate what system access is required
3. **Input Validation**: Validate all data from system APIs
4. **Error Handling**: Gracefully handle system access failures

## Runtime Permissions

Even with sandbox disabled, some operations may require additional runtime permissions:

### Accessibility Permission

Required for window manipulation features:

```dart
final toolkit = MacosWindowToolkit();
final hasPermission = await toolkit.hasAccessibilityPermission();

if (!hasPermission) {
  await toolkit.requestAccessibilityPermission();
}
```

### Screen Recording Permission

Required for window capture features:

```dart
final hasScreenRecording = await toolkit.hasScreenRecordingPermission();

if (!hasScreenRecording) {
  await toolkit.requestScreenRecordingPermission();
}
```

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   - Verify sandbox is disabled in entitlements
   - Check that entitlements files are correctly formatted
   - Ensure app is rebuilt after entitlements changes

2. **Empty window list**
   - Verify other applications have open windows
   - Check system permissions (especially in macOS Ventura+)
   - Test with example app first

3. **Build failures**
   - Verify entitlements file XML syntax
   - Check Xcode project entitlements settings
   - Clean and rebuild project

### Debug Commands

```bash
# Check current entitlements of built app
codesign -d --entitlements :- /path/to/your/app.app

# Verify sandbox status
spctl -a -t exec -vv /path/to/your/app.app

# Check system permissions
sudo log stream --predicate 'subsystem contains "flutter"'
```

## Best Practices

1. **Development**: Test on multiple macOS versions
2. **Documentation**: Clearly document system requirements to users
3. **Error Handling**: Implement graceful fallbacks for permission issues  
4. **Testing**: Test both with and without required permissions
5. **User Experience**: Provide clear guidance for permission setup

## Related Documentation

- [Getting Started](getting_started.md) - Basic setup and usage
- [Permission Monitoring](permission_monitoring.md) - Managing runtime permissions
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [API Reference](api_reference.md) - Complete API documentation