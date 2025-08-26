import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

import '../../main.dart';
import 'widgets/permission_setup_page.dart';

class PermissionGuardPage extends StatefulWidget {
  const PermissionGuardPage({super.key});

  @override
  State<PermissionGuardPage> createState() => _PermissionGuardPageState();
}

class _PermissionGuardPageState extends State<PermissionGuardPage> {
  final _plugin = MacosWindowToolkit();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final screenRecording = await _plugin.hasScreenRecordingPermission();
      final accessibility = await _plugin.hasAccessibilityPermission();

      if (mounted) {
        if (screenRecording && accessibility) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WindowDemoPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PermissionSetupPage()),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permissions: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Checking Permissions...',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_isChecking)
              CircularProgressIndicator(color: colorScheme.primary),
            if (!_isChecking) ...[
              Text(
                'Failed to check permissions',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isChecking = true;
                  });
                  _checkPermissions();
                },
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
