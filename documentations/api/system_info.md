# System Information API

Complete reference for macOS version detection and system capability information.

## Overview

The System Information API provides functionality for detecting macOS version information and understanding system capabilities. This is essential for feature detection, compatibility checks, and optimizing behavior based on available system features like ScreenCaptureKit availability.

## Quick Reference

| Method | Description | Returns |
|--------|-------------|---------|
| [`getMacOSVersionInfo()`](#getmacosversioninfo) | Get macOS version and capabilities | `Future<MacosVersionInfo>` |

## Methods

### `getMacOSVersionInfo()`

Gets comprehensive macOS version information and capability detection.

**Signature:**
```dart
Future<MacosVersionInfo> getMacOSVersionInfo()
```

**Returns:**
- `Future<MacosVersionInfo>` - Complete version information with feature availability

**Throws:**
- Generally does not throw exceptions; returns best-effort information

**Example:**
```dart
final toolkit = MacosWindowToolkit();

final versionInfo = await toolkit.getMacOSVersionInfo();

print('=== macOS Version Information ===');
print('Version: ${versionInfo.versionString}');
print('Major: ${versionInfo.majorVersion}');
print('Minor: ${versionInfo.minorVersion}');
print('Patch: ${versionInfo.patchVersion}');
print('ScreenCaptureKit available: ${versionInfo.isScreenCaptureKitAvailable}');

// Use for feature detection
if (versionInfo.isScreenCaptureKitAvailable) {
  // macOS 12.3+: getCapturableWindows works
  final windows = await toolkit.getCapturableWindows();
  print('Found ${windows.length} capturable windows');
} else {
  print('⚠️ Window capture is unavailable below macOS 12.3');
}

if (versionInfo.majorVersion >= 14) {
  print('✅ captureWindow is available (macOS 14.0+)');
} else {
  print('⚠️ captureWindow needs macOS 14.0; it returns '
      'CaptureFailure(unsupportedVersion) on this system');
}

// Version-specific checks
if (versionInfo.isAtLeast(13)) {
  print('✅ Running on macOS Ventura or later');
  enableAdvancedFeatures();
} else if (versionInfo.isAtLeast(12)) {
  print('✅ Running on macOS Monterey or later');
  enableModernFeatures();
} else {
  print('⚠️ Running on older macOS - some features limited');
  enableCompatibilityMode();
}
```

**Advanced Feature Detection:**
```dart
class FeatureDetector {
  late MacosVersionInfo versionInfo;
  
  Future<void> initialize() async {
    final toolkit = MacosWindowToolkit();
    versionInfo = await toolkit.getMacOSVersionInfo();
    
    print('🔍 Feature Detection Results:');
    print('macOS ${versionInfo.versionString}');
    print('');
    
    _printFeatureAvailability();
  }
  
  void _printFeatureAvailability() {
    final features = <String, bool>{
      'ScreenCaptureKit window list (12.3+)': versionInfo.isScreenCaptureKitAvailable,
      'Window capture (14.0+)': versionInfo.majorVersion >= 14,
      'Screen Recording permissions': versionInfo.isAtLeast(10, 15),
      'Modern privacy controls': versionInfo.isAtLeast(10, 14),
      'Full window capture support': versionInfo.isAtLeast(10, 11),
      'Advanced window properties': versionInfo.isAtLeast(12),
      'Enhanced accessibility API': versionInfo.isAtLeast(11),
    };
    
    features.forEach((feature, available) {
      final icon = available ? '✅' : '❌';
      print('$icon $feature');
    });
    
    print('');
    _printRecommendations();
  }
  
  void _printRecommendations() {
    print('💡 Recommendations:');
    
    if (versionInfo.majorVersion < 14) {
      print('• Update to macOS 14.0+ to capture windows');
    }
    
    if (!versionInfo.isAtLeast(11)) {
      print('• Update to macOS 11+ for enhanced features');
    }
    
    if (versionInfo.isAtLeast(14)) {
      print('• All modern features available');
    }
  }
  
  // Feature check methods
  bool get canListCapturableWindows => versionInfo.isScreenCaptureKitAvailable;
  bool get canCaptureWindows => versionInfo.majorVersion >= 14;
  bool get requiresPermissions => versionInfo.isAtLeast(10, 15);
  bool get supportsAdvancedWindowProps => versionInfo.isAtLeast(12);
  bool get supportsModernPrivacy => versionInfo.isAtLeast(10, 14);
}

// Usage
final detector = FeatureDetector();
await detector.initialize();

if (detector.canCaptureWindows) {
  // captureWindow is available
} else {
  // Capture is unavailable on this system; there is no fallback method.
  // Hide or disable capture features.
}
```

**Conditional UI Based on Version:**
```dart
class VersionAwareWidget extends StatefulWidget {
  @override
  _VersionAwareWidgetState createState() => _VersionAwareWidgetState();
}

class _VersionAwareWidgetState extends State<VersionAwareWidget> {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  MacosVersionInfo? versionInfo;
  
  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }
  
  Future<void> _loadVersionInfo() async {
    final info = await toolkit.getMacOSVersionInfo();
    setState(() => versionInfo = info);
  }
  
  @override
  Widget build(BuildContext context) {
    final info = versionInfo;
    if (info == null) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Always available features
        ElevatedButton(
          onPressed: () => _getAllWindows(),
          child: Text('Get All Windows'),
        ),
        
        // Capture needs macOS 14.0+
        if (info.majorVersion >= 14) ...[
          ElevatedButton(
            onPressed: () => _captureFirstWindow(),
            child: Text('Capture Window'),
          ),
          Chip(
            label: Text('Capture Available'),
            backgroundColor: Colors.green,
          ),
        ] else ...[
          Chip(
            label: Text('Capture unavailable (needs macOS 14.0+)'),
            backgroundColor: Colors.orange,
          ),
        ],
        
        // Version-specific features
        if (info.isAtLeast(13)) ...[
          ElevatedButton(
            onPressed: () => _useVenturaFeatures(),
            child: Text('Ventura+ Features'),
          ),
        ],
        
        // System information display
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Information', 
                     style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Text('macOS ${info.versionString}'),
                Text('Build: ${info.majorVersion}.${info.minorVersion}.${info.patchVersion}'),
                Text('ScreenCaptureKit: ${info.isScreenCaptureKitAvailable ? 'Available' : 'Not available'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Feature implementations based on version
  Future<void> _getAllWindows() async {
    // Always available
    final windows = await toolkit.getAllWindows();
    print('Found ${windows.length} windows');
  }
  
  Future<void> _captureFirstWindow() async {
    final windows = await toolkit.getCapturableWindows();
    if (windows.isEmpty) return;

    final result = await toolkit.captureWindow(windows.first.windowId);
    switch (result) {
      case CaptureSuccess(imageData: final data):
        print('Captured ${data.length} bytes of PNG');
      case CaptureFailure(reason: final reason, message: final message):
        print('Capture failed: $reason ${message ?? ''}');
    }
  }
  
  void _useVenturaFeatures() {
    // Ventura+ specific features
    print('Using macOS 13+ features');
  }
}
```

---

## MacosVersionInfo Data Model

Complete macOS version information with capability detection.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `majorVersion` | `int` | Major version number (e.g., 13 for macOS Ventura) |
| `minorVersion` | `int` | Minor version number (e.g., 0 for 13.0) |
| `patchVersion` | `int` | Patch version number (e.g., 1 for 13.0.1) |
| `versionString` | `String` | Full version string (e.g., "13.0.1") |
| `isScreenCaptureKitAvailable` | `bool` | Whether ScreenCaptureKit is available (macOS 12.3+) |

### Constructor

```dart
const MacosVersionInfo({
  required this.majorVersion,
  required this.minorVersion,
  required this.patchVersion,
  required this.versionString,
  required this.isScreenCaptureKitAvailable,
});
```

### Methods

#### `isAtLeast()`

Checks if the current macOS version is at least the specified version.

**Signature:**
```dart
bool isAtLeast(int major, [int minor = 0, int patch = 0])
```

**Parameters:**
- `major` - Required major version number
- `minor` (optional) - Minor version number. Defaults to 0.
- `patch` (optional) - Patch version number. Defaults to 0.

**Returns:**
- `bool` - `true` if current version is greater than or equal to specified version

**Example:**
```dart
final versionInfo = await toolkit.getMacOSVersionInfo();

// Check major version only
if (versionInfo.isAtLeast(13)) {
  print('Running macOS Ventura or later');
}

// Check major and minor version
if (versionInfo.isAtLeast(12, 3)) {
  print('ScreenCaptureKit should be available');
}

// Check full version
if (versionInfo.isAtLeast(13, 4, 1)) {
  print('Running macOS 13.4.1 or later');
}

// Common version checks
final versionChecks = {
  'Big Sur (11.0+)': versionInfo.isAtLeast(11),
  'Monterey (12.0+)': versionInfo.isAtLeast(12),
  'Monterey 12.3+ (ScreenCaptureKit)': versionInfo.isAtLeast(12, 3),
  'Ventura (13.0+)': versionInfo.isAtLeast(13),
  'Sonoma (14.0+)': versionInfo.isAtLeast(14),
};

versionChecks.forEach((name, supported) {
  final icon = supported ? '✅' : '❌';
  print('$icon $name');
});
```

### Usage Examples

```dart
final versionInfo = await toolkit.getMacOSVersionInfo();

// Basic information
print('macOS ${versionInfo.versionString}');
print('Components: ${versionInfo.majorVersion}.${versionInfo.minorVersion}.${versionInfo.patchVersion}');

// Feature detection
if (versionInfo.majorVersion >= 14) {
  print('✅ Window capture available');
} else if (versionInfo.isScreenCaptureKitAvailable) {
  print('⚠️ getCapturableWindows works, but captureWindow needs macOS 14.0+');
} else {
  print('⚠️ Window capture is unavailable below macOS 12.3');
}

// Version-specific logic
switch (versionInfo.majorVersion) {
  case 14:
    print('macOS Sonoma - all features available');
    enableAllFeatures();
    break;
  case 13:
    print('macOS Ventura - most features available');
    enableModernFeatures();
    break;
  case 12:
    print('macOS Monterey');
    if (versionInfo.isAtLeast(12, 3)) {
      print('ScreenCaptureKit available: capturable window list only');
      enableWindowList();
    } else {
      print('Update to 12.3+ for the capturable window list');
      disableCaptureFeatures();
    }
    break;
  case 11:
    print('macOS Big Sur - basic features only');
    enableBasicFeatures();
    break;
  default:
    if (versionInfo.majorVersion < 11) {
      print('Very old macOS - limited compatibility');
      enableMinimalFeatures();
    } else {
      print('Newer macOS version detected');
      enableAllFeatures();
    }
}

// Comparison examples
if (versionInfo.isAtLeast(13, 0, 0) && !versionInfo.isAtLeast(14, 0, 0)) {
  print('Running specifically on macOS 13.x');
}

// Range checks
bool isModernMacOS = versionInfo.isAtLeast(12);
bool isVeryNew = versionInfo.isAtLeast(14);
bool needsUpdate = !versionInfo.isAtLeast(11);

print('Modern macOS: $isModernMacOS');
print('Very new macOS: $isVeryNew');
print('Needs update: $needsUpdate');
```

## Complete Usage Examples

### System Compatibility Checker

```dart
class SystemCompatibilityChecker {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<CompatibilityReport> checkCompatibility() async {
    final versionInfo = await toolkit.getMacOSVersionInfo();
    
    return CompatibilityReport(versionInfo: versionInfo);
  }
  
  Future<void> printFullReport() async {
    final report = await checkCompatibility();
    
    print('='.padRight(50, '='));
    print('SYSTEM COMPATIBILITY REPORT');
    print('='.padRight(50, '='));
    print('');
    
    // Version Information
    print('🖥️  SYSTEM VERSION');
    print('   macOS ${report.versionInfo.versionString}');
    print('   Build: ${report.versionInfo.majorVersion}.${report.versionInfo.minorVersion}.${report.versionInfo.patchVersion}');
    print('');
    
    // Feature Availability
    print('⚡ FEATURE AVAILABILITY');
    final features = _getFeatureAvailability(report.versionInfo);
    features.forEach((feature, status) {
      final icon = status.isSupported ? '✅' : '❌';
      print('   $icon ${feature.padRight(35)} ${status.description}');
    });
    print('');
    
    // Capture Capabilities
    print('📸 CAPTURE CAPABILITIES');
    print('   Capturable window list (12.3+): ${report.versionInfo.isScreenCaptureKitAvailable ? 'Available' : 'Unavailable'}');
    print('   Window capture (14.0+): ${_getCaptureStatus(report.versionInfo)}');
    print('');
    
    // Recommendations
    print('💡 RECOMMENDATIONS');
    final recommendations = _getRecommendations(report);
    if (recommendations.isEmpty) {
      print('   ✅ System is fully compatible - no actions needed');
    } else {
      recommendations.forEach((rec) => print('   • $rec'));
    }
    print('');
    
    // Overall Score
    final score = _calculateCompatibilityScore(report);
    print('📊 COMPATIBILITY SCORE: ${score.score}/100 (${score.grade})');
    print('='.padRight(50, '='));
  }
  
  Map<String, FeatureStatus> _getFeatureAvailability(MacosVersionInfo version) {
    return {
      'Basic Window Management': FeatureStatus(true, 'Fully supported'),
      'Screen Recording Permissions': FeatureStatus(
        version.isAtLeast(10, 15),
        version.isAtLeast(10, 15) ? 'Required and supported' : 'Not required on this version',
      ),
      'Capturable Window List': FeatureStatus(
        version.isScreenCaptureKitAvailable,
        version.isScreenCaptureKitAvailable ? 'Available' : 'Requires macOS 12.3+',
      ),
      'Window Capture': FeatureStatus(
        version.majorVersion >= 14,
        version.majorVersion >= 14 ? 'Available' : 'Requires macOS 14.0+',
      ),
      'Advanced Window Properties': FeatureStatus(
        version.isAtLeast(12),
        version.isAtLeast(12) ? 'Available' : 'Limited on older versions',
      ),
      'Modern Privacy Controls': FeatureStatus(
        version.isAtLeast(10, 14),
        version.isAtLeast(10, 14) ? 'Available' : 'Basic permissions only',
      ),
      'Process Management': FeatureStatus(true, 'Fully supported'),
      'Real-time Permission Monitoring': FeatureStatus(true, 'Fully supported'),
    };
  }
  
  String _getCaptureStatus(MacosVersionInfo version) {
    if (version.majorVersion >= 14) {
      return 'Available';
    } else {
      return 'Unavailable (captureWindow returns unsupportedVersion)';
    }
  }
  
  List<String> _getRecommendations(CompatibilityReport report) {
    final recommendations = <String>[];
    
    if (!report.versionInfo.isAtLeast(11)) {
      recommendations.add('Update to macOS 11+ for modern features');
    }
    
    if (report.versionInfo.majorVersion < 14) {
      recommendations.add('Update to macOS 14.0+ to capture windows');
    }
    
    if (!report.versionInfo.isAtLeast(10, 15)) {
      recommendations.add('Consider updating for better privacy controls');
    }
    
    return recommendations;
  }
  
  CompatibilityScore _calculateCompatibilityScore(CompatibilityReport report) {
    int score = 0;
    
    // Base compatibility (always have basic features)
    score += 40;
    
    // Modern macOS bonus
    if (report.versionInfo.isAtLeast(12)) score += 20;
    if (report.versionInfo.isAtLeast(13)) score += 10;
    if (report.versionInfo.isAtLeast(14)) score += 5;
    
    // ScreenCaptureKit support
    if (report.versionInfo.isScreenCaptureKitAvailable) score += 20;
    
    // Modern privacy features
    if (report.versionInfo.isAtLeast(10, 15)) score += 5;
    
    String grade;
    if (score >= 95) {
      grade = 'Excellent';
    } else if (score >= 85) {
      grade = 'Very Good';
    } else if (score >= 75) {
      grade = 'Good';
    } else if (score >= 65) {
      grade = 'Fair';
    } else {
      grade = 'Limited';
    }
    
    return CompatibilityScore(score, grade);
  }
}

class CompatibilityReport {
  final MacosVersionInfo versionInfo;
  
  CompatibilityReport({required this.versionInfo});
}

class FeatureStatus {
  final bool isSupported;
  final String description;
  
  FeatureStatus(this.isSupported, this.description);
}

class CompatibilityScore {
  final int score;
  final String grade;
  
  CompatibilityScore(this.score, this.grade);
}

// Usage
final checker = SystemCompatibilityChecker();
await checker.printFullReport();
```

### Version-Aware Application Launcher

```dart
class VersionAwareApp {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  late MacosVersionInfo versionInfo;
  
  Future<void> launch() async {
    print('🚀 Launching macOS Window Toolkit Application...');
    
    // Get system information
    await _initializeSystemInfo();
    
    // Configure based on capabilities
    await _configureForSystem();
    
    // Launch appropriate interface
    await _launchInterface();
  }
  
  Future<void> _initializeSystemInfo() async {
    print('📋 Detecting system capabilities...');
    
    versionInfo = await toolkit.getMacOSVersionInfo();
    
    print('✅ System: macOS ${versionInfo.versionString}');
    print('${versionInfo.majorVersion >= 14 ? '✅' : '⚠️'} Window capture: '
        '${versionInfo.majorVersion >= 14 ? 'available' : 'unavailable (needs macOS 14.0+)'}');
  }
  
  Future<void> _configureForSystem() async {
    print('⚙️  Configuring for system capabilities...');
    
    if (versionInfo.majorVersion >= 14) {
      print('   • Enabling window capture');
      AppConfig.enableCapture = true;
    } else {
      print('   • Window capture unavailable; hiding capture features');
      AppConfig.enableCapture = false;
    }
    
    if (versionInfo.isAtLeast(10, 15)) {
      print('   • Enabling permission monitoring');
      AppConfig.enablePermissionMonitoring = true;
    } else {
      print('   • Simplified permission handling');
      AppConfig.enablePermissionMonitoring = false;
    }
    
    if (versionInfo.isAtLeast(12)) {
      print('   • Advanced window properties available');
      AppConfig.showAdvancedProperties = true;
    } else {
      print('   • Basic window properties only');
      AppConfig.showAdvancedProperties = false;
    }
  }
  
  Future<void> _launchInterface() async {
    print('🎯 Launching interface...');
    
    if (versionInfo.isAtLeast(13)) {
      print('   • Modern UI with all features');
      await _launchModernInterface();
    } else if (versionInfo.isAtLeast(11)) {
      print('   • Standard UI with core features');
      await _launchStandardInterface();
    } else {
      print('   • Simplified UI for older systems');
      await _launchSimplifiedInterface();
    }
  }
  
  Future<void> _launchModernInterface() async {
    // Full-featured interface
    print('🎨 Modern interface loaded');
    // runApp(ModernWindowToolkitApp());
  }
  
  Future<void> _launchStandardInterface() async {
    // Standard interface
    print('🎨 Standard interface loaded');
    // runApp(StandardWindowToolkitApp());
  }
  
  Future<void> _launchSimplifiedInterface() async {
    // Simplified interface for older systems
    print('🎨 Simplified interface loaded');
    // runApp(SimplifiedWindowToolkitApp());
  }
}

class AppConfig {
  static bool enableCapture = false;
  static bool enablePermissionMonitoring = false;
  static bool showAdvancedProperties = false;
}

// Usage
final app = VersionAwareApp();
await app.launch();
```

## Best Practices

### Feature Detection Pattern

```dart
// ✅ Good: Use version detection for feature availability
final versionInfo = await toolkit.getMacOSVersionInfo();

if (versionInfo.isScreenCaptureKitAvailable) {
  // macOS 12.3+
  final windows = await toolkit.getCapturableWindows();
} else {
  // No fallback method exists: tell the user capture is unavailable
  print('Window capture is unavailable below macOS 12.3');
}

// ❌ Avoid: Assuming features are available
// final windows = await toolkit.getCapturableWindows();
// // Throws PlatformException (UNSUPPORTED_MACOS_VERSION) below macOS 12.3
```

### Graceful Degradation

```dart
class FeatureManager {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  late MacosVersionInfo versionInfo;
  
  Future<void> initialize() async {
    versionInfo = await toolkit.getMacOSVersionInfo();
  }
  
  bool get canCapture => versionInfo.majorVersion >= 14;

  Future<List<CapturableWindowInfo>> getWindows() async {
    // getCapturableWindows needs macOS 12.3+; there is no fallback method
    if (!versionInfo.isScreenCaptureKitAvailable) {
      return const [];
    }
    return await toolkit.getCapturableWindows();
  }
  
  Future<Uint8List?> captureWindow(int windowId) async {
    // Below macOS 14.0 captureWindow returns
    // CaptureFailure(unsupportedVersion); hide capture features instead
    if (!canCapture) return null;

    final result = await toolkit.captureWindow(windowId);
    switch (result) {
      case CaptureSuccess(imageData: final data):
        return data;
      case CaptureFailure(reason: final reason):
        print('Capture failed: $reason');
        return null;
    }
  }
}
```

### User Communication

```dart
void showSystemStatus(MacosVersionInfo versionInfo) {
  final messages = <String>[];
  
  if (versionInfo.isAtLeast(14)) {
    messages.add('✅ Your system supports all features');
  } else if (versionInfo.isAtLeast(12, 3)) {
    messages.add('⚠️ Update to macOS 14.0+ to capture windows');
  } else if (versionInfo.isAtLeast(11)) {
    messages.add('⚠️ Window capture needs macOS 14.0+');
  } else {
    messages.add('⚠️ Your macOS version has limited feature support');
    messages.add('Consider updating to macOS 12+ for the best experience');
  }
  
  messages.forEach(print);
}
```

## Thread Safety

All system information methods are thread-safe and can be called from any isolate.

## Performance Notes

- System information calls are very fast (~1-2ms)
- Results can be cached safely as they don't change during app lifetime
- Version checks using `isAtLeast()` are extremely fast (simple integer comparisons)

## Related APIs

- **[Window Capture](window_capture.md)** - Capture needs macOS 14.0; the capturable window list needs 12.3
- **[Permission Management](permission_management.md)** - Permission requirements vary by version
- **[Error Handling](error_handling.md)** - Version-specific error handling

---

[← Back to API Reference](../api_reference.md)