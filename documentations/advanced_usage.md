# Advanced Usage

This guide covers advanced patterns and techniques for using macOS Window Toolkit effectively in complex applications.

## Performance Optimization

### Caching Strategies

While the plugin doesn't cache results internally, you can implement your own caching:

```dart
class WindowService {
  List<WindowInfo>? _cachedWindows;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(seconds: 2);

  Future<List<WindowInfo>> getWindows({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    if (!forceRefresh && 
        _cachedWindows != null && 
        _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheTimeout) {
      return _cachedWindows!;
    }

    _cachedWindows = await MacosWindowToolkit.getAllWindows();
    _lastFetch = now;
    return _cachedWindows!;
  }

  void invalidateCache() {
    _cachedWindows = null;
    _lastFetch = null;
  }
}
```

### Debounced Updates

For real-time applications, debounce frequent updates:

```dart
class DebouncedWindowManager {
  Timer? _debounceTimer;
  final Duration _debounceDuration;
  final VoidCallback _onUpdate;

  DebouncedWindowManager({
    Duration debounceDuration = const Duration(milliseconds: 500),
    required VoidCallback onUpdate,
  }) : _debounceDuration = debounceDuration,
       _onUpdate = onUpdate;

  void requestUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _onUpdate);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
```

### Filtering for Performance

Apply filters early to reduce processing overhead:

```dart
class WindowFilter {
  static List<WindowInfo> visibleOnly(List<WindowInfo> windows) {
    return windows.where((w) => w.isOnScreen).toList();
  }

  static List<WindowInfo> byApplication(
    List<WindowInfo> windows, 
    String appName,
  ) {
    return windows.where((w) => 
      w.ownerName.toLowerCase().contains(appName.toLowerCase())
    ).toList();
  }

  static List<WindowInfo> minimumSize(
    List<WindowInfo> windows,
    double minWidth,
    double minHeight,
  ) {
    return windows.where((w) => 
      w.bounds[2] >= minWidth && w.bounds[3] >= minHeight
    ).toList();
  }

  static List<WindowInfo> inRegion(
    List<WindowInfo> windows,
    Rect region,
  ) {
    return windows.where((w) {
      final windowRect = Rect.fromLTWH(
        w.bounds[0], w.bounds[1], w.bounds[2], w.bounds[3],
      );
      return region.overlaps(windowRect);
    }).toList();
  }
}
```

## Real-time Window Monitoring

### Polling Implementation

```dart
class WindowMonitor {
  Timer? _timer;
  List<WindowInfo> _previousWindows = [];
  final Duration _pollInterval;
  
  // Callbacks
  final Function(List<WindowInfo>)? onWindowsChanged;
  final Function(WindowInfo)? onWindowAdded;
  final Function(WindowInfo)? onWindowRemoved;
  final Function(WindowInfo, WindowInfo)? onWindowChanged;

  WindowMonitor({
    Duration pollInterval = const Duration(seconds: 1),
    this.onWindowsChanged,
    this.onWindowAdded,
    this.onWindowRemoved,
    this.onWindowChanged,
  }) : _pollInterval = pollInterval;

  void start() {
    _timer = Timer.periodic(_pollInterval, (_) => _checkWindows());
    _checkWindows(); // Initial check
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkWindows() async {
    try {
      final currentWindows = await MacosWindowToolkit.getAllWindows();
      _compareWindows(_previousWindows, currentWindows);
      _previousWindows = List.from(currentWindows);
    } catch (e) {
      debugPrint('Error monitoring windows: $e');
    }
  }

  void _compareWindows(
    List<WindowInfo> previous, 
    List<WindowInfo> current,
  ) {
    final previousIds = previous.map((w) => w.windowId).toSet();
    final currentIds = current.map((w) => w.windowId).toSet();

    // Find new windows
    for (final window in current) {
      if (!previousIds.contains(window.windowId)) {
        onWindowAdded?.call(window);
      }
    }

    // Find removed windows
    for (final window in previous) {
      if (!currentIds.contains(window.windowId)) {
        onWindowRemoved?.call(window);
      }
    }

    // Find changed windows
    for (final currentWindow in current) {
      final previousWindow = previous.firstWhereOrNull(
        (w) => w.windowId == currentWindow.windowId,
      );
      if (previousWindow != null && !_windowsEqual(previousWindow, currentWindow)) {
        onWindowChanged?.call(previousWindow, currentWindow);
      }
    }

    onWindowsChanged?.call(current);
  }

  bool _windowsEqual(WindowInfo a, WindowInfo b) {
    return a.windowId == b.windowId &&
           a.name == b.name &&
           a.ownerName == b.ownerName &&
           listEquals(a.bounds, b.bounds) &&
           a.layer == b.layer &&
           a.isOnScreen == b.isOnScreen &&
           a.processId == b.processId;
  }
}

// Extension to add firstWhereOrNull
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
```

