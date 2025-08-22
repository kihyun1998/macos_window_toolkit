import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

class WindowDetailSheet extends StatefulWidget {
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
  State<WindowDetailSheet> createState() => _WindowDetailSheetState();
}

class _WindowDetailSheetState extends State<WindowDetailSheet> {
  final _macosWindowToolkit = MacosWindowToolkit();
  bool _isCapturing = false;
  Uint8List? _capturedImage;
  String? _captureError;
  MacosVersionInfo? _versionInfo;

  @override
  void initState() {
    super.initState();
    _checkVersionInfo();
  }

  Future<void> _checkVersionInfo() async {
    try {
      final versionInfo = await _macosWindowToolkit.getMacOSVersionInfo();
      setState(() {
        _versionInfo = versionInfo;
      });
    } catch (e) {
      // Version info not critical for capture functionality
    }
  }

  Future<void> _captureWindow() async {
    setState(() {
      _isCapturing = true;
      _captureError = null;
    });

    try {
      final imageBytes = await _macosWindowToolkit.captureWindow(
        widget.window.windowId,
      );
      setState(() {
        _capturedImage = imageBytes;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
        if (e is PlatformException) {
          switch (e.code) {
            case 'UNSUPPORTED_MACOS_VERSION':
              _captureError = 'macOS 12.3+ required for ScreenCaptureKit';
              break;
            case 'INVALID_WINDOW_ID':
              _captureError = 'Window not found or not capturable';
              break;
            case 'CAPTURE_FAILED':
              _captureError = 'Capture failed: ${e.message}';
              break;
            default:
              _captureError = 'Capture error: ${e.message}';
          }
        } else {
          _captureError = 'Unexpected error: $e';
        }
      });
    }
  }

  bool get _canCapture {
    return _versionInfo?.isScreenCaptureKitAvailable ?? false;
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

            // Capture Section
            if (_versionInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Window Capture',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (!_canCapture) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ScreenCaptureKit not available (requires macOS 12.3+)',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isCapturing ? null : _captureWindow,
                            icon: _isCapturing
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.camera_alt),
                            label: Text(
                              _isCapturing ? 'Capturing...' : 'Capture Window',
                            ),
                          ),
                          if (_capturedImage != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Captured!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (_captureError != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _captureError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_capturedImage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _capturedImage!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Details List
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _DetailItem(
                    label: 'Window Name',
                    value: widget.window.name.isEmpty
                        ? 'Untitled'
                        : widget.window.name,
                  ),
                  _DetailItem(
                    label: 'Application',
                    value: widget.window.ownerName.isEmpty
                        ? 'Unknown'
                        : widget.window.ownerName,
                  ),
                  _DetailItem(
                    label: 'Window ID',
                    value: '${widget.window.windowId}',
                  ),
                  _DetailItem(
                    label: 'Process ID',
                    value: '${widget.window.processId}',
                  ),
                  _DetailItem(
                    label: 'Position',
                    value:
                        '(${widget.window.x.toStringAsFixed(1)}, ${widget.window.y.toStringAsFixed(1)})',
                  ),
                  _DetailItem(
                    label: 'Size',
                    value:
                        '${widget.window.width.toStringAsFixed(1)} × ${widget.window.height.toStringAsFixed(1)}',
                  ),
                  _DetailItem(label: 'Layer', value: '${widget.window.layer}'),
                  _DetailItem(
                    label: 'On Screen',
                    value: widget.window.isOnScreen ? 'Yes' : 'No',
                  ),
                  if (widget.window.alpha != null)
                    _DetailItem(
                      label: 'Alpha',
                      value: widget.window.alpha!.toStringAsFixed(2),
                    ),
                  if (widget.window.sharingState != null)
                    _DetailItem(
                      label: 'Sharing State',
                      value: widget.getSharingStateText(
                        widget.window.sharingState!,
                      ),
                    ),
                  if (widget.window.memoryUsage != null)
                    _DetailItem(
                      label: 'Memory Usage',
                      value: widget.formatBytes(widget.window.memoryUsage!),
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

  const _DetailItem({required this.label, required this.value});

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
            child: Text(value, style: TextStyle(color: colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
