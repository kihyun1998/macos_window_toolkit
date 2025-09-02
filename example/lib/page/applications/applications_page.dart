import 'package:flutter/material.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key});

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  List<MacosApplicationInfo> _applications = [];
  List<MacosApplicationInfo> _filteredApplications = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();
  final _toolkit = MacosWindowToolkit();

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _searchController.addListener(_filterApplications);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _toolkit.getAllInstalledApplications();

    switch (result) {
      case ApplicationSuccess(applications: final apps):
        setState(() {
          _applications = apps;
          _filteredApplications = apps;
          _isLoading = false;
        });
      case ApplicationFailure():
        setState(() {
          _applications = [];
          _filteredApplications = [];
          _errorMessage = result.userMessage;
          _isLoading = false;
        });
    }
  }

  void _filterApplications() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApplications = _applications.where((app) {
        return app.name.toLowerCase().contains(query) ||
            app.bundleId.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _searchSpecificApp() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _toolkit.getApplicationByName(query);

    switch (result) {
      case ApplicationSuccess(applications: final apps):
        setState(() {
          _filteredApplications = apps;
          _isLoading = false;
        });

        if (apps.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No applications found matching "$query"'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Found ${apps.length} application(s) matching "$query"',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      case ApplicationFailure():
        setState(() {
          _errorMessage = result.userMessage;
          _isLoading = false;
        });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredApplications = _applications;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Applications'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadApplications,
            tooltip: 'Reload Applications',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search applications by name or bundle ID...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _searchSpecificApp,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Found ${_filteredApplications.length} applications',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading applications...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Applications Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'No applications are installed on this system'
                  : 'No applications match your search criteria',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredApplications.length,
      itemBuilder: (context, index) {
        final app = _filteredApplications[index];
        return _ApplicationCard(application: app);
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final MacosApplicationInfo application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showApplicationDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // App Icon placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: application.iconPath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          application.iconPath,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.apps,
                            size: 24,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.apps,
                        size: 24,
                        color: colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 16),

              // App Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.bundleId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (application.version.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Version ${application.version}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplicationDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ApplicationDetailDialog(application: application),
    );
  }
}

class _ApplicationDetailDialog extends StatelessWidget {
  final MacosApplicationInfo application;

  const _ApplicationDetailDialog({required this.application});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.apps, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              application.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow('Bundle ID', application.bundleId),
            if (application.version.isNotEmpty)
              _DetailRow('Version', application.version),
            _DetailRow('Path', application.path),
            if (application.iconPath.isNotEmpty)
              _DetailRow('Icon Path', application.iconPath),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value.isEmpty ? '(Not available)' : value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