### Usage Example

```dart
class WindowMonitorWidget extends StatefulWidget {
  @override
  _WindowMonitorWidgetState createState() => _WindowMonitorWidgetState();
}

class _WindowMonitorWidgetState extends State<WindowMonitorWidget> {
  final WindowMonitor _monitor = WindowMonitor(
    pollInterval: Duration(milliseconds: 500),
    onWindowAdded: (window) => print('New window: ${window.name}'),
    onWindowRemoved: (window) => print('Window closed: ${window.name}'),
    onWindowChanged: (old, new_) => print('Window changed: ${new_.name}'),
  );

  @override
  void initState() {
    super.initState();
    _monitor.start();
  }

  @override
  void dispose() {
    _monitor.stop();
    super.dispose();
  }

  // ... rest of widget
}
```

## Complex Window Analysis

### Window Hierarchy Analysis

```dart
class WindowAnalyzer {
  static Map<String, List<WindowInfo>> groupByApplication(
    List<WindowInfo> windows,
  ) {
    final grouped = <String, List<WindowInfo>>{};
    for (final window in windows) {
      grouped.putIfAbsent(window.ownerName, () => []).add(window);
    }
    return grouped;
  }

  static List<WindowInfo> sortBySize(
    List<WindowInfo> windows, 
    {bool ascending = false}
  ) {
    return windows.toList()..sort((a, b) {
      final aArea = a.bounds[2] * a.bounds[3];
      final bArea = b.bounds[2] * b.bounds[3];
      return ascending ? aArea.compareTo(bArea) : bArea.compareTo(aArea);
    });
  }

  static List<WindowInfo> sortByLayer(
    List<WindowInfo> windows,
    {bool frontToBack = true}
  ) {
    return windows.toList()..sort((a, b) {
      return frontToBack 
        ? b.layer.compareTo(a.layer)
        : a.layer.compareTo(b.layer);
    });
  }

  static WindowStats calculateStats(List<WindowInfo> windows) {
    if (windows.isEmpty) {
      return WindowStats.empty();
    }

    var totalArea = 0.0;
    var visibleCount = 0;
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final window in windows) {
      totalArea += window.bounds[2] * window.bounds[3];
      if (window.isOnScreen) visibleCount++;
      
      minX = math.min(minX, window.bounds[0]);
      minY = math.min(minY, window.bounds[1]);
      maxX = math.max(maxX, window.bounds[0] + window.bounds[2]);
      maxY = math.max(maxY, window.bounds[1] + window.bounds[3]);
    }

    return WindowStats(
      totalCount: windows.length,
      visibleCount: visibleCount,
      totalArea: totalArea,
      averageArea: totalArea / windows.length,
      bounds: Rect.fromLTRB(minX, minY, maxX, maxY),
      applicationCount: groupByApplication(windows).length,
    );
  }
}

class WindowStats {
  final int totalCount;
  final int visibleCount;
  final double totalArea;
  final double averageArea;
  final Rect bounds;
  final int applicationCount;

  WindowStats({
    required this.totalCount,
    required this.visibleCount,
    required this.totalArea,
    required this.averageArea,
    required this.bounds,
    required this.applicationCount,
  });

  factory WindowStats.empty() {
    return WindowStats(
      totalCount: 0,
      visibleCount: 0,
      totalArea: 0,
      averageArea: 0,
      bounds: Rect.zero,
      applicationCount: 0,
    );
  }
}
```

