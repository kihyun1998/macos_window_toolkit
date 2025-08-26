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

enum CaptureType { screenCaptureKit, legacy, smart }

class _WindowDetailSheetState extends State<WindowDetailSheet> {
  final _macosWindowToolkit = MacosWindowToolkit();
  final _titlebarHeightController = TextEditingController();
  
  bool _isCapturing = false;
  String? _captureError;
  MacosVersionInfo? _versionInfo;
  bool _excludeTitlebar = false;
  CaptureType _captureType = CaptureType.smart;
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

  @override
  void dispose() {
    _titlebarHeightController.dispose();
    super.dispose();
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
      final isAlive = await _macosWindowToolkit.isWindowAlive(
        widget.window.windowId,
      );
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
      double? customHeight;
      if (_excludeTitlebar && _titlebarHeightController.text.isNotEmpty) {
        customHeight = double.tryParse(_titlebarHeightController.text);
      }

      Uint8List imageBytes;
      
      switch (_captureType) {
        case CaptureType.screenCaptureKit:
          imageBytes = await _macosWindowToolkit.captureWindow(
            widget.window.windowId,
            excludeTitlebar: _excludeTitlebar,
            customTitlebarHeight: customHeight,
          );
          break;
        case CaptureType.legacy:
          imageBytes = await _macosWindowToolkit.captureWindowLegacy(
            widget.window.windowId,
            excludeTitlebar: _excludeTitlebar,
            customTitlebarHeight: customHeight,
          );
          break;
        case CaptureType.smart:
          imageBytes = await _macosWindowToolkit.captureWindowAuto(
            widget.window.windowId,
            excludeTitlebar: _excludeTitlebar,
            customTitlebarHeight: customHeight,
          );
          break;
      }
      
      setState(() {
        _isCapturing = false;
      });
      
      // Show captured image in dialog
      if (mounted) {
        _showCaptureResultDialog(imageBytes);
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
        if (e is PlatformException) {
          switch (e.code) {
            case 'UNSUPPORTED_MACOS_VERSION':
              _captureError = 'macOS version not supported for this capture method';
              break;
            case 'INVALID_WINDOW_ID':
              _captureError = 'Window not found or not capturable';
              break;
            case 'WINDOW_MINIMIZED':
              _captureError = 'Window is minimized and cannot be captured. Please restore the window first.';
              break;
            case 'CAPTURE_FAILED':
              _captureError = 'Capture failed: ${e.message}';
              break;
            case 'NO_COMPATIBLE_CAPTURE_METHOD':
              _captureError = 'No compatible capture method available';
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
    switch (_captureType) {
      case CaptureType.screenCaptureKit:
        return _versionInfo?.isScreenCaptureKitAvailable ?? false;
      case CaptureType.legacy:
        return true; // Legacy method works on all versions
      case CaptureType.smart:
        return true; // Smart method handles version compatibility
    }
  }

  void _showCaptureResultDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => CaptureResultDialog(imageBytes: imageBytes),
    );
  }

  Future<void> _closeWindow() async {
    setState(() {
      _isClosingWindow = true;
    });

    try {
      final success = await _macosWindowToolkit.closeWindow(
        widget.window.windowId,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully closed window: ${widget.window.name}',
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
            content: Text(
              'Failed to terminate application tree: $errorMessage',
            ),
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
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 1,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scrollController,
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
                    : colorScheme.surfaceContainerHighest,
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
                            onPressed: _isCheckingAlive
                                ? null
                                : _checkWindowAlive,
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed:
                                (_isClosingWindow || _isWindowAlive == false)
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
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

            // Advanced Capture Section
            if (_versionInfo != null) ...[
              ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Advanced Window Capture',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Capture Type Selection
                        Text(
                          'Capture Method',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            RadioListTile<CaptureType>(
                              title: const Text('Smart (Auto)'),
                              subtitle: const Text('Automatically selects best method'),
                              value: CaptureType.smart,
                              groupValue: _captureType,
                              onChanged: _isCapturing ? null : (value) {
                                setState(() {
                                  _captureType = value!;
                                });
                              },
                              dense: true,
                            ),
                            RadioListTile<CaptureType>(
                              title: const Text('ScreenCaptureKit'),
                              subtitle: Text(
                                _versionInfo?.isScreenCaptureKitAvailable == true
                                    ? 'High quality (macOS 12.3+)'
                                    : 'Not available on this system'
                              ),
                              value: CaptureType.screenCaptureKit,
                              groupValue: _captureType,
                              onChanged: _isCapturing ? null : (value) {
                                setState(() {
                                  _captureType = value!;
                                });
                              },
                              dense: true,
                            ),
                            RadioListTile<CaptureType>(
                              title: const Text('Legacy'),
                              subtitle: const Text('Compatible with all macOS versions'),
                              value: CaptureType.legacy,
                              groupValue: _captureType,
                              onChanged: _isCapturing ? null : (value) {
                                setState(() {
                                  _captureType = value!;
                                });
                              },
                              dense: true,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Titlebar Options
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        if (_excludeTitlebar) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titlebarHeightController,
                            decoration: InputDecoration(
                              labelText: 'Custom Titlebar Height (points)',
                              hintText: 'Leave empty for default (28pt)',
                              helperText: 'Common values: Safari 44pt, Chrome 0pt',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            enabled: !_isCapturing,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Capture Button and Status
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
                                  _captureType == CaptureType.screenCaptureKit
                                      ? 'ScreenCaptureKit not available (requires macOS 12.3+)'
                                      : 'Capture method not available',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        ElevatedButton.icon(
                          onPressed: (_isCapturing || !_canCapture) ? null : _captureWindow,
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
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 44),
                          ),
                        ),

                        if (_captureError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
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
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Details List
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

class CaptureResultDialog extends StatelessWidget {
  final Uint8List imageBytes;

  const CaptureResultDialog({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Captured Window'),
          backgroundColor: colorScheme.surface.withOpacity(0.9),
          foregroundColor: colorScheme.onSurface,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.surface.withOpacity(0.9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'Image copied to clipboard'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image size copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Info'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
