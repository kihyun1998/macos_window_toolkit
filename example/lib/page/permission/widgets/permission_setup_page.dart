import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

import 'permission_tile.dart';

class PermissionSetupPage extends StatefulWidget {
  const PermissionSetupPage({super.key});

  @override
  State<PermissionSetupPage> createState() => _PermissionSetupPageState();
}

class _PermissionSetupPageState extends State<PermissionSetupPage>
    with WidgetsBindingObserver {
  final _plugin = MacosWindowToolkit();
  bool? _hasScreenRecordingPermission;
  bool? _hasAccessibilityPermission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final screenRecording = await _plugin.hasScreenRecordingPermission();
      final accessibility = await _plugin.hasAccessibilityPermission();

      setState(() {
        _hasScreenRecordingPermission = screenRecording;
        _hasAccessibilityPermission = accessibility;
      });

      if (screenRecording && accessibility && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permissions: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _requestScreenRecordingPermission() async {
    try {
      final granted = await _plugin.requestScreenRecordingPermission();
      setState(() {
        _hasScreenRecordingPermission = granted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Screen recording permission granted!'
                  : 'Screen recording permission denied.',
            ),
            backgroundColor: granted ? Colors.green : Colors.orange,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  Future<void> _requestAccessibilityPermission() async {
    try {
      final granted = await _plugin.requestAccessibilityPermission();
      setState(() {
        _hasAccessibilityPermission = granted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Accessibility permission granted!'
                  : 'Please enable accessibility permission in System Preferences.',
            ),
            backgroundColor: granted ? Colors.green : Colors.orange,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  Future<void> _openScreenRecordingSettings() async {
    try {
      await _plugin.openScreenRecordingSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opening System Preferences - enable Screen Recording and return to app',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _plugin.openAccessibilitySettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opening System Preferences - enable Accessibility and return to app',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 80, color: colorScheme.primary),
              const SizedBox(height: 32),
              Text(
                'Permissions Required',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This app needs screen recording and accessibility permissions to function properly.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Screen Recording Permission
              PermissionTile(
                title: 'Screen Recording',
                description: 'Required to access window information',
                icon: Icons.desktop_mac,
                hasPermission: _hasScreenRecordingPermission,
                onRequest: _requestScreenRecordingPermission,
                onOpenSettings: _openScreenRecordingSettings,
              ),

              const SizedBox(height: 16),

              // Accessibility Permission
              PermissionTile(
                title: 'Accessibility',
                description: 'Required to interact with windows',
                icon: Icons.accessibility,
                hasPermission: _hasAccessibilityPermission,
                onRequest: _requestAccessibilityPermission,
                onOpenSettings: _openAccessibilitySettings,
              ),

              const SizedBox(height: 32),

              Text(
                'After enabling permissions in System Preferences, return to this app. Permissions will be detected automatically.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