## State Management Integration

### Provider Pattern

```dart
class WindowProvider extends ChangeNotifier {
  List<WindowInfo> _windows = [];
  bool _isLoading = false;
  String? _error;
  
  List<WindowInfo> get windows => _windows;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  final WindowService _windowService = WindowService();

  Future<void> refreshWindows() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _windows = await _windowService.getWindows(forceRefresh: true);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  List<WindowInfo> getWindowsForApp(String appName) {
    return _windows.where((w) => 
      w.ownerName.toLowerCase() == appName.toLowerCase()
    ).toList();
  }

  WindowInfo? findWindowById(int windowId) {
    try {
      return _windows.firstWhere((w) => w.windowId == windowId);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
```

### BLoC Pattern

```dart
// Events
abstract class WindowEvent {}

class LoadWindows extends WindowEvent {}
class RefreshWindows extends WindowEvent {}
class FilterWindows extends WindowEvent {
  final String filter;
  FilterWindows(this.filter);
}

// States
abstract class WindowState {}

class WindowInitial extends WindowState {}
class WindowLoading extends WindowState {}
class WindowLoaded extends WindowState {
  final List<WindowInfo> windows;
  WindowLoaded(this.windows);
}
class WindowError extends WindowState {
  final String error;
  WindowError(this.error);
}

// BLoC
class WindowBloc extends Bloc<WindowEvent, WindowState> {
  final WindowService _windowService;
  
  WindowBloc(this._windowService) : super(WindowInitial()) {
    on<LoadWindows>(_onLoadWindows);
    on<RefreshWindows>(_onRefreshWindows);
    on<FilterWindows>(_onFilterWindows);
  }

  Future<void> _onLoadWindows(
    LoadWindows event, 
    Emitter<WindowState> emit,
  ) async {
    emit(WindowLoading());
    try {
      final windows = await _windowService.getWindows();
      emit(WindowLoaded(windows));
    } catch (e) {
      emit(WindowError(e.toString()));
    }
  }

  Future<void> _onRefreshWindows(
    RefreshWindows event, 
    Emitter<WindowState> emit,
  ) async {
    try {
      final windows = await _windowService.getWindows(forceRefresh: true);
      emit(WindowLoaded(windows));
    } catch (e) {
      emit(WindowError(e.toString()));
    }
  }

  Future<void> _onFilterWindows(
    FilterWindows event, 
    Emitter<WindowState> emit,
  ) async {
    if (state is WindowLoaded) {
      final currentWindows = (state as WindowLoaded).windows;
      final filteredWindows = currentWindows.where((w) =>
        w.name.toLowerCase().contains(event.filter.toLowerCase()) ||
        w.ownerName.toLowerCase().contains(event.filter.toLowerCase())
      ).toList();
      emit(WindowLoaded(filteredWindows));
    }
  }
}
```

## Custom Data Structures

### Enhanced WindowInfo

```dart
extension WindowInfoExtensions on WindowInfo {
  // Geometry helpers
  Rect get rect => Rect.fromLTWH(bounds[0], bounds[1], bounds[2], bounds[3]);
  Offset get position => Offset(bounds[0], bounds[1]);
  Size get size => Size(bounds[2], bounds[3]);
  Offset get center => Offset(
    bounds[0] + bounds[2] / 2, 
    bounds[1] + bounds[3] / 2,
  );
  
  // Convenience getters
  double get area => bounds[2] * bounds[3];
  double get aspectRatio => bounds[2] / bounds[3];
  bool get isLandscape => bounds[2] > bounds[3];
  bool get isPortrait => bounds[3] > bounds[2];
  bool get isSquare => (bounds[2] - bounds[3]).abs() < 1.0;
  
  // Size categories
  bool get isSmall => area < 100000;  // < 316x316
  bool get isMedium => area >= 100000 && area < 500000;
  bool get isLarge => area >= 500000;
  
  // Position helpers
  bool isInRegion(Rect region) => region.overlaps(rect);
  bool isLeftOf(WindowInfo other) => bounds[0] + bounds[2] < other.bounds[0];
  bool isRightOf(WindowInfo other) => bounds[0] > other.bounds[0] + other.bounds[2];
  bool isAbove(WindowInfo other) => bounds[1] + bounds[3] < other.bounds[1];
  bool isBelow(WindowInfo other) => bounds[1] > other.bounds[1] + other.bounds[3];
  
  // Overlap detection
  bool overlapsWith(WindowInfo other) => rect.overlaps(other.rect);
  double overlapArea(WindowInfo other) {
    final intersection = rect.intersect(other.rect);
    return intersection.isEmpty ? 0 : intersection.width * intersection.height;
  }
}
```

