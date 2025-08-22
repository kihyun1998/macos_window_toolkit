import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class CapturableWindowsTab extends StatefulWidget {
  const CapturableWindowsTab({super.key});

  @override
  State<CapturableWindowsTab> createState() => _CapturableWindowsTabState();
}

class _CapturableWindowsTabState extends State<CapturableWindowsTab> {
  final _macosWindowToolkit = MacosWindowToolkit();
  List<CapturableWindowInfo> _capturableWindows = [];
  bool _isLoading = false;
  MacosVersionInfo? _versionInfo;
  String? _error;
  bool _excludeTitlebar = false;

  @override
  void initState() {
    super.initState();
    _checkVersionAndLoadWindows();
  }

  Future<void> _checkVersionAndLoadWindows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final versionInfo = await _macosWindowToolkit.getMacOSVersionInfo();
      setState(() {
        _versionInfo = versionInfo;
      });

      if (versionInfo.isScreenCaptureKitAvailable) {
        await _loadCapturableWindows();
      } else {
        setState(() {
          _error = 'ScreenCaptureKit not available (requires macOS 12.3+)';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to check version: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCapturableWindows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final windows = await _macosWindowToolkit.getCapturableWindows();
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
        title: const Text('Capturable Windows'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_versionInfo?.isScreenCaptureKitAvailable == true)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadCapturableWindows,
              tooltip: 'Refresh Capturable Windows',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            margin: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _versionInfo?.isScreenCaptureKitAvailable == true
                          ? Icons.camera_alt
                          : Icons.warning_amber,
                      color: _versionInfo?.isScreenCaptureKitAvailable == true
                          ? colorScheme.primary
                          : Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _versionInfo?.isScreenCaptureKitAvailable == true
                                ? 'ScreenCaptureKit Available'
                                : 'ScreenCaptureKit Not Available',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _versionInfo?.isScreenCaptureKitAvailable == true
                                ? 'Ready to capture windows'
                                : 'Requires macOS 12.3 or later',
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

          // Titlebar Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Switch(
                      value: _excludeTitlebar,
                      onChanged: (value) {
                        setState(() {
                          _excludeTitlebar = value;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exclude Titlebar',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capture only the content area without the window titlebar',
                            style: theme.textTheme.bodySmall?.copyWith(
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
          
          const SizedBox(height: 8),

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
            if (_versionInfo?.isScreenCaptureKitAvailable == true)
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
        return CapturableWindowCard(
          window: window,
          onCapture: () => _captureWindow(window),
        );
      },
    );
  }

  Future<void> _captureWindow(CapturableWindowInfo window) async {
    final windowId = window.windowId;

    try {
      final imageBytes = await _macosWindowToolkit.captureWindow(windowId, excludeTitlebar: _excludeTitlebar);

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
          CaptureResultDialog(window: window, imageData: imageData),
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

class CapturableWindowCard extends StatelessWidget {
  final CapturableWindowInfo window;
  final VoidCallback onCapture;

  const CapturableWindowCard({
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
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.window, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(window.title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: onCapture,
          tooltip: 'Capture Window',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class CaptureResultDialog extends StatelessWidget {
  final CapturableWindowInfo window;
  final Uint8List imageData;

  const CaptureResultDialog({
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
                  child: Text(
                    'Captured: ${window.title}',
                    style: Theme.of(context).textTheme.titleLarge,
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
