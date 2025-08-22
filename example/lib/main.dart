import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> _windows = [];
  bool _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('macOS Window Toolkit Demo'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _getAllWindows,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Get All Windows'),
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
      ),
    );
  }
}
