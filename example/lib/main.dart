import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';
import 'package:macos_window_toolkit_example/widgets/permission_setup_page.dart';

import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'services/version_service.dart';
import 'services/window_service.dart';
import 'widgets/capturable_windows_tab.dart';
import 'widgets/legacy_windows_tab.dart';
import 'widgets/permissions_status_card.dart';
import 'widgets/search_controls.dart';
import 'widgets/smart_capture_tab.dart';
import 'widgets/version_info_card.dart';
import 'widgets/window_detail_sheet.dart';
import 'widgets/windows_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final plugin = MacosWindowToolkit();
  bool hasPermissions = false;

  try {
    final screenRecording = await plugin.hasScreenRecordingPermission();
    final accessibility = await plugin.hasAccessibilityPermission();
    hasPermissions = screenRecording && accessibility;
  } catch (e) {
    // 권한 확인 실패시 기본값 false로 권한 설정 페이지로 이동
    hasPermissions = false;
  }

  runApp(MyApp(hasInitialPermissions: hasPermissions));
}

class MyApp extends StatelessWidget {
  final bool hasInitialPermissions;

  const MyApp({super.key, required this.hasInitialPermissions});

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
      initialRoute: hasInitialPermissions ? '/main' : '/permission',
      routes: {
        '/main': (context) => const MainTabView(),
        '/permission': (context) => const PermissionSetupPage(),
      },
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
          children: [
            WindowDemoPage(),
            SmartCaptureTab(),
            CapturableWindowsTab(),
            LegacyWindowsTab(),
          ],
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
  final _searchController = TextEditingController();

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
    WindowService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterWindows() {
    setState(() {
      _filteredWindows = WindowService.filterWindows(
        _windows,
        _searchController.text,
      );
    });
  }

  void _toggleAutoRefresh() {
    WindowService.toggleAutoRefresh(
      onRefresh: () {
        if (!_isLoading) _getAllWindows();
      },
    );
    setState(() {}); // Trigger rebuild to update UI
  }

  Future<void> _getAllWindows() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final windows = await WindowService.getAllWindows();
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
        NotificationService.handlePlatformException(
          context,
          e,
          'getting windows',
        );
      }
    }
  }

  Future<void> _checkScreenRecordingPermission() async {
    final hasPermission =
        await PermissionService.checkScreenRecordingPermission();
    setState(() {
      _hasScreenRecordingPermission = hasPermission;
    });

    if (hasPermission == null && mounted) {
      NotificationService.showError(
        context,
        'Error checking screen recording permission',
      );
    }
  }

  Future<void> _checkAccessibilityPermission() async {
    final hasPermission =
        await PermissionService.checkAccessibilityPermission();
    setState(() {
      _hasAccessibilityPermission = hasPermission;
    });

    if (hasPermission == null && mounted) {
      NotificationService.showError(
        context,
        'Error checking accessibility permission',
      );
    }
  }

  Future<void> _getVersionInfo() async {
    final versionInfo = await VersionService.getMacOSVersionInfo();
    setState(() {
      _versionInfo = versionInfo;
    });
  }

  Future<void> _requestScreenRecordingPermission() async {
    final granted = await PermissionService.requestScreenRecordingPermission();

    if (granted != null) {
      setState(() {
        _hasScreenRecordingPermission = granted;
      });

      if (mounted) {
        NotificationService.showPermissionResult(
          context,
          granted: granted,
          permissionName: 'Screen recording',
          additionalInfo: granted
              ? 'You may need to restart the app.'
              : 'Window names may not be available.',
        );
      }
    } else if (mounted) {
      NotificationService.showError(
        context,
        'Error requesting screen recording permission',
      );
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    final granted = await PermissionService.requestAccessibilityPermission();

    if (granted != null) {
      setState(() {
        _hasAccessibilityPermission = granted;
      });

      if (mounted) {
        NotificationService.showPermissionResult(
          context,
          granted: granted,
          permissionName: 'Accessibility',
          additionalInfo: granted
              ? null
              : 'Please enable it in System Preferences.',
        );
      }
    } else if (mounted) {
      NotificationService.showError(
        context,
        'Error requesting accessibility permission',
      );
    }
  }

  Future<void> _openScreenRecordingSettings() async {
    final success = await PermissionService.openScreenRecordingSettings();

    if (success != null && mounted) {
      NotificationService.showSettingsResult(
        context,
        success: success,
        settingsType: 'screen recording',
      );
    } else if (mounted) {
      NotificationService.showError(
        context,
        'Error opening screen recording settings',
      );
    }
  }

  Future<void> _openAccessibilitySettings() async {
    final success = await PermissionService.openAccessibilitySettings();

    if (success != null && mounted) {
      NotificationService.showSettingsResult(
        context,
        success: success,
        settingsType: 'accessibility',
      );
    } else if (mounted) {
      NotificationService.showError(
        context,
        'Error opening accessibility settings',
      );
    }
  }

  void _requestMostCriticalPermission() {
    final criticalPermission =
        PermissionService.getMostCriticalMissingPermission(
          hasScreenRecording: _hasScreenRecordingPermission,
          hasAccessibility: _hasAccessibilityPermission,
        );

    switch (criticalPermission) {
      case PermissionType.screenRecording:
        _requestScreenRecordingPermission();
        break;
      case PermissionType.accessibility:
        _requestAccessibilityPermission();
        break;
      case null:
        break;
    }
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
            icon: Icon(
              WindowService.isAutoRefreshEnabled ? Icons.pause : Icons.refresh,
            ),
            onPressed: _toggleAutoRefresh,
            tooltip: WindowService.isAutoRefreshEnabled
                ? 'Stop Auto-refresh'
                : 'Start Auto-refresh',
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
              onRequestScreenRecordingPermission:
                  _requestScreenRecordingPermission,
              onRequestAccessibilityPermission: _requestAccessibilityPermission,
            ),

            // Version Info Card
            VersionInfoCard(versionInfo: _versionInfo),

            // Search and Controls
            SearchControls(
              searchController: _searchController,
              totalWindows: _windows.length,
              filteredWindows: _filteredWindows.length,
              autoRefresh: WindowService.isAutoRefreshEnabled,
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
                formatBytes: WindowService.formatBytes,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          PermissionService.hasAnyMissingPermission(
            hasScreenRecording: _hasScreenRecordingPermission,
            hasAccessibility: _hasAccessibilityPermission,
          )
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
    WindowDetailSheet.show(
      context,
      window,
      WindowService.getSharingStateText,
      WindowService.formatBytes,
    );
  }
}
