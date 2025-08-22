import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class VersionInfoCard extends StatelessWidget {
  final MacosVersionInfo? versionInfo;

  const VersionInfoCard({
    super.key,
    required this.versionInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (versionInfo == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'macOS ${versionInfo!.versionString}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'ScreenCaptureKit: ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          versionInfo!.isScreenCaptureKitAvailable ? 'Available' : 'Not Available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: versionInfo!.isScreenCaptureKitAvailable 
                                ? Colors.green 
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!versionInfo!.isScreenCaptureKitAvailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Requires macOS 12.3 or later',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}