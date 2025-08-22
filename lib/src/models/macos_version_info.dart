/// Information about the macOS version and capabilities
class MacosVersionInfo {
  /// Major version number (e.g., 13 for macOS Ventura)
  final int majorVersion;
  
  /// Minor version number (e.g., 0 for 13.0)
  final int minorVersion;
  
  /// Patch version number (e.g., 1 for 13.0.1)
  final int patchVersion;
  
  /// Full version string (e.g., "13.0.1")
  final String versionString;
  
  /// Whether ScreenCaptureKit is available (macOS 12.3+)
  final bool isScreenCaptureKitAvailable;

  const MacosVersionInfo({
    required this.majorVersion,
    required this.minorVersion,
    required this.patchVersion,
    required this.versionString,
    required this.isScreenCaptureKitAvailable,
  });

  /// Creates a [MacosVersionInfo] from a map representation
  factory MacosVersionInfo.fromMap(Map<String, dynamic> map) {
    return MacosVersionInfo(
      majorVersion: map['majorVersion'] as int? ?? 0,
      minorVersion: map['minorVersion'] as int? ?? 0,
      patchVersion: map['patchVersion'] as int? ?? 0,
      versionString: map['versionString'] as String? ?? '',
      isScreenCaptureKitAvailable: map['isScreenCaptureKitAvailable'] as bool? ?? false,
    );
  }

  /// Converts this [MacosVersionInfo] to a map representation
  Map<String, dynamic> toMap() {
    return {
      'majorVersion': majorVersion,
      'minorVersion': minorVersion,
      'patchVersion': patchVersion,
      'versionString': versionString,
      'isScreenCaptureKitAvailable': isScreenCaptureKitAvailable,
    };
  }

  /// Checks if the current macOS version is at least the specified version
  bool isAtLeast(int major, [int minor = 0, int patch = 0]) {
    if (majorVersion > major) return true;
    if (majorVersion < major) return false;
    
    if (minorVersion > minor) return true;
    if (minorVersion < minor) return false;
    
    return patchVersion >= patch;
  }

  @override
  String toString() {
    return 'MacosVersionInfo(version: $versionString, screenCaptureKit: $isScreenCaptureKitAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MacosVersionInfo &&
        other.majorVersion == majorVersion &&
        other.minorVersion == minorVersion &&
        other.patchVersion == patchVersion &&
        other.versionString == versionString &&
        other.isScreenCaptureKitAvailable == isScreenCaptureKitAvailable;
  }

  @override
  int get hashCode {
    return majorVersion.hashCode ^
        minorVersion.hashCode ^
        patchVersion.hashCode ^
        versionString.hashCode ^
        isScreenCaptureKitAvailable.hashCode;
  }
}