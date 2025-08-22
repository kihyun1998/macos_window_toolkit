import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class WindowDetailSheet extends StatelessWidget {
  final MacosWindowInfo window;
  final String Function(int) getSharingStateText;
  final String Function(int) formatBytes;

  const WindowDetailSheet({
    super.key,
    required this.window,
    required this.getSharingStateText,
    required this.formatBytes,
  });

  static void show(
    BuildContext context,
    MacosWindowInfo window,
    String Function(int) getSharingStateText,
    String Function(int) formatBytes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => WindowDetailSheet(
        window: window,
        getSharingStateText: getSharingStateText,
        formatBytes: formatBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Window Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Details List
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _DetailItem(
                    label: 'Window Name',
                    value: window.name.isEmpty ? 'Untitled' : window.name,
                  ),
                  _DetailItem(
                    label: 'Application',
                    value: window.ownerName.isEmpty ? 'Unknown' : window.ownerName,
                  ),
                  _DetailItem(
                    label: 'Window ID',
                    value: '${window.windowId}',
                  ),
                  _DetailItem(
                    label: 'Process ID',
                    value: '${window.processId}',
                  ),
                  _DetailItem(
                    label: 'Position',
                    value: '(${window.x.toStringAsFixed(1)}, ${window.y.toStringAsFixed(1)})',
                  ),
                  _DetailItem(
                    label: 'Size',
                    value: '${window.width.toStringAsFixed(1)} × ${window.height.toStringAsFixed(1)}',
                  ),
                  _DetailItem(
                    label: 'Layer',
                    value: '${window.layer}',
                  ),
                  _DetailItem(
                    label: 'On Screen',
                    value: window.isOnScreen ? 'Yes' : 'No',
                  ),
                  if (window.alpha != null)
                    _DetailItem(
                      label: 'Alpha',
                      value: window.alpha!.toStringAsFixed(2),
                    ),
                  if (window.sharingState != null)
                    _DetailItem(
                      label: 'Sharing State',
                      value: getSharingStateText(window.sharingState!),
                    ),
                  if (window.memoryUsage != null)
                    _DetailItem(
                      label: 'Memory Usage',
                      value: formatBytes(window.memoryUsage!),
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

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}