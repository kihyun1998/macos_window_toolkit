import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class LegacyWindowsTab extends StatefulWidget {
  const LegacyWindowsTab({super.key});

  @override
  State<LegacyWindowsTab> createState() => _LegacyWindowsTabState();
}

class _LegacyWindowsTabState extends State<LegacyWindowsTab> {
  final _macosWindowToolkit = MacosWindowToolkit();
  List<CapturableWindowInfo> _capturableWindows = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCapturableWindows();
  }

  Future<void> _loadCapturableWindows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final windows = await _macosWindowToolkit.getCapturableWindowsLegacy();
      setState(() {
        _capturableWindows = windows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load capturable windows: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Capture (CGWindowListCreateImage)'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCapturableWindows,
            tooltip: 'Refresh Capturable Windows',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.camera,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legacy Window Capture',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uses CGWindowListCreateImage (compatible with all macOS versions)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Windows List
          Expanded(child: _buildWindowsList()),
        ],
      ),
    );
  }

  Widget _buildWindowsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading capturable windows...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCapturableWindows,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_capturableWindows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.window_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No capturable windows found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _capturableWindows.length,
      itemBuilder: (context, index) {
        final window = _capturableWindows[index];
        return LegacyCapturableWindowCard(
          window: window,
          onCapture: () => _captureWindow(window),
        );
      },
    );
  }

  Future<void> _captureWindow(CapturableWindowInfo window) async {
    final windowId = window.windowId;

    try {
      final imageBytes = await _macosWindowToolkit.captureWindowLegacy(windowId);

      if (mounted) {
        _showCaptureResult(window, imageBytes);
      }
    } catch (e) {
      if (mounted) {
        _showCaptureError(window, e);
      }
    }
  }

  void _showCaptureResult(CapturableWindowInfo window, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) =>
          LegacyCaptureResultDialog(window: window, imageData: imageData),
    );
  }

  void _showCaptureError(CapturableWindowInfo window, dynamic error) {
    String errorMessage = 'Capture failed';
    if (error is PlatformException) {
      errorMessage = error.message ?? 'Unknown error';
    } else {
      errorMessage = error.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to capture "${window.title}": $errorMessage'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class LegacyCapturableWindowCard extends StatelessWidget {
  final CapturableWindowInfo window;
  final VoidCallback onCapture;

  const LegacyCapturableWindowCard({
    super.key,
    required this.window,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(
            Icons.camera,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          window.title.isEmpty ? '(No Title)' : window.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              window.ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Size: ${window.frame.width.toInt()} × ${window.frame.height.toInt()}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (window.bundleIdentifier.isEmpty)
              Text(
                'Legacy API (no bundle info)',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.camera),
          onPressed: onCapture,
          tooltip: 'Capture Window (Legacy)',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class LegacyCaptureResultDialog extends StatelessWidget {
  final CapturableWindowInfo window;
  final Uint8List imageData;

  const LegacyCaptureResultDialog({
    super.key,
    required this.window,
    required this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legacy Captured: ${window.title}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Using CGWindowListCreateImage',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(imageData, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Image size: ${imageData.length} bytes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}