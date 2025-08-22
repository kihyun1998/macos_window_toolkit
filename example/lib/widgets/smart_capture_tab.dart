import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class SmartCaptureTab extends StatefulWidget {
  const SmartCaptureTab({super.key});

  @override
  State<SmartCaptureTab> createState() => _SmartCaptureTabState();
}

class _SmartCaptureTabState extends State<SmartCaptureTab> {
  final _macosWindowToolkit = MacosWindowToolkit();
  List<CapturableWindowInfo> _capturableWindows = [];
  Map<String, dynamic>? _captureMethodInfo;
  bool _isLoading = false;
  String? _error;
  bool _excludeTitlebar = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _macosWindowToolkit.getCapturableWindowsAuto(),
        _macosWindowToolkit.getCaptureMethodInfo(),
      ]);

      setState(() {
        _capturableWindows = futures[0] as List<CapturableWindowInfo>;
        _captureMethodInfo = futures[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load smart capture data: $e';
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
        title: const Text('Smart Capture (Auto-Selection)'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh Smart Capture Data',
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Capture (Auto-Selection)',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Automatically selects the best capture method for your macOS version',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_captureMethodInfo != null) ...[
                      const SizedBox(height: 16),
                      _buildMethodInfoSection(),
                    ],
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

  Widget _buildMethodInfoSection() {
    final info = _captureMethodInfo!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Configuration',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('macOS Version', info['macOSVersion'] ?? 'Unknown'),
          _buildInfoRow('Capture Method', info['captureMethod'] ?? 'Unknown'),
          _buildInfoRow('Window List Method', info['windowListMethod'] ?? 'Unknown'),
          _buildInfoRow(
            'ScreenCaptureKit Available',
            info['isScreenCaptureKitAvailable'] == true ? 'Yes' : 'No',
            info['isScreenCaptureKitAvailable'] == true ? Colors.green : Colors.orange,
          ),
          _buildInfoRow(
            'Modern Capture',
            info['supportsModernCapture'] == true ? 'Supported' : 'Not Supported',
            info['supportsModernCapture'] == true ? Colors.green : Colors.orange,
          ),
          _buildInfoRow(
            'Modern Window List',
            info['supportsModernWindowList'] == true ? 'Supported' : 'Not Supported',
            info['supportsModernWindowList'] == true ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: valueColor != null ? FontWeight.w500 : null,
              ),
            ),
          ),
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
            Text('Loading smart capture data...'),
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
              onPressed: _loadData,
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
        return SmartCapturableWindowCard(
          window: window,
          onCapture: () => _captureWindow(window),
        );
      },
    );
  }

  Future<void> _captureWindow(CapturableWindowInfo window) async {
    final windowId = window.windowId;

    try {
      final imageBytes = await _macosWindowToolkit.captureWindowAuto(windowId, excludeTitlebar: _excludeTitlebar);

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
          SmartCaptureResultDialog(window: window, imageData: imageData),
    );
  }

  void _showCaptureError(CapturableWindowInfo window, dynamic error) {
    String errorMessage = 'Smart capture failed';
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

class SmartCapturableWindowCard extends StatelessWidget {
  final CapturableWindowInfo window;
  final VoidCallback onCapture;

  const SmartCapturableWindowCard({
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
          child: Icon(
            Icons.auto_awesome,
            color: colorScheme.onPrimaryContainer,
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
            if (window.bundleIdentifier.isNotEmpty)
              Text(
                window.bundleIdentifier,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.auto_awesome),
          onPressed: onCapture,
          tooltip: 'Smart Capture (Auto)',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class SmartCaptureResultDialog extends StatelessWidget {
  final CapturableWindowInfo window;
  final Uint8List imageData;

  const SmartCaptureResultDialog({
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
                        'Smart Captured: ${window.title}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automatically selected best capture method',
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