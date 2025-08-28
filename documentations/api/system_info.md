# System Information API

Complete reference for macOS version detection and system capability information.

## Overview

The System Information API provides functionality for detecting macOS version information and understanding system capabilities. This is essential for feature detection, compatibility checks, and optimizing behavior based on available system features like ScreenCaptureKit availability.

## Quick Reference

| Method | Description | Returns |
|--------|-------------|---------|
| [`getMacOSVersionInfo()`](#getmacosversioninfo) | Get macOS version and capabilities | `Future<MacosVersionInfo>` |
| [`getCaptureMethodInfo()`](#getcapturemethodinfo) | Get current capture method info | `Future<Map<String, dynamic>>` |

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
  print('✅ Can use high-quality ScreenCaptureKit capture');
  final windows = await toolkit.getCapturableWindows();
  // Use modern capture methods
} else {
  print('⚠️ Using legacy capture methods for compatibility');
  final windows = await toolkit.getCapturableWindowsLegacy();
  // Use legacy methods
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
      'ScreenCaptureKit (High-quality capture)': versionInfo.isScreenCaptureKitAvailable,
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
    
    if (!versionInfo.isScreenCaptureKitAvailable) {
      print('• Update to macOS 12.3+ for better capture quality');
    }
    
    if (!versionInfo.isAtLeast(11)) {
      print('• Update to macOS 11+ for enhanced features');
    }
    
    if (versionInfo.isAtLeast(14)) {
      print('• All modern features available');
    }
  }
  
  // Feature check methods
  bool get canUseScreenCaptureKit => versionInfo.isScreenCaptureKitAvailable;
  bool get requiresPermissions => versionInfo.isAtLeast(10, 15);
  bool get supportsAdvancedWindowProps => versionInfo.isAtLeast(12);
  bool get supportsModernPrivacy => versionInfo.isAtLeast(10, 14);
}

// Usage
final detector = FeatureDetector();
await detector.initialize();

