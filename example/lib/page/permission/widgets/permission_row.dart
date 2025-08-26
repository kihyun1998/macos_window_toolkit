// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.title,
    this.hasPermission,
    required this.onRequest,
    required this.onOpenSettings,
    required this.description,
  });

  final String title;
  final bool? hasPermission;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hasPermission == null) {
      return Row(
        children: [
          Icon(
            Icons.help_outline,
            color: colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text('Checking...', style: theme.textTheme.bodySmall),
        ],
      );
    }

    final isGranted = hasPermission!;
    final statusColor = isGranted ? colorScheme.primary : colorScheme.error;

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
