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
  });
  
  /// Creates a [MacosWindowInfo] from a map (typically from platform channel)
  factory MacosWindowInfo.fromMap(Map<String, dynamic> map) {
    return MacosWindowInfo(
      windowId: map['windowId'] ?? 0,
      name: map['name'] ?? '',
      ownerName: map['ownerName'] ?? '',
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      width: map['width']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      layer: map['layer'] ?? 0,
      isOnScreen: map['isOnScreen'] ?? false,
      processId: map['processId'] ?? 0,
      storeType: map['storeType'],
      sharingState: map['sharingState'],
      alpha: map['alpha']?.toDouble(),
      memoryUsage: map['memoryUsage'],
      isInVideoMemory: map['isInVideoMemory'],
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
        other.isInVideoMemory == isInVideoMemory;
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
    );
  }
}