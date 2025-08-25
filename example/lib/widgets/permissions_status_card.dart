import 'package:flutter/material.dart';

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
            _buildPermissionRow(
              context: context,
              title: 'Screen Recording',
              hasPermission: hasScreenRecordingPermission,
              onRequest: onRequestScreenRecordingPermission,
              onOpenSettings: onOpenScreenRecordingSettings,
              description: 'Required for window names',
            ),
            const SizedBox(height: 6),
            _buildPermissionRow(
              context: context,
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

  Widget _buildPermissionRow({
    required BuildContext context,
    required String title,
    required bool? hasPermission,
    required VoidCallback onRequest,
    required VoidCallback onOpenSettings,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hasPermission == null) {
      return Row(
        children: [
          Icon(Icons.help_outline, color: colorScheme.onSurfaceVariant, size: 16),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text('Checking...', style: theme.textTheme.bodySmall),
        ],
      );
    }

    final isGranted = hasPermission;
    final statusColor = isGranted 
        ? colorScheme.primary 
        : colorScheme.error;

    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle : Icons.cancel,
          color: statusColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        if (!isGranted) ...[
          OutlinedButton(
            onPressed: onRequest,
            style: OutlinedButton.styleFrom(
              foregroundColor: statusColor,
              side: BorderSide(color: statusColor),
              minimumSize: const Size(60, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Request', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 4),
        ],
        IconButton(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings, size: 16),
          tooltip: 'Open Settings',
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          padding: EdgeInsets.zero,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}