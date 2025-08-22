import 'package:flutter/material.dart';

class PermissionCard extends StatelessWidget {
  final bool? hasPermission;
  final VoidCallback onOpenSettings;

  const PermissionCard({
    super.key,
    required this.hasPermission,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    if (hasPermission == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isGranted = hasPermission!;
    final backgroundColor = isGranted
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer;
    final foregroundColor = isGranted
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? colorScheme.primary : colorScheme.error,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.warning_rounded,
            color: foregroundColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGranted ? 'Permissions Granted' : 'Permissions Required',
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGranted
                      ? 'Screen recording permission is enabled. Full window information is available.'
                      : 'Screen recording permission is needed to access window names and details.',
                  style: TextStyle(color: foregroundColor, fontSize: 14),
                ),
              ],
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Settings'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
          ],
        ],
      ),
    );
  }
}