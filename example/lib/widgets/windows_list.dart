import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';
import 'window_card.dart';

class WindowsList extends StatelessWidget {
  final bool isLoading;
  final List<MacosWindowInfo> windows;
  final List<MacosWindowInfo> filteredWindows;
  final String searchQuery;
  final VoidCallback onRefresh;
  final Function(MacosWindowInfo) onWindowTap;
  final String Function(int) formatBytes;

  const WindowsList({
    super.key,
    required this.isLoading,
    required this.windows,
    required this.filteredWindows,
    required this.searchQuery,
    required this.onRefresh,
    required this.onWindowTap,
    required this.formatBytes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading windows...'),
          ],
        ),
      );
    }

    if (windows.isEmpty) {
      return _EmptyState(
        colorScheme: colorScheme,
        icon: Icons.window,
        title: 'No windows found',
        subtitle: 'Tap the refresh button to scan for windows',
        actionLabel: 'Scan Windows',
        onAction: onRefresh,
      );
    }

    if (filteredWindows.isEmpty && searchQuery.isNotEmpty) {
      return _EmptyState(
        colorScheme: colorScheme,
        icon: Icons.search_off,
        title: 'No windows match your search',
        subtitle: 'Try a different search term',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredWindows.length,
      itemBuilder: (context, index) {
        final window = filteredWindows[index];
        return WindowCard(
          window: window,
          onTap: () => onWindowTap(window),
          formatBytes: formatBytes,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.colorScheme,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}