if (detector.canUseScreenCaptureKit) {
  // Use modern capture methods
} else {
  // Fall back to legacy methods
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
        
        // Modern features
        if (info.isScreenCaptureKitAvailable) ...[
          ElevatedButton(
            onPressed: () => _useScreenCaptureKit(),
            child: Text('High-Quality Capture'),
          ),
          Chip(
            label: Text('ScreenCaptureKit Available'),
            backgroundColor: Colors.green,
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () => _useLegacyCapture(),
            child: Text('Legacy Capture'),
          ),
          Chip(
            label: Text('Legacy Mode'),
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
  
  Future<void> _useScreenCaptureKit() async {
    // Modern method
    final windows = await toolkit.getCapturableWindows();
    if (windows.isNotEmpty) {
      final result = await toolkit.captureWindow(windows.first.windowId);
      // Handle modern capture result
    }
  }
  
  Future<void> _useLegacyCapture() async {
    // Legacy method
    final windows = await toolkit.getCapturableWindowsLegacy();
    if (windows.isNotEmpty) {
      final result = await toolkit.captureWindowLegacy(windows.first.windowId);
      // Handle legacy capture result
    }
  }
  
  void _useVenturaFeatures() {
    // Ventura+ specific features
    print('Using macOS 13+ features');
  }
}
```

---

### `getCaptureMethodInfo()`

Gets detailed information about capture capabilities and methods on the current system.

**Signature:**
```dart
Future<Map<String, dynamic>> getCaptureMethodInfo()
```

**Returns:**
- `Future<Map<String, dynamic>>` - Detailed capture method information

**Returned Fields:**
- `captureMethod` (`String`) - Method used by auto-selection ("ScreenCaptureKit" or "CGWindowListCreateImage")
- `windowListMethod` (`String`) - Window listing method ("ScreenCaptureKit" or "CGWindowListCopyWindowInfo")
- `macOSVersion` (`String`) - Current macOS version string
- `isScreenCaptureKitAvailable` (`bool`) - Whether ScreenCaptureKit framework is available
- `supportsModernCapture` (`bool`) - Whether modern capture methods are supported
- `supportsModernWindowList` (`bool`) - Whether modern window listing is supported

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

// Show user-friendly messages
_showCapabilityMessage(info);

// Use for debugging
_debugCaptureIssues(info);

void _showCapabilityMessage(Map<String, dynamic> info) {
  if (info['supportsModernCapture'] == true) {
    print('✅ Using high-quality ScreenCaptureKit for window capture');
    print('   - Better color accuracy');
    print('   - Improved performance');
    print('   - Enhanced window detection');
  } else {
    print('⚠️ Using compatible CGWindowListCreateImage for window capture');
    print('   - Broader macOS compatibility');
    print('   - May have lower performance on large windows');
    print('   - Consider updating to macOS 12.3+ for improved quality');
  }
  
  if (info['supportsModernWindowList'] == true) {
    print('✅ Using ScreenCaptureKit for window discovery');
    print('   - More accurate window information');
    print('   - Application bundle identifiers available');
  } else {
    print('⚠️ Using CGWindowListCopyWindowInfo for window discovery');
    print('   - Compatible with all macOS versions');
    print('   - Bundle identifiers not available');
  }
}

void _debugCaptureIssues(Map<String, dynamic> info) {
  print('');
  print('🔧 Debug Information:');
  print('If you experience capture issues:');
  
  if (info['isScreenCaptureKitAvailable'] == false) {
    print('• ScreenCaptureKit not available - update to macOS 12.3+');
  }
  
  if (info['captureMethod'] == 'CGWindowListCreateImage') {
    print('• Using legacy capture method');
    print('  - Ensure screen recording permission is granted');
    print('  - Performance may vary with window size');
  }
  
  print('• Current system: ${info['macOSVersion']}');
  print('• For best experience, use macOS 14.0+');
}
```

**Performance Optimization Based on Capabilities:**
```dart
class CaptureOptimizer {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  late Map<String, dynamic> captureInfo;
  
  Future<void> initialize() async {
    captureInfo = await toolkit.getCaptureMethodInfo();
    _optimizeForSystem();
  }
  
  void _optimizeForSystem() {
    final isModern = captureInfo['supportsModernCapture'] == true;
    
    if (isModern) {
      print('🚀 Optimizing for ScreenCaptureKit');
      _enableHighQualityMode();
    } else {
      print('⚡ Optimizing for legacy compatibility');
      _enableCompatibilityMode();
    }
  }
  
  void _enableHighQualityMode() {
    // Use ScreenCaptureKit features
    print('• High-quality capture enabled');
    print('• Advanced window filtering available');
    print('• Bundle identifier support enabled');
  }
  
  void _enableCompatibilityMode() {
    // Optimize for legacy systems
    print('• Compatibility mode enabled');
    print('• Basic window filtering only');
    print('• Reduced capture frequency for performance');
  }
  
  Future<List<CapturableWindowInfo>> getOptimalWindowList() async {
    if (captureInfo['supportsModernWindowList'] == true) {
      return await toolkit.getCapturableWindows();
    } else {
      return await toolkit.getCapturableWindowsLegacy();
    }
  }
  
  Future<CaptureResult> captureOptimally(int windowId) async {
    if (captureInfo['supportsModernCapture'] == true) {
      return await toolkit.captureWindow(windowId);
    } else {
      // Use legacy method with optimizations
      return await toolkit.captureWindowLegacy(windowId);
    }
  }
}
```

**System Capability Dashboard:**
```dart
Widget buildCapabilityDashboard(Map<String, dynamic> info) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Capabilities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          
          // macOS Version
          _buildInfoRow(
            'macOS Version',
            info['macOSVersion'] as String,
            Colors.blue,
          ),
          
          // Capture Method
          _buildInfoRow(
            'Capture Method',
            info['captureMethod'] as String,
            info['supportsModernCapture'] == true ? Colors.green : Colors.orange,
          ),
          
          // Window List Method
          _buildInfoRow(
            'Window Discovery',
            info['windowListMethod'] as String,
            info['supportsModernWindowList'] == true ? Colors.green : Colors.orange,
          ),
          
          // ScreenCaptureKit Availability
          _buildInfoRow(
            'ScreenCaptureKit',
            info['isScreenCaptureKitAvailable'] == true ? 'Available' : 'Not Available',
            info['isScreenCaptureKitAvailable'] == true ? Colors.green : Colors.red,
          ),
          
          SizedBox(height: 12),
          
          // Recommendations
          if (info['supportsModernCapture'] != true) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Update to macOS 12.3+ for enhanced capture quality',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildInfoRow(String label, String value, Color color) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
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
if (versionInfo.isScreenCaptureKitAvailable) {
  print('✅ Can use ScreenCaptureKit for high-quality capture');
} else {
  print('⚠️ ScreenCaptureKit not available, using legacy methods');
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
      print('ScreenCaptureKit available');
      enableScreenCaptureKit();
    } else {
      print('Update to 12.3+ for ScreenCaptureKit');
      enableLegacyMode();
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
    final captureInfo = await toolkit.getCaptureMethodInfo();
    
    return CompatibilityReport(
      versionInfo: versionInfo,
      captureInfo: captureInfo,
    );
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
    print('   Method: ${report.captureInfo['captureMethod']}');
    print('   Window Discovery: ${report.captureInfo['windowListMethod']}');
    print('   Quality: ${_getCaptureQuality(report.captureInfo)}');
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
      'ScreenCaptureKit (High Quality)': FeatureStatus(
        version.isScreenCaptureKitAvailable,
        version.isScreenCaptureKitAvailable ? 'Available' : 'Requires macOS 12.3+',
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
  
  String _getCaptureQuality(Map<String, dynamic> info) {
    if (info['supportsModernCapture'] == true) {
      return 'High (ScreenCaptureKit)';
    } else {
      return 'Standard (Legacy method)';
    }
  }
  
  List<String> _getRecommendations(CompatibilityReport report) {
    final recommendations = <String>[];
    
    if (!report.versionInfo.isAtLeast(12, 3)) {
      recommendations.add('Update to macOS 12.3+ for ScreenCaptureKit support');
    }
    
    if (!report.versionInfo.isAtLeast(11)) {
      recommendations.add('Update to macOS 11+ for modern features');
    }
    
    if (report.captureInfo['supportsModernCapture'] != true) {
      recommendations.add('Some capture operations may be slower than optimal');
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
  final Map<String, dynamic> captureInfo;
  
  CompatibilityReport({
    required this.versionInfo,
    required this.captureInfo,
  });
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
  late Map<String, dynamic> captureInfo;
  
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
    captureInfo = await toolkit.getCaptureMethodInfo();
    
    print('✅ System: macOS ${versionInfo.versionString}');
    print('✅ Capture: ${captureInfo['captureMethod']}');
  }
  
  Future<void> _configureForSystem() async {
    print('⚙️  Configuring for system capabilities...');
    
    if (versionInfo.isScreenCaptureKitAvailable) {
      print('   • Enabling high-quality capture mode');
      AppConfig.enableHighQualityCapture = true;
    } else {
      print('   • Using legacy capture mode for compatibility');
      AppConfig.enableHighQualityCapture = false;
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
  static bool enableHighQualityCapture = false;
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
  // Use modern features
  final windows = await toolkit.getCapturableWindows();
} else {
  // Fall back to legacy
  final windows = await toolkit.getCapturableWindowsLegacy();
}

// ❌ Avoid: Assuming features are available
// final windows = await toolkit.getCapturableWindows(); // May fail on old macOS
```

### Graceful Degradation

```dart
class FeatureManager {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  late MacosVersionInfo versionInfo;
  
  Future<void> initialize() async {
    versionInfo = await toolkit.getMacOSVersionInfo();
  }
  
  Future<List<CapturableWindowInfo>> getWindows() async {
    // Try modern method first, fall back gracefully
    if (versionInfo.isScreenCaptureKitAvailable) {
      try {
        return await toolkit.getCapturableWindows();
      } catch (e) {
        print('Modern method failed, falling back to legacy');
      }
    }
    
    return await toolkit.getCapturableWindowsLegacy();
  }
  
  Future<CaptureResult> captureWindow(int windowId) async {
    // Auto-select best method
    return await toolkit.captureWindowAuto(windowId);
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
    messages.add('✅ Your system supports high-quality capture');
  } else if (versionInfo.isAtLeast(11)) {
    messages.add('⚠️ Update to macOS 12.3+ for enhanced capture quality');
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

- **[Window Capture](window_capture.md)** - Uses system info for method selection
- **[Permission Management](permission_management.md)** - Permission requirements vary by version
- **[Error Handling](error_handling.md)** - Version-specific error handling

---

[← Back to API Reference](../api_reference.md)