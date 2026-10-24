/// Information about a window that can be captured using ScreenCaptureKit
class CapturableWindowInfo {
  /// Unique identifier for the window
  final int windowId;

  /// Window title/name
  final String title;

  /// Name of the application that owns the window
  final String ownerName;

  /// Application bundle identifier
  final String bundleIdentifier;

  /// Window frame (position and size)
  final CapturableWindowFrame frame;

  /// Whether the window is currently visible on screen
  final bool isOnScreen;

  const CapturableWindowInfo({
    required this.windowId,
    required this.title,
    required this.ownerName,
    required this.bundleIdentifier,
    required this.frame,
    required this.isOnScreen,
  });

  /// Creates a [CapturableWindowInfo] from a map representation
  factory CapturableWindowInfo.fromMap(Map<String, dynamic> map) {
    return CapturableWindowInfo(
      windowId: (map['windowId'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      bundleIdentifier: map['bundleIdentifier'] as String? ?? '',
      frame: CapturableWindowFrame.fromMap(
          Map<String, dynamic>.from(map['frame'] as Map? ?? const {})),
      isOnScreen: map['isOnScreen'] as bool? ?? false,
    );
  }

  /// Converts this [CapturableWindowInfo] to a map representation
  Map<String, dynamic> toMap() {
    return {
      'windowId': windowId,
      'title': title,
      'ownerName': ownerName,
      'bundleIdentifier': bundleIdentifier,
      'frame': frame.toMap(),
      'isOnScreen': isOnScreen,
    };
  }

  @override
  String toString() {
    return 'CapturableWindowInfo('
        'windowId: $windowId, '
        'title: $title, '
        'ownerName: $ownerName, '
        'bundleIdentifier: $bundleIdentifier, '
        'frame: $frame, '
        'isOnScreen: $isOnScreen)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CapturableWindowInfo &&
        other.windowId == windowId &&
        other.title == title &&
        other.ownerName == ownerName &&
        other.bundleIdentifier == bundleIdentifier &&
        other.frame == frame &&
        other.isOnScreen == isOnScreen;
  }

  @override
  int get hashCode {
    return Object.hash(
      windowId,
      title,
      ownerName,
      bundleIdentifier,
      frame,
      isOnScreen,
    );
  }
}

/// Window frame information for capturable windows
class CapturableWindowFrame {
  /// X coordinate of the window
  final double x;

  /// Y coordinate of the window
  final double y;

  /// Width of the window
  final double width;

  /// Height of the window
  final double height;

  const CapturableWindowFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Creates a [CapturableWindowFrame] from a map representation
  factory CapturableWindowFrame.fromMap(Map<String, dynamic> map) {
    return CapturableWindowFrame(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts this [CapturableWindowFrame] to a map representation
  Map<String, dynamic> toMap() {
    return {'x': x, 'y': y, 'width': width, 'height': height};
  }

  @override
  String toString() {
    return 'CapturableWindowFrame(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CapturableWindowFrame &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode {
    return Object.hash(x, y, width, height);
  }
}
