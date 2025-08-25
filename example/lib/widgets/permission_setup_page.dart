import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

import '../main.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  Future<void> _openScreenRecordingSettings() async {
    try {
      await _plugin.openScreenRecordingSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening System Preferences - enable Screen Recording and return to app'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _plugin.openAccessibilitySettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening System Preferences - enable Accessibility and return to app'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
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
              Icon(
                Icons.security,
                size: 80,
                color: colorScheme.primary,
              ),
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
              _buildPermissionTile(
                context: context,
                title: 'Screen Recording',
                description: 'Required to access window information',
                icon: Icons.desktop_mac,
                hasPermission: _hasScreenRecordingPermission,
                onRequest: _requestScreenRecordingPermission,
                onOpenSettings: _openScreenRecordingSettings,
              ),
              
              const SizedBox(height: 16),
              
              // Accessibility Permission
              _buildPermissionTile(
                context: context,
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

  Widget _buildPermissionTile({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool? hasPermission,
    required VoidCallback onRequest,
    required VoidCallback onOpenSettings,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isGranted = hasPermission == true;
    final isLoading = hasPermission == null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isGranted 
              ? colorScheme.primary
              : colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isGranted
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted 
                  ? colorScheme.primary
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isGranted 
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLoading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    else
                      Icon(
                        isGranted ? Icons.check_circle : Icons.cancel,
                        color: isGranted 
                            ? colorScheme.primary
                            : colorScheme.error,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isGranted && !isLoading) ...[
            OutlinedButton(
              onPressed: onRequest,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(60, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Request'),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings),
            iconSize: 20,
            tooltip: 'Open System Preferences',
          ),
        ],
      ),
    );
  }
}