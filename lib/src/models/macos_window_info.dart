/// Represents information about a macOS window
class MacosWindowInfo {
  /// Unique identifier for the window
  final int windowId;

  /// Window title/name
  final String name;

  /// Name of the application that owns the window
  final String ownerName;

  /// X coordinate of the window
  final double x;

  /// Y coordinate of the window
  final double y;

  /// Width of the window
  final double width;

  /// Height of the window
  final double height;

  /// Window layer level
  final int layer;

  /// Whether the window is currently visible on screen
  final bool isOnScreen;

  /// Process ID of the application that owns the window
  final int processId;

  /// Window store type (system internal)
  final int? storeType;

  /// Sharing state of the window
  /// 0: None (not shared), 1: ReadOnly, 2: ReadWrite
  final int? sharingState;

  /// Transparency/alpha value of the window (0.0 = transparent, 1.0 = opaque)
  final double? alpha;

  /// Memory usage of the window in bytes
  final int? memoryUsage;

  /// Whether the window buffer is stored in video memory
  final bool? isInVideoMemory;

  /// Window role (e.g., "AXWindow", "AXDialog", "AXSheet")
  /// Requires Accessibility permission to retrieve
  final String? role;

  /// Window subrole (e.g., "AXStandardWindow", "AXDialog", "AXFloatingWindow")
  /// Requires Accessibility permission to retrieve
  final String? subrole;

  const MacosWindowInfo({
    required this.windowId,
    required this.name,
    required this.ownerName,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.layer,
    required this.isOnScreen,
    required this.processId,
    this.storeType,
    this.sharingState,
    this.alpha,
    this.memoryUsage,
    this.isInVideoMemory,
    this.role,
    this.subrole,
  });

  /// Creates a [MacosWindowInfo] from a map (typically from platform channel)
  factory MacosWindowInfo.fromMap(Map<String, dynamic> map) {
    return MacosWindowInfo(
      windowId: (map['windowId'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      layer: (map['layer'] as num?)?.toInt() ?? 0,
      isOnScreen: map['isOnScreen'] as bool? ?? false,
      processId: (map['processId'] as num?)?.toInt() ?? 0,
      storeType: (map['storeType'] as num?)?.toInt(),
      sharingState: (map['sharingState'] as num?)?.toInt(),
      alpha: (map['alpha'] as num?)?.toDouble(),
      memoryUsage: (map['memoryUsage'] as num?)?.toInt(),
      isInVideoMemory: map['isInVideoMemory'] as bool?,
      role: map['role'] as String?,
      subrole: map['subrole'] as String?,
    );
  }

  /// Converts this [MacosWindowInfo] to a map
  Map<String, dynamic> toMap() {
    return {
      'windowId': windowId,
      'name': name,
      'ownerName': ownerName,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'layer': layer,
      'isOnScreen': isOnScreen,
      'processId': processId,
      if (storeType != null) 'storeType': storeType,
      if (sharingState != null) 'sharingState': sharingState,
      if (alpha != null) 'alpha': alpha,
      if (memoryUsage != null) 'memoryUsage': memoryUsage,
      if (isInVideoMemory != null) 'isInVideoMemory': isInVideoMemory,
      if (role != null) 'role': role,
      if (subrole != null) 'subrole': subrole,
    };
  }

  @override
  String toString() {
    return 'MacosWindowInfo('
        'windowId: $windowId, '
        'name: "$name", '
        'ownerName: "$ownerName", '
        'x: $x, y: $y, '
        'width: $width, height: $height, '
        'layer: $layer, '
        'isOnScreen: $isOnScreen, '
        'processId: $processId'
        '${storeType != null ? ', storeType: $storeType' : ''}'
        '${sharingState != null ? ', sharingState: $sharingState' : ''}'
        '${alpha != null ? ', alpha: $alpha' : ''}'
        '${memoryUsage != null ? ', memoryUsage: $memoryUsage' : ''}'
        '${isInVideoMemory != null ? ', isInVideoMemory: $isInVideoMemory' : ''}'
        '${role != null ? ', role: $role' : ''}'
        '${subrole != null ? ', subrole: $subrole' : ''}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MacosWindowInfo &&
        other.windowId == windowId &&
        other.name == name &&
        other.ownerName == ownerName &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.layer == layer &&
        other.isOnScreen == isOnScreen &&
        other.processId == processId &&
        other.storeType == storeType &&
        other.sharingState == sharingState &&
        other.alpha == alpha &&
        other.memoryUsage == memoryUsage &&
        other.isInVideoMemory == isInVideoMemory &&
        other.role == role &&
        other.subrole == subrole;
  }

  @override
  int get hashCode {
    return Object.hash(
      windowId,
      name,
      ownerName,
      x,
      y,
      width,
      height,
      layer,
      isOnScreen,
      processId,
      storeType,
      sharingState,
      alpha,
      memoryUsage,
      isInVideoMemory,
      role,
      subrole,
    );
  }
}
