# Examples

Practical examples and code snippets for common use cases with macOS Window Toolkit, including the new permission monitoring features.

## Basic Examples

### Simple Window Lister

```dart
import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class SimpleWindowLister extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Windows')),
      body: FutureBuilder<List<WindowInfo>>(
        future: MacosWindowToolkit.getAllWindows(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final windows = snapshot.data!;
          return ListView.builder(
            itemCount: windows.length,
            itemBuilder: (context, index) {
              final window = windows[index];
              return ListTile(
                title: Text(window.name),
                subtitle: Text(window.ownerName),
                trailing: Text('${window.bounds[2].toInt()}×${window.bounds[3].toInt()}'),
              );
            },
          );
        },
      ),
    );
  }
}
```

### Refreshable Window List

```dart
class RefreshableWindowList extends StatefulWidget {
  @override
  _RefreshableWindowListState createState() => _RefreshableWindowListState();
}

class _RefreshableWindowListState extends State<RefreshableWindowList> {
  List<WindowInfo> windows = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWindows();
  }

  Future<void> _loadWindows() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await MacosWindowToolkit.getAllWindows();
      setState(() {
        windows = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Windows (${windows.length})'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWindows,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWindows,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            Text('Error: $error'),
            ElevatedButton(
              onPressed: _loadWindows,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (windows.isEmpty) {
      return Center(child: Text('No windows found'));
    }

    return ListView.builder(
      itemCount: windows.length,
      itemBuilder: (context, index) => _buildWindowTile(windows[index]),
    );
  }

  Widget _buildWindowTile(WindowInfo window) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          window.isOnScreen ? Icons.visibility : Icons.visibility_off,
          color: window.isOnScreen ? Colors.green : Colors.grey,
        ),
        title: Text(window.name.isEmpty ? '(No Title)' : window.name),
        subtitle: Text(window.ownerName),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${window.bounds[2].toInt()}×${window.bounds[3].toInt()}'),
            Text('Layer ${window.layer}', style: TextStyle(fontSize: 12)),
          ],
        ),
        onTap: () => _showWindowDetails(window),
      ),
    );
  }

  void _showWindowDetails(WindowInfo window) {
    showDialog(
      context: context,
      builder: (context) => _WindowDetailsDialog(window: window),
    );
  }
}

class _WindowDetailsDialog extends StatelessWidget {
  final WindowInfo window;

  const _WindowDetailsDialog({required this.window});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(window.name.isEmpty ? '(No Title)' : window.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow('Application', window.ownerName),
          _DetailRow('Window ID', window.windowId.toString()),
          _DetailRow('Process ID', window.processId.toString()),
          _DetailRow('Position', '(${window.bounds[0].toInt()}, ${window.bounds[1].toInt()})'),
          _DetailRow('Size', '${window.bounds[2].toInt()} × ${window.bounds[3].toInt()}'),
          _DetailRow('Layer', window.layer.toString()),
          _DetailRow('Visible', window.isOnScreen ? 'Yes' : 'No'),
          _DetailRow('Area', '${(window.bounds[2] * window.bounds[3]).toInt()} pixels²'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label + ':', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
```

## Intermediate Examples

### Window Search and Filter

