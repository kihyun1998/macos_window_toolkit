import 'package:flutter/material.dart';

class SearchControls extends StatelessWidget {
  final TextEditingController searchController;
  final int totalWindows;
  final int filteredWindows;
  final bool autoRefresh;
  final VoidCallback onToggleAutoRefresh;

  const SearchControls({
    super.key,
    required this.searchController,
    required this.totalWindows,
    required this.filteredWindows,
    required this.autoRefresh,
    required this.onToggleAutoRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search windows by name or app...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
          ),

          const SizedBox(height: 12),

          // Stats and Controls Row
          Row(
            children: [
              // Total Windows Count
              Expanded(
                child: _StatCard(
                  colorScheme: colorScheme,
                  label: 'Total Windows',
                  value: '$totalWindows',
                  icon: Icons.window,
                ),
              ),
              const SizedBox(width: 12),
              // Filtered/Visible Count
              Expanded(
                child: _StatCard(
                  colorScheme: colorScheme,
                  label: searchController.text.isEmpty ? 'Visible' : 'Filtered',
                  value: '$filteredWindows',
                  icon: Icons.visibility,
                ),
              ),
              const SizedBox(width: 12),
              // Auto-refresh Toggle
              FilledButton.tonalIcon(
                onPressed: onToggleAutoRefresh,
                icon: Icon(autoRefresh ? Icons.pause : Icons.refresh),
                label: Text(autoRefresh ? 'Auto' : 'Manual'),
                style: FilledButton.styleFrom(
                  backgroundColor: autoRefresh
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  foregroundColor: autoRefresh
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.colorScheme,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
