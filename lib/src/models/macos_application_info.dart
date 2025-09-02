/// Represents information about a macOS application
class MacosApplicationInfo {
  /// Application display name
  final String name;

  /// Bundle identifier (e.g., "com.apple.Safari")
  final String bundleId;

  /// Application version string
  final String version;

  /// Full path to the application bundle
  final String path;

  /// Path to the application icon file
  final String iconPath;

  const MacosApplicationInfo({
    required this.name,
    required this.bundleId,
    required this.version,
    required this.path,
    required this.iconPath,
  });

  /// Creates a MacosApplicationInfo from a map returned by the native platform
  factory MacosApplicationInfo.fromMap(Map<String, dynamic> map) {
    return MacosApplicationInfo(
      name: map['name'] as String? ?? '',
      bundleId: map['bundleId'] as String? ?? '',
      version: map['version'] as String? ?? '',
      path: map['path'] as String? ?? '',
      iconPath: map['iconPath'] as String? ?? '',
    );
  }

  /// Converts the MacosApplicationInfo to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bundleId': bundleId,
      'version': version,
      'path': path,
      'iconPath': iconPath,
    };
  }

  @override
  String toString() {
    return 'MacosApplicationInfo('
        'name: $name, '
        'bundleId: $bundleId, '
        'version: $version, '
        'path: $path, '
        'iconPath: $iconPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MacosApplicationInfo &&
        other.name == name &&
        other.bundleId == bundleId &&
        other.version == version &&
        other.path == path &&
        other.iconPath == iconPath;
  }

  @override
  int get hashCode {
    return Object.hash(name, bundleId, version, path, iconPath);
  }
}

/// Result type for application operations
sealed class ApplicationResult {
  const ApplicationResult();
}

/// Successful application retrieval
class ApplicationSuccess extends ApplicationResult {
  final List<MacosApplicationInfo> applications;

  const ApplicationSuccess(this.applications);
}

/// Application retrieval failed
class ApplicationFailure extends ApplicationResult {
  final ApplicationFailureReason reason;
  final String? message;
  final String? details;

  const ApplicationFailure({required this.reason, this.message, this.details});

  String get userMessage {
    switch (reason) {
      case ApplicationFailureReason.permissionDenied:
        return 'Permission denied to access application information';
      case ApplicationFailureReason.systemError:
        return 'System error while retrieving applications';
      case ApplicationFailureReason.notFound:
        return 'No applications found matching the criteria';
      case ApplicationFailureReason.unknown:
        return message ?? 'Unable to retrieve application information';
    }
  }

  /// Whether this failure can be retried
  bool get canRetry {
    switch (reason) {
      case ApplicationFailureReason.permissionDenied:
      case ApplicationFailureReason.systemError:
        return true;
      case ApplicationFailureReason.notFound:
      case ApplicationFailureReason.unknown:
        return false;
    }
  }

  /// Suggested user action for this failure
  String? get suggestedAction {
    switch (reason) {
      case ApplicationFailureReason.permissionDenied:
        return 'Grant necessary permissions in System Settings';
      case ApplicationFailureReason.systemError:
        return 'Try again or restart the application';
      case ApplicationFailureReason.notFound:
        return 'Try a different search term or check application name';
      case ApplicationFailureReason.unknown:
        return null;
    }
  }
}

/// Reasons for application retrieval failure
enum ApplicationFailureReason {
  /// Permission denied to access application information
  permissionDenied,

  /// System error occurred during application scanning
  systemError,

  /// No applications found matching the criteria
  notFound,

  /// Unknown failure reason
  unknown,
}
