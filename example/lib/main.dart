import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

import 'widgets/permission_card.dart';
import 'widgets/search_controls.dart';
import 'widgets/window_detail_sheet.dart';
import 'widgets/windows_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'macOS Window Toolkit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
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
  List<MacosWindowInfo> _windows = [];
  List<MacosWindowInfo> _filteredWindows = [];
  bool _isLoading = false;
  bool? _hasPermission;
  final _macosWindowToolkitPlugin = MacosWindowToolkit();
  final _searchController = TextEditingController();
  Timer? _refreshTimer;
  bool _autoRefresh = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _searchController.addListener(_filterWindows);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterWindows() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredWindows = _windows.where((window) {
        return window.name.toLowerCase().contains(query) ||
            window.ownerName.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });

    if (_autoRefresh) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_isLoading) _getAllWindows();
      });
    } else {
      _refreshTimer?.cancel();
    }
  }

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
      _filterWindows();
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await _macosWindowToolkitPlugin
          .hasScreenRecordingPermission();
      setState(() {
        _hasPermission = hasPermission;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permission: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await _macosWindowToolkitPlugin
          .requestScreenRecordingPermission();
      setState(() {
        _hasPermission = granted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Permission granted! You may need to restart the app to see full window names.'
                  : 'Permission denied. Window names may not be available.',
            ),
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
      final success = await _macosWindowToolkitPlugin
          .openScreenRecordingSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'System Preferences opened. Please enable screen recording permission and restart the app.'
                  : 'Failed to open System Preferences. Please open it manually.',
            ),
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

  Future<void> _checkPermissionAndOpenSettings() async {
    try {
      final hasPermission = await _macosWindowToolkitPlugin
          .hasScreenRecordingPermission();

      if (hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screen recording permission is already granted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final success = await _macosWindowToolkitPlugin
            .openScreenRecordingSettings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'No permission detected. Opening System Preferences - please enable screen recording.'
                    : 'No permission detected. Failed to open System Preferences. Please open it manually.',
              ),
              backgroundColor: success ? Colors.orange : Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  String _getSharingStateText(int sharingState) {
    switch (sharingState) {
      case 0:
        return 'None';
      case 1:
        return 'ReadOnly';
      case 2:
        return 'ReadWrite';
      default:
        return 'Unknown($sharingState)';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('macOS Window Toolkit'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.refresh),
            onPressed: _toggleAutoRefresh,
            tooltip: _autoRefresh ? 'Stop Auto-refresh' : 'Start Auto-refresh',
          ),
          IconButton(
            icon: const Icon(Icons.window),
            onPressed: _isLoading ? null : _getAllWindows,
            tooltip: 'Refresh Windows',
          ),
        ],
      ),
      body: Column(
        children: [
          // Permission Status Card
          PermissionCard(
            hasPermission: _hasPermission,
            onOpenSettings: _openSettings,
          ),

          // Search and Controls
          SearchControls(
            searchController: _searchController,
            totalWindows: _windows.length,
            filteredWindows: _filteredWindows.length,
            autoRefresh: _autoRefresh,
            onToggleAutoRefresh: _toggleAutoRefresh,
          ),

          // Windows List
          Expanded(
            child: WindowsList(
              isLoading: _isLoading,
              windows: _windows,
              filteredWindows: _filteredWindows,
              searchQuery: _searchController.text,
              onRefresh: _getAllWindows,
              onWindowTap: _showWindowDetails,
              formatBytes: _formatBytes,
            ),
          ),
        ],
      ),
      floatingActionButton: _hasPermission == false
          ? FloatingActionButton.extended(
              onPressed: _requestPermission,
              icon: const Icon(Icons.security),
              label: const Text('Enable Permissions'),
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            )
          : null,
    );
  }

  void _showWindowDetails(MacosWindowInfo window) {
    WindowDetailSheet.show(context, window, _getSharingStateText, _formatBytes);
  }
}
