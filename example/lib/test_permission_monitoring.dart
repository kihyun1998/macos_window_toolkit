import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

/// Test page to demonstrate permission monitoring functionality
class TestPermissionMonitoring extends StatefulWidget {
  const TestPermissionMonitoring({super.key});

  @override
  State<TestPermissionMonitoring> createState() =>
      _TestPermissionMonitoringState();
}

class _TestPermissionMonitoringState extends State<TestPermissionMonitoring> {
  final MacosWindowToolkit _toolkit = MacosWindowToolkit();
  PermissionStatus? _lastPermissionStatus;
  List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();
    _setupPermissionListener();
  }

  @override
  void dispose() {
    _toolkit.stopPermissionWatching();
    super.dispose();
  }

  void _setupPermissionListener() {
    _toolkit.permissionStream.listen((status) {
      setState(() {
        _lastPermissionStatus = status;
        
        final timestamp = status.timestamp.toString().substring(11, 19);
        
        if (status.hasChanges) {
          _eventLog.insert(0, 
            '[$timestamp] CHANGE DETECTED - Screen: ${status.screenRecording}, '
            'Accessibility: ${status.accessibility}'
          );
        } else {
          _eventLog.insert(0, 
            '[$timestamp] Check - Screen: ${status.screenRecording}, '
            'Accessibility: ${status.accessibility}'
          );
        }
        
        // Keep only last 20 events
        if (_eventLog.length > 20) {
          _eventLog = _eventLog.take(20).toList();
        }
      });
    });
  }

  Widget _buildPermissionStatus(String name, bool? status) {
    Color color;
    String text;
    
    if (status == null) {
      color = Colors.grey;
      text = 'Unknown';
    } else if (status) {
      color = Colors.green;
      text = 'Granted';
    } else {
      color = Colors.red;
      text = 'Denied';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == true ? Icons.check_circle : Icons.error,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$name: $text',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Monitoring Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control Panel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _toolkit.startPermissionWatching(
                              interval: const Duration(seconds: 2),
                              emitOnlyChanges: true, // 기본값: 변경시만 emit
                            );
                            setState(() {
                              _eventLog.insert(0, 
                                '[${DateTime.now().toString().substring(11, 19)}] '
                                'Monitoring STARTED (2s interval, changes only)'
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Monitoring'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            _toolkit.startPermissionWatching(
                              interval: const Duration(seconds: 2),
                              emitOnlyChanges: false, // 모든 체크마다 emit
                            );
                            setState(() {
                              _eventLog.insert(0, 
                                '[${DateTime.now().toString().substring(11, 19)}] '
                                'Monitoring STARTED (2s interval, with heartbeat)'
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Heartbeat'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            _toolkit.stopPermissionWatching();
                            setState(() {
                              _eventLog.insert(0, 
                                '[${DateTime.now().toString().substring(11, 19)}] '
                                'Monitoring STOPPED'
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Stop Monitoring'),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8
                          ),
                          decoration: BoxDecoration(
                            color: _toolkit.isPermissionWatching 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Status: ${_toolkit.isPermissionWatching ? "ACTIVE" : "INACTIVE"}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _toolkit.isPermissionWatching 
                                ? Colors.green.shade700 
                                : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Permission Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Permission Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildPermissionStatus(
                          'Screen Recording', 
                          _lastPermissionStatus?.screenRecording
                        ),
                        const SizedBox(width: 16),
                        _buildPermissionStatus(
                          'Accessibility', 
                          _lastPermissionStatus?.accessibility
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Last updated: ${_lastPermissionStatus?.timestamp.toString() ?? 'Never'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        if (_lastPermissionStatus != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _lastPermissionStatus!.allPermissionsGranted 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _lastPermissionStatus!.allPermissionsGranted 
                                ? 'All Granted' 
                                : 'Missing: ${_lastPermissionStatus!.deniedPermissions.join(', ')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _lastPermissionStatus!.allPermissionsGranted 
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Event Log
            const Text(
              'Event Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: _eventLog.isEmpty
                  ? const Center(
                      child: Text(
                        'No events yet. Start monitoring to see permission checks.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _eventLog.length,
                      itemBuilder: (context, index) {
                        final event = _eventLog[index];
                        final isChangeEvent = event.contains('CHANGE DETECTED');
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: isChangeEvent 
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: isChangeEvent 
                                ? Colors.orange.shade700
                                : Colors.grey.shade700,
                              fontWeight: isChangeEvent 
                                ? FontWeight.w600 
                                : FontWeight.normal,
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
}