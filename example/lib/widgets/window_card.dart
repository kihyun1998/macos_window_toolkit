import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class WindowCard extends StatelessWidget {
  final MacosWindowInfo window;
  final VoidCallback onTap;
  final String Function(int) formatBytes;

  const WindowCard({
    super.key,
    required this.window,
    required this.onTap,
    required this.formatBytes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // App Icon Placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.apps,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Window Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          window.name.isEmpty ? 'Untitled Window' : window.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          window.ownerName.isEmpty
                              ? 'Unknown App'
                              : window.ownerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Indicators
                  Column(
                    children: [
                      if (window.isOnScreen)
                        _StatusBadge(
                          colorScheme: colorScheme,
                          text: 'VISIBLE',
                          color: colorScheme.primary,
                          textColor: colorScheme.onPrimary,
                        )
                      else
                        _StatusBadge(
                          colorScheme: colorScheme,
                          text: 'MINIMIZED',
                          color: colorScheme.error,
                          textColor: colorScheme.onError,
                        ),
                      if (window.sharingState != null &&
                          window.sharingState! > 0) ...[
                        const SizedBox(height: 4),
                        _StatusBadge(
                          colorScheme: colorScheme,
                          text: 'SHARING',
                          color: colorScheme.tertiary,
                          textColor: colorScheme.onTertiary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Window Properties
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _PropertyChip(
                    colorScheme: colorScheme,
                    icon: Icons.aspect_ratio,
                    label: '${window.width.toInt()} × ${window.height.toInt()}',
                  ),
                  _PropertyChip(
                    colorScheme: colorScheme,
                    icon: Icons.location_on,
                    label: '(${window.x.toInt()}, ${window.y.toInt()})',
                  ),
                  _PropertyChip(
                    colorScheme: colorScheme,
                    icon: Icons.layers,
                    label: 'Layer ${window.layer}',
                  ),
                  if (window.memoryUsage != null)
                    _PropertyChip(
                      colorScheme: colorScheme,
                      icon: Icons.memory,
                      label: formatBytes(window.memoryUsage!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ColorScheme colorScheme;
  final String text;
  final Color color;
  final Color textColor;

  const _StatusBadge({
    required this.colorScheme,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _PropertyChip extends StatelessWidget {
  final ColorScheme colorScheme;
  final IconData icon;
  final String label;

  const _PropertyChip({
    required this.colorScheme,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
