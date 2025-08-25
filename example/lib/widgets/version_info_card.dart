import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class VersionInfoCard extends StatelessWidget {
  final MacosVersionInfo? versionInfo;

  const VersionInfoCard({super.key, required this.versionInfo});

  @override
  Widget build(BuildContext context) {
    if (versionInfo == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'macOS ${versionInfo!.versionString}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'ScreenCaptureKit: ',
                        style: theme.textTheme.bodySmall,
                      ),
                      Icon(
                        versionInfo!.isScreenCaptureKitAvailable
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: versionInfo!.isScreenCaptureKitAvailable
                            ? colorScheme.primary
                            : colorScheme.error,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        versionInfo!.isScreenCaptureKitAvailable
                            ? 'Available'
                            : 'Requires 12.3+',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: versionInfo!.isScreenCaptureKitAvailable
                              ? colorScheme.primary
                              : colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
