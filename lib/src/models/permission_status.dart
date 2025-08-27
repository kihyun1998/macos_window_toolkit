/// Represents the current status of macOS permissions
/// 
/// This class provides a type-safe way to handle permission status updates
/// from the permission monitoring system.
class PermissionStatus {
  /// Screen recording permission status
  /// - `true`: Permission granted
  /// - `false`: Permission denied
  /// - `null`: Permission status unknown (error occurred)
  final bool? screenRecording;
  
  /// Accessibility permission status
  /// - `true`: Permission granted
  /// - `false`: Permission denied
  /// - `null`: Permission status unknown (error occurred)
  final bool? accessibility;
  
  /// Whether any permissions have changed since the last check
  final bool hasChanges;
  
  /// When this permission check was performed
  final DateTime timestamp;
  
  /// Creates a new permission status
  const PermissionStatus({
    required this.screenRecording,
    required this.accessibility,
    required this.hasChanges,
    required this.timestamp,
  });
  
  /// Creates a permission status from a map (used internally)
  factory PermissionStatus.fromMap(Map<String, dynamic> map) {
    return PermissionStatus(
      screenRecording: map['screenRecording'] as bool?,
      accessibility: map['accessibility'] as bool?,
      hasChanges: map['hasChanges'] as bool? ?? false,
      timestamp: map['timestamp'] as DateTime? ?? DateTime.now(),
    );
  }
  
  /// Converts this permission status to a map
  Map<String, dynamic> toMap() {
    return {
      'screenRecording': screenRecording,
      'accessibility': accessibility,
      'hasChanges': hasChanges,
      'timestamp': timestamp,
    };
  }
  
  /// Whether all required permissions are granted
  bool get allPermissionsGranted {
    return screenRecording == true && accessibility == true;
  }
  
  /// Whether any permission is denied
  bool get hasAnyDenied {
    return screenRecording == false || accessibility == false;
  }
  
  /// Whether any permission status is unknown (error state)
  bool get hasUnknownStatus {
    return screenRecording == null || accessibility == null;
  }
  
  /// List of permissions that are currently denied
  List<String> get deniedPermissions {
    final denied = <String>[];
    if (screenRecording == false) denied.add('Screen Recording');
    if (accessibility == false) denied.add('Accessibility');
    return denied;
  }
  
  /// List of permissions that are currently granted
  List<String> get grantedPermissions {
    final granted = <String>[];
    if (screenRecording == true) granted.add('Screen Recording');
    if (accessibility == true) granted.add('Accessibility');
    return granted;
  }
  
  /// Creates a copy of this permission status with updated values
  PermissionStatus copyWith({
    bool? screenRecording,
    bool? accessibility,
    bool? hasChanges,
    DateTime? timestamp,
  }) {
    return PermissionStatus(
      screenRecording: screenRecording ?? this.screenRecording,
      accessibility: accessibility ?? this.accessibility,
      hasChanges: hasChanges ?? this.hasChanges,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  String toString() {
    return 'PermissionStatus('
        'screenRecording: $screenRecording, '
        'accessibility: $accessibility, '
        'hasChanges: $hasChanges, '
        'timestamp: $timestamp)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PermissionStatus &&
      other.screenRecording == screenRecording &&
      other.accessibility == accessibility &&
      other.hasChanges == hasChanges &&
      other.timestamp == timestamp;
  }
  
  @override
  int get hashCode {
    return screenRecording.hashCode ^
      accessibility.hashCode ^
      hasChanges.hashCode ^
      timestamp.hashCode;
  }
}