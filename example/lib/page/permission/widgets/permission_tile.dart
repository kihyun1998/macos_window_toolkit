// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.hasPermission,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool? hasPermission;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isGranted = hasPermission == true;
    final isLoading = hasPermission == null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isGranted ? colorScheme.primary : colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isGranted
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
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