```dart
class WindowSearchPage extends StatefulWidget {
  @override
  _WindowSearchPageState createState() => _WindowSearchPageState();
}

class _WindowSearchPageState extends State<WindowSearchPage> {
  List<WindowInfo> allWindows = [];
  List<WindowInfo> filteredWindows = [];
  TextEditingController searchController = TextEditingController();
  bool showVisibleOnly = true;
  String selectedApp = 'All Apps';
  Set<String> availableApps = {'All Apps'};

  @override
  void initState() {
    super.initState();
    _loadWindows();
    searchController.addListener(_filterWindows);
  }

  Future<void> _loadWindows() async {
    try {
      final windows = await MacosWindowToolkit.getAllWindows();
      setState(() {
        allWindows = windows;
        availableApps = {'All Apps', ...windows.map((w) => w.ownerName).toSet()};
        _filterWindows();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading windows: $e')),
      );
    }
  }

  void _filterWindows() {
    setState(() {
      filteredWindows = allWindows.where((window) {
        // Text search
        final query = searchController.text.toLowerCase();
        final matchesSearch = query.isEmpty ||
            window.name.toLowerCase().contains(query) ||
            window.ownerName.toLowerCase().contains(query);

        // Visibility filter
        final matchesVisibility = !showVisibleOnly || window.isOnScreen;

        // App filter
        final matchesApp = selectedApp == 'All Apps' || window.ownerName == selectedApp;

        return matchesSearch && matchesVisibility && matchesApp;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Window Search'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWindows,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchControls(),
          Expanded(child: _buildWindowList()),
        ],
      ),
    );
  }

  Widget _buildSearchControls() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search windows...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterWindows();
                        },
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedApp,
                    isExpanded: true,
                    items: availableApps.map((app) {
                      return DropdownMenuItem(value: app, child: Text(app));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedApp = value!;
                        _filterWindows();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                FilterChip(
                  label: Text('Visible Only'),
                  selected: showVisibleOnly,
                  onSelected: (selected) {
                    setState(() {
                      showVisibleOnly = selected;
                      _filterWindows();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowList() {
    if (filteredWindows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No windows match your search criteria'),
            if (searchController.text.isNotEmpty || selectedApp != 'All Apps' || showVisibleOnly)
              TextButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    selectedApp = 'All Apps';
                    showVisibleOnly = false;
                    _filterWindows();
                  });
                },
                child: Text('Clear Filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredWindows.length,
      itemBuilder: (context, index) {
        final window = filteredWindows[index];
        return ListTile(
          leading: Icon(
            window.isOnScreen ? Icons.visibility : Icons.visibility_off,
            color: window.isOnScreen ? Colors.green : Colors.grey,
          ),
          title: Text(window.name.isEmpty ? '(No Title)' : window.name),
          subtitle: Text('${window.ownerName} • ${window.bounds[2].toInt()}×${window.bounds[3].toInt()}'),
          trailing: Chip(
            label: Text('${window.layer}'),
            backgroundColor: Colors.blue.shade100,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
```

### Window Statistics Dashboard

```dart
class WindowStatsDashboard extends StatefulWidget {
  @override
  _WindowStatsDashboardState createState() => _WindowStatsDashboardState();
}

class _WindowStatsDashboardState extends State<WindowStatsDashboard> {
  List<WindowInfo> windows = [];
  Map<String, int> appWindowCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWindows();
  }

  Future<void> _loadWindows() async {
    setState(() => isLoading = true);
    
    try {
      final result = await MacosWindowToolkit.getAllWindows();
      setState(() {
        windows = result;
        _calculateStats();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _calculateStats() {
    appWindowCounts.clear();
    for (final window in windows) {
      appWindowCounts[window.ownerName] = 
          (appWindowCounts[window.ownerName] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Window Statistics')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Window Statistics'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWindows,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            SizedBox(height: 24),
            _buildAppBreakdown(),
            SizedBox(height: 24),
            _buildSizeAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final visibleCount = windows.where((w) => w.isOnScreen).length;
    final totalArea = windows.fold<double>(0, (sum, w) => sum + (w.bounds[2] * w.bounds[3]));
    final averageArea = windows.isEmpty ? 0 : totalArea / windows.length;

    return Row(
      children: [
        Expanded(child: _StatCard('Total Windows', '${windows.length}', Icons.window)),
        SizedBox(width: 16),
        Expanded(child: _StatCard('Visible', '$visibleCount', Icons.visibility)),
        SizedBox(width: 16),
        Expanded(child: _StatCard('Applications', '${appWindowCounts.length}', Icons.apps)),
      ],
    );
  }

  Widget _buildAppBreakdown() {
    final sortedApps = appWindowCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Windows by Application', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            ...sortedApps.take(10).map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Container(
                    width: 100,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: entry.value / sortedApps.first.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('${entry.value}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeAnalysis() {
    final sortedBySize = windows.toList()
      ..sort((a, b) => (b.bounds[2] * b.bounds[3]).compareTo(a.bounds[2] * a.bounds[3]));

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Largest Windows', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            ...sortedBySize.take(5).map((window) {
              final area = (window.bounds[2] * window.bounds[3]).toInt();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(window.name.isEmpty ? '(No Title)' : window.name),
                subtitle: Text(window.ownerName),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${window.bounds[2].toInt()}×${window.bounds[3].toInt()}'),
                    Text('$area px²', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
```

## Permission Monitoring Examples

### Real-time Permission Monitoring

