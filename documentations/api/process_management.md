# Process Management API

Complete reference for application process control and management operations.

## Overview

The Process Management API provides functionality for controlling application processes and analyzing process relationships. This includes terminating individual applications, managing entire process trees, and discovering child process relationships. These capabilities are particularly useful for security applications, system administration tools, and advanced window management scenarios.

## Quick Reference

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| [`terminateApplicationByPID()`](#terminateapplicationbypid) | Terminate single process | `processId`, `force` | `Future<bool>` |
| [`terminateApplicationTree()`](#terminateapplicationtree) | Terminate process and all children | `processId`, `force` | `Future<bool>` |
| [`getChildProcesses()`](#getchildprocesses) | Get child process IDs | `processId` | `Future<List<int>>` |

## Methods

### `terminateApplicationByPID()`

Terminates an application by its process ID.

**Signature:**
```dart
Future<bool> terminateApplicationByPID(
  int processId, {
  bool force = false,
})
```

**Parameters:**
- `processId` - Process ID of the application to terminate
- `force` (optional) - Termination method. `false` for graceful, `true` for forced. Defaults to `false`.

**Returns:**
- `Future<bool>` - `true` if application was successfully terminated, `false` otherwise

**Throws:**
- `PlatformException` with error codes:
  - `TERMINATE_APP_ERROR` - Application termination failed
  - `PROCESS_NOT_FOUND` - Process with specified ID does not exist
  - `TERMINATION_FAILED` - System call to terminate process failed

**Termination Methods:**
- **Graceful (`force: false`)**: Allows application to clean up resources, save data, and terminate properly
- **Forced (`force: true`)**: Immediately kills the process without cleanup

**Implementation Approach:**
1. **NSRunningApplication API** (preferred) - More graceful termination
2. **Signal-based termination** (fallback) - SIGTERM/SIGKILL system calls

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Get process ID from window information
final windows = await toolkit.getAllWindows();
final targetWindow = windows.firstWhere(
  (w) => w.ownerName.contains('TextEdit'),
  orElse: () => throw StateError('TextEdit window not found'),
);

print('Terminating TextEdit (PID: ${targetWindow.processId})');

// Try graceful termination first
bool success = await toolkit.terminateApplicationByPID(targetWindow.processId);

if (success) {
  print('✅ Application terminated gracefully');
} else {
  print('❌ Graceful termination failed, trying force termination...');
  
  // Try force termination as fallback
  success = await toolkit.terminateApplicationByPID(
    targetWindow.processId,
    force: true,
  );
  
  if (success) {
    print('✅ Application force terminated');
  } else {
    print('❌ Failed to terminate application');
  }
}
```

**Advanced Usage with Error Handling:**
```dart
Future<bool> safeTerminateApplication(
  int processId, {
  bool tryGracefulFirst = true,
  Duration gracefulTimeout = const Duration(seconds: 5),
}) async {
  final toolkit = MacosWindowToolkit();
  
  try {
    if (tryGracefulFirst) {
      print('Attempting graceful termination...');
      final success = await toolkit.terminateApplicationByPID(processId);
      
      if (success) {
        // Wait a moment to see if process actually terminates
        await Future.delayed(Duration(seconds: 1));
        
        // Check if process is still running
        final windows = await toolkit.getWindowsByProcessId(processId);
        if (windows.isEmpty) {
          print('✅ Graceful termination successful');
          return true;
        } else {
          print('⚠️ Process still running after graceful termination');
        }
      }
      
      // Graceful failed, try force termination
      print('Attempting force termination...');
      return await toolkit.terminateApplicationByPID(processId, force: true);
    } else {
      // Direct force termination
      return await toolkit.terminateApplicationByPID(processId, force: true);
    }
    
  } on PlatformException catch (e) {
    switch (e.code) {
      case 'PROCESS_NOT_FOUND':
        print('Process $processId no longer exists');
        return true; // Consider it successful if already gone
        
      case 'TERMINATION_FAILED':
        print('System failed to terminate process: ${e.message}');
        return false;
        
      case 'TERMINATE_APP_ERROR':
        print('Application termination error: ${e.message}');
        return false;
        
      default:
        print('Unexpected error: ${e.code} - ${e.message}');
        return false;
    }
  } catch (e) {
    print('Unexpected error terminating process: $e');
    return false;
  }
}
```

**Use Cases:**
- Closing unresponsive applications
- Security applications (terminating potentially malicious processes)
- System administration tools
- Application lifecycle management

**Important Notes:**
- Does not require accessibility permissions
- Works at the process level, not window level
- Graceful termination is always preferred when possible
- Force termination may result in data loss

---

### `terminateApplicationTree()`

Terminates an application and all its child processes.

**Signature:**
```dart
Future<bool> terminateApplicationTree(
  int processId, {
  bool force = false,
})
```

**Parameters:**
- `processId` - Process ID of the parent application to terminate
- `force` (optional) - Termination method for all processes. Defaults to `false`.

**Returns:**
- `Future<bool>` - `true` if all processes were successfully terminated, `false` if any failed

**Throws:**
- `PlatformException` with error codes:
  - `TERMINATE_TREE_ERROR` - Process tree termination failed
  - `PROCESS_NOT_FOUND` - Parent process does not exist
  - `FAILED_TO_GET_PROCESS_LIST` - Unable to retrieve system process list

**Termination Process:**
1. **Discovery**: Identifies all child processes using system process list
2. **Child Termination**: Terminates child processes first (bottom-up approach)
3. **Parent Termination**: Finally terminates the parent process

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Find a complex application with likely child processes
final windows = await toolkit.getAllWindows();
final electronApp = windows.firstWhere(
  (w) => w.ownerName.contains('Electron') || 
         w.ownerName.contains('Visual Studio Code') ||
         w.ownerName.contains('Discord'),
  orElse: () => throw StateError('No Electron app found'),
);

print('Terminating ${electronApp.ownerName} and all child processes...');
print('Parent PID: ${electronApp.processId}');

// Get child processes first for information
final childPIDs = await toolkit.getChildProcesses(electronApp.processId);
print('Found ${childPIDs.length} child processes: $childPIDs');

// Terminate entire process tree
try {
  final success = await toolkit.terminateApplicationTree(
    electronApp.processId,
    force: false, // Try graceful first
  );
  
  if (success) {
    print('✅ Successfully terminated application tree');
    print('Parent and ${childPIDs.length} children terminated');
  } else {
    print('❌ Some processes failed to terminate');
    
    // Try force termination as fallback
    print('Retrying with force termination...');
    final forceSuccess = await toolkit.terminateApplicationTree(
      electronApp.processId,
      force: true,
    );
    
    print(forceSuccess 
          ? '✅ Force termination successful' 
          : '❌ Force termination failed');
  }
  
} on PlatformException catch (e) {
  switch (e.code) {
    case 'PROCESS_NOT_FOUND':
      print('Parent process no longer exists');
      break;
    case 'FAILED_TO_GET_PROCESS_LIST':
      print('Unable to query system process list');
      break;
    default:
      print('Error: ${e.code} - ${e.message}');
  }
}
```

**Advanced Process Tree Management:**
```dart
class ProcessTreeManager {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<ProcessTreeInfo> analyzeProcessTree(int parentPid) async {
    // Get all child processes
    final children = await toolkit.getChildProcesses(parentPid);
    
    // Build tree structure
    final tree = ProcessTreeInfo(
      parentPid: parentPid,
      childPids: children,
      totalProcesses: 1 + children.length,
    );
    
    // Get process information from windows if available
    for (final childPid in children) {
      final windows = await toolkit.getWindowsByProcessId(childPid);
      if (windows.isNotEmpty) {
        tree.processNames[childPid] = windows.first.ownerName;
      }
    }
    
    return tree;
  }
  
  Future<bool> terminateTreeSafely(
    int parentPid, {
    bool confirmBeforeForce = true,
    Duration gracefulWaitTime = const Duration(seconds: 3),
  }) async {
    // Analyze tree first
    final treeInfo = await analyzeProcessTree(parentPid);
    print('Process tree analysis:');
    print('- Parent PID: $parentPid');
    print('- Child processes: ${treeInfo.childPids.length}');
    print('- Total processes: ${treeInfo.totalProcesses}');
    
    // Try graceful termination
    print('Attempting graceful termination of process tree...');
    bool success = await toolkit.terminateApplicationTree(parentPid);
    
    if (success) {
      print('✅ Graceful termination successful');
      return true;
    }
    
    // Wait a moment before checking
    await Future.delayed(gracefulWaitTime);
    
    // Check if any processes are still running
    final remainingChildren = await toolkit.getChildProcesses(parentPid);
    if (remainingChildren.isEmpty) {
      print('✅ All processes terminated after grace period');
      return true;
    }
    
    print('⚠️ ${remainingChildren.length} processes still running');
    
    if (confirmBeforeForce) {
      print('Force termination required. Proceeding...');
    }
    
    // Force termination as last resort
    success = await toolkit.terminateApplicationTree(parentPid, force: true);
    
    if (success) {
      print('✅ Force termination successful');
    } else {
      print('❌ Force termination failed');
    }
    
    return success;
  }
}

class ProcessTreeInfo {
  final int parentPid;
  final List<int> childPids;
  final int totalProcesses;
  final Map<int, String> processNames = {};
  
  ProcessTreeInfo({
    required this.parentPid,
    required this.childPids,
    required this.totalProcesses,
  });
}
```

**Use Cases:**
- **Security Applications**: Complete removal of potentially malicious software
- **System Cleanup**: Ensuring no orphaned child processes remain
- **Application Management**: Clean shutdown of complex applications
- **Development Tools**: Stopping entire development environments

**Important Notes:**
- More thorough than single process termination
- Prevents orphaned child processes
- Essential for applications that spawn multiple processes
- Bottom-up termination order prevents race conditions

---

### `getChildProcesses()`

Gets all child process IDs for a given parent process ID.

**Signature:**
```dart
Future<List<int>> getChildProcesses(int processId)
```

**Parameters:**
- `processId` - Process ID of the parent process

**Returns:**
- `Future<List<int>>` - List of child process IDs (empty if none found)

**Throws:**
- `PlatformException` with error codes:
  - `GET_CHILD_PROCESSES_ERROR` - Failed to retrieve child processes
  - `FAILED_TO_GET_PROCESS_LIST` - Unable to retrieve system process list

**Implementation:**
- Queries system process table directly
- Identifies parent-child relationships using process hierarchy
- Does not require elevated privileges

**Example:**
```dart
final toolkit = MacosWindowToolkit();

// Find a browser process (likely to have children)
final windows = await toolkit.getAllWindows();
final browserWindow = windows.firstWhere(
  (w) => w.ownerName.contains('Chrome') || 
         w.ownerName.contains('Safari') ||
         w.ownerName.contains('Firefox'),
  orElse: () => throw StateError('No browser found'),
);

print('Analyzing process tree for ${browserWindow.ownerName}');
print('Parent PID: ${browserWindow.processId}');

try {
  final childPIDs = await toolkit.getChildProcesses(browserWindow.processId);
  
  if (childPIDs.isEmpty) {
    print('No child processes found');
  } else {
    print('Found ${childPIDs.length} child processes:');
    
    for (final childPID in childPIDs) {
      // Try to get process information from windows
      final childWindows = await toolkit.getWindowsByProcessId(childPID);
      
      if (childWindows.isNotEmpty) {
        final childApp = childWindows.first.ownerName;
        print('- Child PID $childPID: $childApp');
        
        // Check for grandchildren
        final grandchildren = await toolkit.getChildProcesses(childPID);
        if (grandchildren.isNotEmpty) {
          print('  └─ ${grandchildren.length} grandchildren: $grandchildren');
        }
      } else {
        print('- Child PID $childPID: (no windows)');
      }
    }
  }
  
} on PlatformException catch (e) {
  switch (e.code) {
    case 'FAILED_TO_GET_PROCESS_LIST':
      print('Unable to access system process list');
      break;
    default:
      print('Error getting child processes: ${e.code} - ${e.message}');
  }
}
```

**Advanced Process Analysis:**
```dart
class ProcessAnalyzer {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<ProcessHierarchy> buildProcessHierarchy(int rootPid) async {
    final hierarchy = ProcessHierarchy(rootPid);
    await _buildHierarchyRecursive(hierarchy, rootPid, 0);
    return hierarchy;
  }
  
  Future<void> _buildHierarchyRecursive(
    ProcessHierarchy hierarchy,
    int pid,
    int depth,
  ) async {
    if (depth > 10) { // Prevent infinite recursion
      print('Warning: Maximum depth reached for PID $pid');
      return;
    }
    
    try {
      final children = await toolkit.getChildProcesses(pid);
      
      for (final childPid in children) {
        // Get process info if available
        final windows = await toolkit.getWindowsByProcessId(childPid);
        final processName = windows.isNotEmpty 
            ? windows.first.ownerName 
            : 'Unknown';
        
        final node = ProcessNode(
          pid: childPid,
          name: processName,
          depth: depth + 1,
        );
        
        hierarchy.addProcess(node);
        
        // Recursively build children
        await _buildHierarchyRecursive(hierarchy, childPid, depth + 1);
      }
      
    } catch (e) {
      print('Error analyzing PID $pid: $e');
    }
  }
  
  Future<void> printProcessTree(int rootPid) async {
    final hierarchy = await buildProcessHierarchy(rootPid);
    
    print('Process Tree for PID $rootPid:');
    print('└─ Root Process ($rootPid)');
    
    for (final process in hierarchy.processes) {
      final indent = '   ' * process.depth;
      final connector = process.depth > 0 ? '└─ ' : '';
      print('$indent$connector${process.name} (${process.pid})');
    }
    
    print('\nSummary:');
    print('- Total processes: ${hierarchy.totalProcesses}');
    print('- Maximum depth: ${hierarchy.maxDepth}');
    print('- Leaf processes: ${hierarchy.leafProcesses.length}');
  }
}

class ProcessHierarchy {
  final int rootPid;
  final List<ProcessNode> processes = [];
  
  ProcessHierarchy(this.rootPid);
  
  void addProcess(ProcessNode node) {
    processes.add(node);
  }
  
  int get totalProcesses => processes.length + 1; // +1 for root
  
  int get maxDepth => processes.isEmpty 
      ? 0 
      : processes.map((p) => p.depth).reduce(math.max);
  
  List<ProcessNode> get leafProcesses {
    final leafPids = <int>{};
    final parentPids = processes.map((p) => p.pid).toSet();
    
    // A leaf process has no children in our hierarchy
    for (final process in processes) {
      final hasChildren = processes.any((p) => 
          p.depth == process.depth + 1 && 
          parentPids.contains(process.pid));
      
      if (!hasChildren) {
        leafPids.add(process.pid);
      }
    }
    
    return processes.where((p) => leafPids.contains(p.pid)).toList();
  }
}

class ProcessNode {
  final int pid;
  final String name;
  final int depth;
  
  ProcessNode({
    required this.pid,
    required this.name,
    required this.depth,
  });
}

// Usage
final analyzer = ProcessAnalyzer();
await analyzer.printProcessTree(browserWindow.processId);
```

**Security Use Cases:**
```dart
class SecurityProcessMonitor {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  
  Future<List<SuspiciousProcess>> findSuspiciousProcessTrees() async {
    final suspicious = <SuspiciousProcess>[];
    
    // Get all windows to analyze their processes
    final windows = await toolkit.getAllWindows();
    final processIds = windows.map((w) => w.processId).toSet();
    
    for (final pid in processIds) {
      try {
        final children = await toolkit.getChildProcesses(pid);
        
        // Flag processes with many children (potential fork bombs)
        if (children.length > 50) {
          suspicious.add(SuspiciousProcess(
            pid: pid,
            reason: 'Excessive child processes (${children.length})',
            severity: SuspiciousSeverity.high,
            childCount: children.length,
          ));
        }
        
        // Flag processes spawning children rapidly
        await Future.delayed(Duration(seconds: 1));
        final newChildren = await toolkit.getChildProcesses(pid);
        final newChildrenCount = newChildren.length - children.length;
        
        if (newChildrenCount > 10) {
          suspicious.add(SuspiciousProcess(
            pid: pid,
            reason: 'Rapid child process spawning ($newChildrenCount/second)',
            severity: SuspiciousSeverity.critical,
            childCount: newChildren.length,
          ));
        }
        
      } catch (e) {
        // Skip processes we can't analyze
        continue;
      }
    }
    
    return suspicious;
  }
  
  Future<bool> quarantineSuspiciousProcess(SuspiciousProcess suspicious) async {
    print('🚨 Quarantining suspicious process PID ${suspicious.pid}');
    print('   Reason: ${suspicious.reason}');
    
    try {
      // Terminate entire process tree to prevent escape
      final success = await toolkit.terminateApplicationTree(
        suspicious.pid,
        force: true, // Use force for security threats
      );
      
      if (success) {
        print('✅ Successfully quarantined process tree');
      } else {
        print('❌ Failed to quarantine process tree');
      }
      
      return success;
      
    } catch (e) {
      print('❌ Error quarantining process: $e');
      return false;
    }
  }
}

class SuspiciousProcess {
  final int pid;
  final String reason;
  final SuspiciousSeverity severity;
  final int childCount;
  
  SuspiciousProcess({
    required this.pid,
    required this.reason,
    required this.severity,
    required this.childCount,
  });
}

enum SuspiciousSeverity {
  low,
  medium,
  high,
  critical,
}
```

**Use Cases:**
- **Process Monitoring**: Understanding application architecture
- **Security Analysis**: Detecting suspicious process behavior
- **System Administration**: Managing complex application hierarchies
- **Development Tools**: Debugging multi-process applications
- **Resource Management**: Identifying resource-intensive process trees

**Performance:**
- Lightweight operation (~5-10ms per process)
- Scales linearly with number of child processes
- Does not require special permissions

---

## Complete Usage Examples

### Process Management Dashboard

```dart
class ProcessManagerWidget extends StatefulWidget {
  @override
  _ProcessManagerWidgetState createState() => _ProcessManagerWidgetState();
}

class _ProcessManagerWidgetState extends State<ProcessManagerWidget> {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  List<ProcessInfo> processes = [];
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadProcesses();
  }
  
  Future<void> _loadProcesses() async {
    setState(() => isLoading = true);
    
    try {
      // Get all windows to find processes
      final windows = await toolkit.getAllWindows();
      final processMap = <int, ProcessInfo>{};
      
      // Group windows by process
      for (final window in windows) {
        if (!processMap.containsKey(window.processId)) {
          processMap[window.processId] = ProcessInfo(
            pid: window.processId,
            name: window.ownerName,
            windows: [],
          );
        }
        processMap[window.processId]!.windows.add(window);
      }
      
      // Get child processes for each
      for (final processInfo in processMap.values) {
        try {
          final children = await toolkit.getChildProcesses(processInfo.pid);
          processInfo.childPids = children;
        } catch (e) {
          print('Error getting children for ${processInfo.pid}: $e');
        }
      }
      
      setState(() {
        processes = processMap.values.toList()
          ..sort((a, b) => b.childPids.length.compareTo(a.childPids.length));
      });
      
    } catch (e) {
      _showError('Failed to load processes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  Future<void> _terminateProcess(ProcessInfo process, bool force) async {
    final confirmed = await _showTerminationDialog(process, force);
    if (!confirmed) return;
    
    setState(() => isLoading = true);
    
    try {
      final success = process.childPids.isNotEmpty
          ? await toolkit.terminateApplicationTree(process.pid, force: force)
          : await toolkit.terminateApplicationByPID(process.pid, force: force);
      
      if (success) {
        _showSuccess('${process.name} terminated successfully');
        await _loadProcesses(); // Refresh list
      } else {
        _showError('Failed to terminate ${process.name}');
      }
      
    } catch (e) {
      _showError('Error terminating process: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Process Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProcesses,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: processes.length,
              itemBuilder: (context, index) {
                final process = processes[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    title: Text(process.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PID: ${process.pid}'),
                        Text('Windows: ${process.windows.length}'),
                        if (process.childPids.isNotEmpty)
                          Text('Child processes: ${process.childPids.length}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.orange),
                          onPressed: () => _terminateProcess(process, false),
                          tooltip: 'Graceful termination',
                        ),
                        IconButton(
                          icon: Icon(Icons.power_off, color: Colors.red),
                          onPressed: () => _terminateProcess(process, true),
                          tooltip: 'Force termination',
                        ),
                      ],
                    ),
                    children: [
                      // Windows
                      if (process.windows.isNotEmpty) ...[
                        ListTile(
                          title: Text('Windows'),
                          dense: true,
                        ),
                        ...process.windows.map((window) => ListTile(
                          title: Text(window.name.isEmpty ? '(No title)' : window.name),
                          subtitle: Text('${window.width.round()} × ${window.height.round()}'),
                          contentPadding: EdgeInsets.only(left: 32),
                          dense: true,
                        )),
                      ],
                      
                      // Child processes
                      if (process.childPids.isNotEmpty) ...[
                        ListTile(
                          title: Text('Child Processes'),
                          dense: true,
                        ),
                        ...process.childPids.map((childPid) => ListTile(
                          title: Text('PID: $childPid'),
                          contentPadding: EdgeInsets.only(left: 32),
                          dense: true,
                        )),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
  
  Future<bool> _showTerminationDialog(ProcessInfo process, bool force) async {
    final action = force ? 'force terminate' : 'gracefully terminate';
    final warning = force 
        ? 'This will immediately kill the process and may cause data loss.'
        : 'This will ask the application to quit gracefully.';
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terminate Process'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to $action "${process.name}"?'),
            SizedBox(height: 8),
            Text('PID: ${process.pid}'),
            if (process.childPids.isNotEmpty)
              Text('This will also terminate ${process.childPids.length} child processes.'),
            SizedBox(height: 8),
            Text(warning, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: force ? Colors.red : Colors.orange,
            ),
            child: Text(force ? 'Force Terminate' : 'Terminate'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class ProcessInfo {
  final int pid;
  final String name;
  final List<MacosWindowInfo> windows;
  List<int> childPids = [];
  
  ProcessInfo({
    required this.pid,
    required this.name,
    required this.windows,
  });
}
```

### Security Monitor

```dart
class SecurityMonitor {
  final MacosWindowToolkit toolkit = MacosWindowToolkit();
  Timer? _monitoringTimer;
  final StreamController<SecurityAlert> _alertController = 
      StreamController<SecurityAlert>.broadcast();
  
  Stream<SecurityAlert> get alertStream => _alertController.stream;
  
  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(interval, (_) => _checkSecurity());
    print('🔒 Security monitoring started (${interval.inSeconds}s interval)');
  }
  
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    print('🔒 Security monitoring stopped');
  }
  
  Future<void> _checkSecurity() async {
    try {
      await _checkProcessSpawning();
      await _checkSuspiciousProcessTrees();
    } catch (e) {
      print('Security check error: $e');
    }
  }
  
  Future<void> _checkProcessSpawning() async {
    final windows = await toolkit.getAllWindows();
    final processIds = windows.map((w) => w.processId).toSet();
    
    for (final pid in processIds) {
      try {
        final children = await toolkit.getChildProcesses(pid);
        
        // Flag excessive child processes (potential fork bomb)
        if (children.length > 100) {
          final appName = windows.firstWhere((w) => w.processId == pid).ownerName;
          
          _alertController.add(SecurityAlert(
            type: SecurityAlertType.excessiveChildProcesses,
            processId: pid,
            processName: appName,
            message: '$appName has ${children.length} child processes',
            severity: SecuritySeverity.high,
            childCount: children.length,
          ));
        }
        
      } catch (e) {
        // Skip processes we can't analyze
        continue;
      }
    }
  }
  
  Future<void> _checkSuspiciousProcessTrees() async {
    // Implementation for detecting suspicious process behavior
    // This is a simplified example - real security monitoring would be more sophisticated
  }
  
  Future<void> quarantineProcess(int pid, String reason) async {
    print('🚨 QUARANTINE: Terminating process $pid - $reason');
    
    try {
      final success = await toolkit.terminateApplicationTree(pid, force: true);
      if (success) {
        print('✅ Process $pid quarantined successfully');
      } else {
        print('❌ Failed to quarantine process $pid');
      }
    } catch (e) {
      print('❌ Error quarantining process $pid: $e');
    }
  }
  
  void dispose() {
    stopMonitoring();
    _alertController.close();
  }
}

class SecurityAlert {
  final SecurityAlertType type;
  final int processId;
  final String processName;
  final String message;
  final SecuritySeverity severity;
  final DateTime timestamp;
  final int? childCount;
  
  SecurityAlert({
    required this.type,
    required this.processId,
    required this.processName,
    required this.message,
    required this.severity,
    this.childCount,
  }) : timestamp = DateTime.now();
}

enum SecurityAlertType {
  excessiveChildProcesses,
  rapidProcessSpawning,
  suspiciousProcessTree,
  unknownProcess,
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}
```

## Best Practices

### Safety Considerations

```dart
// ✅ Good: Always try graceful termination first
Future<bool> safeTerminate(int pid) async {
  bool success = await toolkit.terminateApplicationByPID(pid);
  if (!success) {
    // Only use force as last resort
    success = await toolkit.terminateApplicationByPID(pid, force: true);
  }
  return success;
}

// ❌ Avoid: Force termination as first choice
// await toolkit.terminateApplicationByPID(pid, force: true);
```

### Error Handling

```dart
Future<void> terminateWithRetry(
  int pid, {
  int maxRetries = 3,
  Duration retryDelay = const Duration(seconds: 1),
}) async {
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      final success = await toolkit.terminateApplicationByPID(pid);
      if (success) {
        print('✅ Process terminated on attempt ${attempt + 1}');
        return;
      }
    } on PlatformException catch (e) {
      if (e.code == 'PROCESS_NOT_FOUND') {
        print('Process already terminated');
        return;
      }
      
      if (attempt == maxRetries - 1) {
        print('❌ Final attempt failed: ${e.message}');
        rethrow;
      }
      
      print('⚠️ Attempt ${attempt + 1} failed, retrying...');
      await Future.delayed(retryDelay);
    }
  }
  
  print('❌ All attempts failed');
}
```

### Resource Management

```dart
class ProcessManager {
  final Set<int> _managedProcesses = {};
  
  Future<void> trackProcess(int pid) async {
    _managedProcesses.add(pid);
  }
  
  Future<void> cleanupAllProcesses() async {
    for (final pid in _managedProcesses) {
      try {
        await toolkit.terminateApplicationByPID(pid);
      } catch (e) {
        print('Failed to cleanup process $pid: $e');
      }
    }
    _managedProcesses.clear();
  }
}
```

## Thread Safety

All process management methods are thread-safe and can be called from any isolate.

## Security Considerations

- Process termination can result in data loss if forced
- Always prefer graceful termination when possible
- Be cautious with system processes
- Consider user confirmation for critical applications
- Monitor for abuse of termination capabilities

## Related APIs

- **[Window Management](window_management.md)** - Get process IDs from windows
- **[Permission Management](permission_management.md)** - No special permissions required
- **[Error Handling](error_handling.md)** - Handle process management errors

---

[← Back to API Reference](../api_reference.md)