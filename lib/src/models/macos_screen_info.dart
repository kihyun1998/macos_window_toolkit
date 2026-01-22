/// Represents a rectangle (frame) on the screen with position and size.
class ScreenRect {
  /// X coordinate of the frame's origin
  final double x;

  /// Y coordinate of the frame's origin
  final double y;

  /// Width of the frame
  final double width;

  /// Height of the frame
  final double height;

  const ScreenRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Creates a [ScreenRect] from a map representation
  factory ScreenRect.fromMap(Map<String, dynamic> map) {
    return ScreenRect(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts this [ScreenRect] to a map representation
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  @override
  String toString() {
    return 'ScreenRect(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScreenRect &&
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

/// Information about a macOS screen/display.
///
/// Contains detailed information about screen dimensions, scale factor,
/// and pixel resolution for each connected display.
class MacosScreenInfo {
  /// Index of the screen (0-based)
  final int index;

  /// Whether this is the main screen
  final bool isMain;

  /// Scale factor (e.g., 2.0 for Retina displays)
  final double scaleFactor;

  /// Full frame of the screen in points
  final ScreenRect frame;

  /// Visible frame excluding menu bar and dock
  final ScreenRect visibleFrame;

  /// Actual pixel width (frame.width * scaleFactor)
  final int pixelWidth;

  /// Actual pixel height (frame.height * scaleFactor)
  final int pixelHeight;

  const MacosScreenInfo({
    required this.index,
    required this.isMain,
    required this.scaleFactor,
    required this.frame,
    required this.visibleFrame,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  /// Creates a [MacosScreenInfo] from a map representation
  factory MacosScreenInfo.fromMap(Map<String, dynamic> map) {
    return MacosScreenInfo(
      index: map['index'] as int? ?? 0,
      isMain: map['isMain'] as bool? ?? false,
      scaleFactor: (map['scaleFactor'] as num?)?.toDouble() ?? 1.0,
      frame: ScreenRect.fromMap(map['frame'] as Map<String, dynamic>? ?? {}),
      visibleFrame: ScreenRect.fromMap(
          map['visibleFrame'] as Map<String, dynamic>? ?? {}),
      pixelWidth: map['pixelWidth'] as int? ?? 0,
      pixelHeight: map['pixelHeight'] as int? ?? 0,
    );
  }

  /// Converts this [MacosScreenInfo] to a map representation
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'isMain': isMain,
      'scaleFactor': scaleFactor,
      'frame': frame.toMap(),
      'visibleFrame': visibleFrame.toMap(),
      'pixelWidth': pixelWidth,
      'pixelHeight': pixelHeight,
    };
  }

  @override
  String toString() {
    return 'MacosScreenInfo('
        'index: $index, '
        'isMain: $isMain, '
        'scaleFactor: $scaleFactor, '
        'frame: $frame, '
        'visibleFrame: $visibleFrame, '
        'pixelWidth: $pixelWidth, '
        'pixelHeight: $pixelHeight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MacosScreenInfo &&
        other.index == index &&
        other.isMain == isMain &&
        other.scaleFactor == scaleFactor &&
        other.frame == frame &&
        other.visibleFrame == visibleFrame &&
        other.pixelWidth == pixelWidth &&
        other.pixelHeight == pixelHeight;
  }

  @override
  int get hashCode {
    return Object.hash(
      index,
      isMain,
      scaleFactor,
      frame,
      visibleFrame,
      pixelWidth,
      pixelHeight,
    );
  }
}