```dart
import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class PermissionMonitoringExample extends StatefulWidget {
  @override
  State<PermissionMonitoringExample> createState() => _PermissionMonitoringExampleState();
}

class _PermissionMonitoringExampleState extends State<PermissionMonitoringExample> {
  final _toolkit = MacosWindowToolkit();
  PermissionStatus? _lastStatus;
  List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _toolkit.stopPermissionWatching();
    super.dispose();
  }

  void _startMonitoring() {
    _toolkit.startPermissionWatching(
      interval: const Duration(seconds: 2),
      emitOnlyChanges: true,
    );

    _toolkit.permissionStream.listen((status) {
      setState(() {
        _lastStatus = status;
        
        if (status.hasChanges) {
          _eventLog.insert(0, 
            '[${DateTime.now().toString().substring(11, 19)}] '
            'CHANGE: Screen=${status.screenRecording}, '
            'Accessibility=${status.accessibility}'
          );
        }
        
        // Keep only last 10 events
        if (_eventLog.length > 10) {
          _eventLog = _eventLog.take(10).toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Permission Monitoring')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Status', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 16),
                    _buildPermissionRow('Screen Recording', _lastStatus?.screenRecording),
                    _buildPermissionRow('Accessibility', _lastStatus?.accessibility),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _lastStatus?.allPermissionsGranted == true 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _lastStatus?.allPermissionsGranted == true 
                                ? Colors.green 
                                : Colors.red
                            ),
                          ),
                          child: Text(
                            _lastStatus?.allPermissionsGranted == true 
                              ? 'All Granted' 
                              : 'Missing Permissions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _lastStatus?.allPermissionsGranted == true 
                                ? Colors.green.shade700 
                                : Colors.red.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Monitoring: ${_toolkit.isPermissionWatching ? "ON" : "OFF"}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Controls
            Row(
              children: [
                ElevatedButton(
                  onPressed: _toolkit.isPermissionWatching 
                    ? null 
                    : () => _startMonitoring(),
                  child: Text('Start Monitoring'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _toolkit.isPermissionWatching 
                    ? () {
                        _toolkit.stopPermissionWatching();
                        setState(() {});
                      }
                    : null,
                  child: Text('Stop Monitoring'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Event Log
            Text('Recent Changes', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _eventLog.isEmpty
                  ? Center(child: Text('No changes detected yet'))
                  : ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: _eventLog.length,
                      itemBuilder: (context, index) {
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _eventLog[index],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String name, bool? status) {
    Color color;
    String text;
    IconData icon;
    
    if (status == null) {
      color = Colors.grey;
      text = 'Unknown';
      icon = Icons.help;
    } else if (status) {
      color = Colors.green;
      text = 'Granted';
      icon = Icons.check_circle;
    } else {
      color = Colors.red;
      text = 'Denied';
      icon = Icons.error;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Text('$name:', style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

### Permission-Aware App Structure with Riverpod

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

// Providers
final permissionProvider = StreamProvider<PermissionStatus>((ref) {
  final toolkit = MacosWindowToolkit();
  toolkit.startPermissionWatching();
  return toolkit.permissionStream;
});

final windowsProvider = FutureProvider<List<MacosWindowInfo>>((ref) async {
  final toolkit = MacosWindowToolkit();
  return await toolkit.getAllWindows();
});

// Main App Structure
class PermissionAwareApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      home: PermissionGate(),
    );
  }
}

class PermissionGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionProvider);
    
    return permissionAsync.when(
      data: (status) {
        if (status.allPermissionsGranted) {
          return MainApp();
        } else {
          return PermissionSetupScreen(status: status);
        }
      },
      loading: () => LoadingScreen(),
      error: (error, _) => ErrorScreen(error: error),
    );
  }
}

class PermissionSetupScreen extends ConsumerWidget {
  final PermissionStatus status;
  
  const PermissionSetupScreen({required this.status, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Permissions Required')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'This app requires the following permissions:',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            
            // Show missing permissions
            ...status.deniedPermissions.map((permission) => 
              PermissionTile(
                name: permission,
                isGranted: false,
                onRequest: () => _requestPermission(permission),
              )
            ).toList(),
            
            SizedBox(height: 32),
            
            Text(
              'Permissions will be detected automatically once granted.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission(String permission) async {
    final toolkit = MacosWindowToolkit();
    
    switch (permission) {
      case 'Screen Recording':
        await toolkit.requestScreenRecordingPermission();
        break;
      case 'Accessibility':
        await toolkit.requestAccessibilityPermission();
        break;
    }
  }
}

class PermissionTile extends StatelessWidget {
  final String name;
  final bool isGranted;
  final VoidCallback onRequest;
  
  const PermissionTile({
    required this.name,
    required this.isGranted,
    required this.onRequest,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          isGranted ? Icons.check_circle : Icons.warning,
          color: isGranted ? Colors.green : Colors.orange,
        ),
        title: Text(name),
        subtitle: Text(isGranted ? 'Granted' : 'Required'),
        trailing: isGranted 
          ? null 
          : ElevatedButton(
              onPressed: onRequest,
              child: Text('Request'),
            ),
      ),
    );
  }
}

class MainApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowsAsync = ref.watch(windowsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Window Manager'),
        actions: [
          PermissionStatusIndicator(),
        ],
      ),
      body: windowsAsync.when(
        data: (windows) => WindowListView(windows: windows),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.refresh(windowsProvider),
        child: Icon(Icons.refresh),
      ),
    );
  }
}

class PermissionStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(permissionProvider);
    
    return permissionAsync.when(
      data: (status) => Container(
        margin: EdgeInsets.only(right: 16),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: status.allPermissionsGranted 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status.allPermissionsGranted ? Colors.green : Colors.orange,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.allPermissionsGranted ? Icons.check : Icons.warning,
              size: 16,
              color: status.allPermissionsGranted ? Colors.green : Colors.orange,
            ),
            SizedBox(width: 4),
            Text(
              status.allPermissionsGranted ? 'OK' : '${status.deniedPermissions.length}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: status.allPermissionsGranted ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
      loading: () => SizedBox.shrink(),
      error: (_, __) => Icon(Icons.error, color: Colors.red),
    );
  }
}

class WindowListView extends StatelessWidget {
  final List<MacosWindowInfo> windows;
  
  const WindowListView({required this.windows, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: windows.length,
      itemBuilder: (context, index) {
        final window = windows[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              window.isOnScreen ? Icons.visibility : Icons.visibility_off,
              color: window.isOnScreen ? Colors.green : Colors.grey,
            ),
            title: Text(window.name.isEmpty ? '(No Title)' : window.name),
            subtitle: Text('${window.ownerName} • PID: ${window.processId}'),
            trailing: Text('${window.width.toInt()} × ${window.height.toInt()}'),
          ),
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking permissions...'),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Object error;
  
  const ErrorScreen({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Advanced Examples

### Real-time Window Monitor

```dart
class WindowMonitorApp extends StatefulWidget {
  @override
  _WindowMonitorAppState createState() => _WindowMonitorAppState();
}

