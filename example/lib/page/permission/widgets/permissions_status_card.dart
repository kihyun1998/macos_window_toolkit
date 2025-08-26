import 'package:flutter/material.dart';

import 'permission_row.dart';

class PermissionsStatusCard extends StatelessWidget {
  final bool? hasScreenRecordingPermission;
  final bool? hasAccessibilityPermission;
  final VoidCallback onOpenScreenRecordingSettings;
  final VoidCallback onOpenAccessibilitySettings;
  final VoidCallback onRequestScreenRecordingPermission;
  final VoidCallback onRequestAccessibilityPermission;

  const PermissionsStatusCard({
    super.key,
    required this.hasScreenRecordingPermission,
    required this.hasAccessibilityPermission,
    required this.onOpenScreenRecordingSettings,
    required this.onOpenAccessibilitySettings,
    required this.onRequestScreenRecordingPermission,
    required this.onRequestAccessibilityPermission,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Permissions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PermissionRow(
              title: 'Screen Recording',
              hasPermission: hasScreenRecordingPermission,
              onRequest: onRequestScreenRecordingPermission,
              onOpenSettings: onOpenScreenRecordingSettings,
              description: 'Required for window names',
            ),
            const SizedBox(height: 6),
            PermissionRow(
              title: 'Accessibility',
              hasPermission: hasAccessibilityPermission,
              onRequest: onRequestAccessibilityPermission,
              onOpenSettings: onOpenAccessibilitySettings,
              description: 'Required to close windows',
            ),
          ],
        ),
      ),
    );
  }
}
