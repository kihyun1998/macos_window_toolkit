import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'macOS Window Toolkit Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WindowDemoPage(),
    );
  }
}

class WindowDemoPage extends StatefulWidget {
  const WindowDemoPage({super.key});

  @override
  State<WindowDemoPage> createState() => _WindowDemoPageState();
}

class _WindowDemoPageState extends State<WindowDemoPage> {
  List<Map<String, dynamic>> _windows = [];
  bool _isLoading = false;
  bool? _hasPermission;
  final _macosWindowToolkitPlugin = MacosWindowToolkit();

  Future<void> _getAllWindows() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final windows = await _macosWindowToolkitPlugin.getAllWindows();
      setState(() {
        _windows = windows;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await _macosWindowToolkitPlugin.hasScreenRecordingPermission();
      setState(() {
        _hasPermission = hasPermission;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasPermission 
                ? 'Screen recording permission is granted' 
                : 'Screen recording permission is NOT granted'),
            backgroundColor: hasPermission ? Colors.green : Colors.orange,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking permission: ${e.message}')),
        );
      }
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await _macosWindowToolkitPlugin.requestScreenRecordingPermission();
      setState(() {
        _hasPermission = granted;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted 
                ? 'Permission granted! You may need to restart the app to see full window names.'
                : 'Permission denied. Window names may not be available.'),
            backgroundColor: granted ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting permission: ${e.message}')),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    try {
      final success = await _macosWindowToolkitPlugin.openScreenRecordingSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'System Preferences opened. Please enable screen recording permission and restart the app.'
                : 'Failed to open System Preferences. Please open it manually.'),
            backgroundColor: success ? Colors.blue : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening settings: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('macOS Window Toolkit Demo'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Permission status indicator
              if (_hasPermission != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _hasPermission! ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _hasPermission! ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasPermission! ? Icons.check_circle : Icons.warning,
                        color: _hasPermission! ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hasPermission! 
                              ? 'Screen recording permission is granted'
                              : 'Screen recording permission is required for full window names',
                          style: TextStyle(
                            color: _hasPermission! ? Colors.green.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Permission buttons
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _checkPermission,
                    icon: const Icon(Icons.security),
                    label: const Text('Check Permission'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _requestPermission,
                    icon: const Icon(Icons.settings),
                    label: const Text('Request Permission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Get windows button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getAllWindows,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.window),
                label: const Text('Get All Windows'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              if (_windows.isNotEmpty) ...[
                Text('Found ${_windows.length} windows:'),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _windows.length,
                    itemBuilder: (context, index) {
                      final window = _windows[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(window['name']?.toString() ?? 'Untitled'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('App: ${window['ownerName'] ?? 'Unknown'}'),
                              Text('Window ID: ${window['windowId']}'),
                              Text('Process ID: ${window['processId']}'),
                              Text('Bounds: ${window['bounds']}'),
                              Text('Layer: ${window['layer']}, On Screen: ${window['isOnScreen']}'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }
}