class _WindowMonitorAppState extends State<WindowMonitorApp> {
  List<WindowInfo> currentWindows = [];
  List<String> events = [];
  Timer? monitorTimer;
  Map<int, WindowInfo> previousWindowsMap = {};

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    monitorTimer = Timer.periodic(Duration(seconds: 1), (_) => _checkWindows());
    _checkWindows(); // Initial load
  }

  Future<void> _checkWindows() async {
    try {
      final windows = await MacosWindowToolkit.getAllWindows();
      final currentMap = {for (var w in windows) w.windowId: w};
      
      _detectChanges(previousWindowsMap, currentMap);
      
      setState(() {
        currentWindows = windows;
        previousWindowsMap = currentMap;
      });
    } catch (e) {
      _addEvent('Error: $e');
    }
  }

  void _detectChanges(Map<int, WindowInfo> previous, Map<int, WindowInfo> current) {
    final currentIds = current.keys.toSet();
    final previousIds = previous.keys.toSet();

    // New windows
    for (final id in currentIds.difference(previousIds)) {
      final window = current[id]!;
      _addEvent('➕ New: ${window.name} (${window.ownerName})');
    }

    // Closed windows
    for (final id in previousIds.difference(currentIds)) {
      final window = previous[id]!;
      _addEvent('➖ Closed: ${window.name} (${window.ownerName})');
    }

    // Changed windows
    for (final id in currentIds.intersection(previousIds)) {
      final oldWindow = previous[id]!;
      final newWindow = current[id]!;
      
      if (oldWindow.name != newWindow.name) {
        _addEvent('📝 Renamed: ${oldWindow.name} → ${newWindow.name}');
      }
      
      if (oldWindow.isOnScreen != newWindow.isOnScreen) {
        final status = newWindow.isOnScreen ? 'shown' : 'hidden';
        _addEvent('👁 ${newWindow.name}: $status');
      }
      
      if (!_boundsEqual(oldWindow.bounds, newWindow.bounds)) {
        _addEvent('📐 Resized: ${newWindow.name}');
      }
    }
  }

  bool _boundsEqual(List<double> a, List<double> b) {
    return (a[0] - b[0]).abs() < 1 &&
           (a[1] - b[1]).abs() < 1 &&
           (a[2] - b[2]).abs() < 1 &&
           (a[3] - b[3]).abs() < 1;
  }

  void _addEvent(String event) {
    setState(() {
      events.insert(0, '${DateTime.now().toString().substring(11, 19)} - $event');
      if (events.length > 100) {
        events.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Window Monitor'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => setState(() => events.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.monitor, color: Colors.blue),
                SizedBox(width: 8),
                Text('Monitoring ${currentWindows.length} windows'),
                Spacer(),
                Text('${events.length} events'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(
                    events[index],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    monitorTimer?.cancel();
    super.dispose();
  }
}
```

### Window Utility Functions

```dart
class WindowUtils {
  // Find windows by criteria
  static List<WindowInfo> findByApp(List<WindowInfo> windows, String appName) {
    return windows.where((w) => 
      w.ownerName.toLowerCase().contains(appName.toLowerCase())
    ).toList();
  }

  static WindowInfo? findLargestWindow(List<WindowInfo> windows) {
    if (windows.isEmpty) return null;
    return windows.reduce((a, b) => 
      (a.bounds[2] * a.bounds[3]) > (b.bounds[2] * b.bounds[3]) ? a : b
    );
  }

  static WindowInfo? findTopmostWindow(List<WindowInfo> windows) {
    if (windows.isEmpty) return null;
    return windows.reduce((a, b) => a.layer > b.layer ? a : b);
  }

  // Geometric calculations
  static bool windowsOverlap(WindowInfo a, WindowInfo b) {
    final aRect = Rect.fromLTWH(a.bounds[0], a.bounds[1], a.bounds[2], a.bounds[3]);
    final bRect = Rect.fromLTWH(b.bounds[0], b.bounds[1], b.bounds[2], b.bounds[3]);
    return aRect.overlaps(bRect);
  }

  static double calculateOverlapArea(WindowInfo a, WindowInfo b) {
    final aRect = Rect.fromLTWH(a.bounds[0], a.bounds[1], a.bounds[2], a.bounds[3]);
    final bRect = Rect.fromLTWH(b.bounds[0], b.bounds[1], b.bounds[2], b.bounds[3]);
    final intersection = aRect.intersect(bRect);
    return intersection.isEmpty ? 0 : intersection.width * intersection.height;
  }

  // Grouping and sorting
  static Map<String, List<WindowInfo>> groupByApp(List<WindowInfo> windows) {
    final grouped = <String, List<WindowInfo>>{};
    for (final window in windows) {
      grouped.putIfAbsent(window.ownerName, () => []).add(window);
    }
    return grouped;
  }

  static List<WindowInfo> sortBySize(List<WindowInfo> windows, {bool ascending = false}) {
    final sorted = List<WindowInfo>.from(windows);
    sorted.sort((a, b) {
      final aArea = a.bounds[2] * a.bounds[3];
      final bArea = b.bounds[2] * b.bounds[3];
      return ascending ? aArea.compareTo(bArea) : bArea.compareTo(aArea);
    });
    return sorted;
  }

  static List<WindowInfo> sortByPosition(List<WindowInfo> windows) {
    final sorted = List<WindowInfo>.from(windows);
    sorted.sort((a, b) {
      final yCompare = a.bounds[1].compareTo(b.bounds[1]);
      return yCompare != 0 ? yCompare : a.bounds[0].compareTo(b.bounds[0]);
    });
    return sorted;
  }

  // Filtering
  static List<WindowInfo> filterVisible(List<WindowInfo> windows) {
    return windows.where((w) => w.isOnScreen).toList();
  }

  static List<WindowInfo> filterByMinSize(
    List<WindowInfo> windows, 
    double minWidth, 
    double minHeight,
  ) {
    return windows.where((w) => 
      w.bounds[2] >= minWidth && w.bounds[3] >= minHeight
    ).toList();
  }

  static List<WindowInfo> filterInRegion(List<WindowInfo> windows, Rect region) {
    return windows.where((w) {
      final windowRect = Rect.fromLTWH(w.bounds[0], w.bounds[1], w.bounds[2], w.bounds[3]);
      return region.overlaps(windowRect);
    }).toList();
  }

  // Statistics
  static Map<String, dynamic> calculateStatistics(List<WindowInfo> windows) {
    if (windows.isEmpty) {
      return {'totalWindows': 0, 'visibleWindows': 0, 'totalArea': 0.0, 'averageArea': 0.0};
    }

    final visibleCount = windows.where((w) => w.isOnScreen).length;
    final totalArea = windows.fold<double>(0, (sum, w) => sum + (w.bounds[2] * w.bounds[3]));
    
    return {
      'totalWindows': windows.length,
      'visibleWindows': visibleCount,
      'totalArea': totalArea,
      'averageArea': totalArea / windows.length,
      'applications': groupByApp(windows).length,
    };
  }
}
```

These examples demonstrate various patterns and techniques for working with macOS Window Toolkit, from basic window listing to advanced monitoring and analysis functionality.