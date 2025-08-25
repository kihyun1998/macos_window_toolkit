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
  bool _excludeTitlebar = false;
  bool? _isWindowAlive;
  bool _isCheckingAlive = false;
  bool _isClosingWindow = false;
  bool _isTerminatingApp = false;
  bool _isTerminatingTree = false;

  @override
  void initState() {
    super.initState();
    _checkVersionInfo();
    _checkWindowAlive();
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

  Future<void> _checkWindowAlive() async {
    setState(() {
      _isCheckingAlive = true;
    });

    try {
      final isAlive = await _macosWindowToolkit.isWindowAlive(widget.window.windowId);
      print('Window ${widget.window.windowId} alive check result: $isAlive');
      setState(() {
        _isWindowAlive = isAlive;
        _isCheckingAlive = false;
      });
    } catch (e) {
      print('Error checking window alive: $e');
      setState(() {
        _isWindowAlive = null;
        _isCheckingAlive = false;
      });
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
        excludeTitlebar: _excludeTitlebar,
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

  Future<void> _closeWindow() async {
    setState(() {
      _isClosingWindow = true;
    });

    try {
      final success = await _macosWindowToolkit.closeWindow(widget.window.windowId);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully closed window: ${widget.window.name}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to close window: ${widget.window.name}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unknown error occurred';
        if (e is PlatformException) {
          switch (e.code) {
            case 'WINDOW_NOT_FOUND':
              errorMessage = 'Window not found';
              break;
            case 'INSUFFICIENT_WINDOW_INFO':
              errorMessage = 'Not enough window information';
              break;
            case 'APPLESCRIPT_EXECUTION_FAILED':
              errorMessage = 'AppleScript execution failed';
              break;
            default:
              errorMessage = 'Error: ${e.message}';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close window: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClosingWindow = false;
        });
      }
    }
  }

  Future<void> _terminateApplication({bool force = false}) async {
    setState(() {
      _isTerminatingApp = true;
    });

    try {
      final success = await _macosWindowToolkit.terminateApplicationByPID(
        widget.window.processId,
        force: force,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully ${force ? 'force ' : ''}terminated application: ${widget.window.ownerName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to ${force ? 'force ' : ''}terminate application: ${widget.window.ownerName}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unknown error occurred';
        if (e is PlatformException) {
          switch (e.code) {
            case 'PROCESS_NOT_FOUND':
              errorMessage = 'Process not found';
              break;
            case 'TERMINATION_FAILED':
              errorMessage = 'Termination failed';
              break;
            case 'TERMINATE_APP_ERROR':
              errorMessage = 'Application termination error';
              break;
            default:
              errorMessage = 'Error: ${e.message}';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to terminate application: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTerminatingApp = false;
        });
      }
    }
  }

  Future<void> _terminateApplicationTree({bool force = false}) async {
    setState(() {
      _isTerminatingTree = true;
    });

    try {
      final success = await _macosWindowToolkit.terminateApplicationTree(
        widget.window.processId,
        force: force,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully ${force ? 'force ' : ''}terminated application tree: ${widget.window.ownerName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to ${force ? 'force ' : ''}terminate application tree: ${widget.window.ownerName}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Unknown error occurred';
        if (e is PlatformException) {
          switch (e.code) {
            case 'PROCESS_NOT_FOUND':
              errorMessage = 'Process not found';
              break;
            case 'FAILED_TO_GET_PROCESS_LIST':
              errorMessage = 'Failed to get process list';
              break;
            case 'TERMINATE_TREE_ERROR':
              errorMessage = 'Process tree termination error';
              break;
            default:
              errorMessage = 'Error: ${e.message}';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to terminate application tree: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTerminatingTree = false;
        });
      }
    }
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

            // Window Status Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isWindowAlive == true 
                    ? Colors.green.withOpacity(0.1)
                    : _isWindowAlive == false 
                        ? Colors.red.withOpacity(0.1)
                        : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: _isWindowAlive != null
                    ? Border.all(
                        color: _isWindowAlive! ? Colors.green : Colors.red,
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isWindowAlive == true 
                            ? Icons.check_circle 
                            : _isWindowAlive == false 
                                ? Icons.cancel 
                                : Icons.help_outline,
                        color: _isWindowAlive == true 
                            ? Colors.green 
                            : _isWindowAlive == false 
                                ? Colors.red 
                                : colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Window Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isCheckingAlive ? null : _checkWindowAlive,
                            icon: _isCheckingAlive
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.refresh, size: 16),
                            label: Text('Check'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(80, 32),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: (_isClosingWindow || _isWindowAlive == false) 
                                ? null 
                                : _closeWindow,
                            icon: _isClosingWindow
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.close, size: 16),
                            label: Text('Close'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(80, 32),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _isCheckingAlive
                            ? 'Checking...'
                            : _isWindowAlive == true
                                ? 'Window is alive'
                                : _isWindowAlive == false
                                    ? 'Window not found'
                                    : 'Unknown',
                        style: TextStyle(
                          color: _isWindowAlive == true 
                              ? Colors.green 
                              : _isWindowAlive == false 
                                  ? Colors.red 
                                  : colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Process Termination Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Process Termination',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'These actions terminate the entire application process, not just the window. '
                    'No accessibility permissions required.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: (_isTerminatingApp || _isTerminatingTree) 
                            ? null 
                            : () => _terminateApplication(force: false),
                        icon: _isTerminatingApp && !_isTerminatingTree
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.stop, size: 16),
                        label: Text('Terminate App'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(120, 36),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          foregroundColor: Colors.orange,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: (_isTerminatingApp || _isTerminatingTree) 
                            ? null 
                            : () => _terminateApplication(force: true),
                        icon: _isTerminatingApp && !_isTerminatingTree
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.power_off, size: 16),
                        label: Text('Force Terminate'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(130, 36),
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: (_isTerminatingApp || _isTerminatingTree) 
                            ? null 
                            : () => _terminateApplicationTree(force: false),
                        icon: _isTerminatingTree
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.account_tree, size: 16),
                        label: Text('Terminate Tree'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(130, 36),
                          backgroundColor: Colors.deepOrange.withOpacity(0.1),
                          foregroundColor: Colors.deepOrange,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: (_isTerminatingApp || _isTerminatingTree) 
                            ? null 
                            : () => _terminateApplicationTree(force: true),
                        icon: _isTerminatingTree
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.dangerous, size: 16),
                        label: Text('Force Tree'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(110, 36),
                          backgroundColor: Colors.red.withOpacity(0.2),
                          foregroundColor: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Process ID: ${widget.window.processId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onErrorContainer.withOpacity(0.7),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: _excludeTitlebar,
                                onChanged: _isCapturing ? null : (value) {
                                  setState(() {
                                    _excludeTitlebar = value;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Exclude Titlebar',
                                style: TextStyle(
                                  color: _isCapturing ? Colors.grey : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                        ],
                      ),
                      if (_capturedImage != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
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
                        ),
                      ],

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
