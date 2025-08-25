import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

import 'widgets/capturable_windows_tab.dart';
import 'widgets/legacy_windows_tab.dart';
import 'widgets/permissions_status_card.dart';
import 'widgets/search_controls.dart';
import 'widgets/smart_capture_tab.dart';
import 'widgets/version_info_card.dart';
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
      home: const MainTabView(),
    );
  }
}

class MainTabView extends StatelessWidget {
  const MainTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('macOS Window Toolkit'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.window), text: 'All Windows'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'Smart Capture'),
              Tab(icon: Icon(Icons.camera_alt), text: 'ScreenCaptureKit'),
              Tab(icon: Icon(Icons.camera), text: 'Legacy Capture'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [WindowDemoPage(), SmartCaptureTab(), CapturableWindowsTab(), LegacyWindowsTab()],
        ),
      ),
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
  bool? _hasScreenRecordingPermission;
  bool? _hasAccessibilityPermission;
  MacosVersionInfo? _versionInfo;
  final _macosWindowToolkitPlugin = MacosWindowToolkit();
  final _searchController = TextEditingController();
  Timer? _refreshTimer;
  bool _autoRefresh = false;

  @override
  void initState() {
    super.initState();
    _checkScreenRecordingPermission();
    _checkAccessibilityPermission();
    _getVersionInfo();
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

  Future<void> _checkScreenRecordingPermission() async {
    try {
      final hasPermission = await _macosWindowToolkitPlugin
          .hasScreenRecordingPermission();
      setState(() {
        _hasScreenRecordingPermission = hasPermission;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking screen recording permission: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkAccessibilityPermission() async {
    try {
      final hasPermission = await _macosWindowToolkitPlugin
          .hasAccessibilityPermission();
      setState(() {
        _hasAccessibilityPermission = hasPermission;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking accessibility permission: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _getVersionInfo() async {
    try {
      final versionInfo = await _macosWindowToolkitPlugin.getMacOSVersionInfo();
      setState(() {
        _versionInfo = versionInfo;
      });
    } on PlatformException catch (e) {
      print('Error getting version info: ${e.message}');
    }
  }

  Future<void> _requestScreenRecordingPermission() async {
    try {
      final granted = await _macosWindowToolkitPlugin
          .requestScreenRecordingPermission();
      setState(() {
        _hasScreenRecordingPermission = granted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Screen recording permission granted! You may need to restart the app.'
                  : 'Screen recording permission denied. Window names may not be available.',
            ),
            backgroundColor: granted ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting screen recording permission: ${e.message}')),
        );
      }
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    try {
      final granted = await _macosWindowToolkitPlugin
          .requestAccessibilityPermission();
      setState(() {
        _hasAccessibilityPermission = granted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Accessibility permission granted!'
                  : 'Accessibility permission not granted. Please enable it in System Preferences.',
            ),
            backgroundColor: granted ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting accessibility permission: ${e.message}')),
        );
      }
    }
  }

  Future<void> _openScreenRecordingSettings() async {
    try {
      final success = await _macosWindowToolkitPlugin
          .openScreenRecordingSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Opening System Preferences - please enable screen recording.'
                  : 'Failed to open System Preferences. Please open it manually.',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 3),
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

  Future<void> _openAccessibilitySettings() async {
    try {
      final success = await _macosWindowToolkitPlugin
          .openAccessibilitySettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Opening System Preferences - please enable accessibility.'
                  : 'Failed to open System Preferences. Please open it manually.',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening accessibility settings: ${e.message}')),
        );
      }
    }
  }

  void _requestMostCriticalPermission() {
    // Prioritize screen recording permission as it's needed for basic functionality
    if (_hasScreenRecordingPermission == false) {
      _requestScreenRecordingPermission();
    } else if (_hasAccessibilityPermission == false) {
      _requestAccessibilityPermission();
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
        title: const Text('All Windows'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Permissions Status Card
            PermissionsStatusCard(
              hasScreenRecordingPermission: _hasScreenRecordingPermission,
              hasAccessibilityPermission: _hasAccessibilityPermission,
              onOpenScreenRecordingSettings: _openScreenRecordingSettings,
              onOpenAccessibilitySettings: _openAccessibilitySettings,
              onRequestScreenRecordingPermission: _requestScreenRecordingPermission,
              onRequestAccessibilityPermission: _requestAccessibilityPermission,
            ),

            // Version Info Card
            VersionInfoCard(versionInfo: _versionInfo),

            // Search and Controls
            SearchControls(
              searchController: _searchController,
              totalWindows: _windows.length,
              filteredWindows: _filteredWindows.length,
              autoRefresh: _autoRefresh,
              onToggleAutoRefresh: _toggleAutoRefresh,
            ),

            // Windows List
            SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  400, // Adjust based on other widgets
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
      ),
      floatingActionButton: (_hasScreenRecordingPermission == false || _hasAccessibilityPermission == false)
          ? FloatingActionButton.extended(
              onPressed: _requestMostCriticalPermission,
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