### Window Collections

```dart
class WindowCollection {
  final List<WindowInfo> _windows;
  
  WindowCollection(this._windows);
  
  factory WindowCollection.fromList(List<WindowInfo> windows) =>
      WindowCollection(List.from(windows));
  
  // Getters
  List<WindowInfo> get windows => List.unmodifiable(_windows);
  int get length => _windows.length;
  bool get isEmpty => _windows.isEmpty;
  bool get isNotEmpty => _windows.isNotEmpty;
  
  // Filtering
  WindowCollection visible() => 
      WindowCollection(_windows.where((w) => w.isOnScreen).toList());
  
  WindowCollection byApp(String appName) => 
      WindowCollection(_windows.where((w) => 
        w.ownerName.toLowerCase().contains(appName.toLowerCase())).toList());
  
  WindowCollection inRegion(Rect region) =>
      WindowCollection(_windows.where((w) => w.isInRegion(region)).toList());
  
  WindowCollection largerThan(double width, double height) =>
      WindowCollection(_windows.where((w) => 
        w.bounds[2] > width && w.bounds[3] > height).toList());
  
  // Sorting  
  WindowCollection sortedBySize({bool ascending = false}) {
    final sorted = List<WindowInfo>.from(_windows);
    sorted.sort((a, b) {
      final comparison = a.area.compareTo(b.area);
      return ascending ? comparison : -comparison;
    });
    return WindowCollection(sorted);
  }
  
  WindowCollection sortedByPosition() {
    final sorted = List<WindowInfo>.from(_windows);
    sorted.sort((a, b) {
      final yCompare = a.bounds[1].compareTo(b.bounds[1]);
      return yCompare != 0 ? yCompare : a.bounds[0].compareTo(b.bounds[0]);
    });
    return WindowCollection(sorted);
  }
  
  // Analysis
  WindowStats get stats => WindowAnalyzer.calculateStats(_windows);
  Map<String, List<WindowInfo>> get byApplication => 
      WindowAnalyzer.groupByApplication(_windows);
  
  WindowInfo? get largest => _windows.isEmpty ? null :
      _windows.reduce((a, b) => a.area > b.area ? a : b);
  
  WindowInfo? get topmost => _windows.isEmpty ? null :
      _windows.reduce((a, b) => a.layer > b.layer ? a : b);
}
```

## Error Recovery Strategies

### Retry Logic

```dart
class RobustWindowService {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);

  static Future<List<WindowInfo>> getWindowsWithRetry() async {
    var attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await MacosWindowToolkit.getAllWindows();
      } on PlatformException catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        // Exponential backoff
        final delay = retryDelay * math.pow(2, attempt - 1);
        await Future.delayed(delay);
      }
    }
    
    // This should never be reached
    throw Exception('Max retries exceeded');
  }
}
```

### Fallback Mechanisms

```dart
class WindowServiceWithFallback {
  static List<WindowInfo>? _lastKnownGoodData;
  
  static Future<List<WindowInfo>> getWindows() async {
    try {
      final windows = await MacosWindowToolkit.getAllWindows();
      _lastKnownGoodData = windows; // Cache successful result
      return windows;
    } catch (e) {
      // Return last known good data if available
      if (_lastKnownGoodData != null) {
        debugPrint('Using cached data due to error: $e');
        return _lastKnownGoodData!;
      }
      
      // Return empty list as final fallback
      debugPrint('No cached data available, returning empty list. Error: $e');
      return [];
    }
  }
}
```

This advanced usage guide provides patterns and techniques for building robust, performant applications with macOS Window Toolkit. Choose the approaches that best fit your application's architecture and requirements.