import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
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
  final _titlebarHeightController = TextEditingController();
  final _targetWidthController = TextEditingController();
  final _targetHeightController = TextEditingController();

  bool _isCapturing = false;
  String? _captureError;
  MacosVersionInfo? _versionInfo;
  bool _excludeTitlebar = false;
  bool _enableResize = false;
  bool _preserveAspectRatio = false;
  bool? _isWindowAlive;
  bool? _isWindowAliveWithName;
  bool _isCheckingAlive = false;
  bool _isCheckingAliveWithName = false;
  bool _isClosingWindow = false;
  bool _isFocusingWindow = false;
  bool _isTerminatingApp = false;
  bool _isTerminatingTree = false;

  // Scroll info state
  ScrollInfo? _scrollInfo;
  bool _isLoadingScrollInfo = false;
  String? _scrollError;

  @override
  void initState() {
    super.initState();
    _checkVersionInfo();
    _checkWindowAlive();
    _loadScrollInfo();
  }

  @override
  void dispose() {
    _titlebarHeightController.dispose();
    _targetWidthController.dispose();
    _targetHeightController.dispose();
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
      setState(() {
        _isWindowAlive = isAlive;
        _isCheckingAlive = false;
      });
    } catch (e) {
      setState(() {
        _isWindowAlive = null;
        _isCheckingAlive = false;
      });
    }
  }

  Future<void> _checkWindowAliveWithName() async {
    setState(() {
      _isCheckingAliveWithName = true;
    });

    try {
      final isAlive = await _macosWindowToolkit.isWindowAlive(
        widget.window.windowId,
        expectedName: widget.window.name,
      );
      setState(() {
        _isWindowAliveWithName = isAlive;
        _isCheckingAliveWithName = false;
      });
    } catch (e) {
      setState(() {
        _isWindowAliveWithName = null;
        _isCheckingAliveWithName = false;
      });
    }
  }

  Future<void> _loadScrollInfo() async {
    setState(() {
      _isLoadingScrollInfo = true;
      _scrollError = null;
    });

    try {
      final result = await _macosWindowToolkit.getScrollInfo(
        widget.window.windowId,
      );

      if (!mounted) return;

      switch (result) {
        case ScrollSuccess(scrollInfo: final info):
          setState(() {
            _scrollInfo = info;
            _isLoadingScrollInfo = false;
          });
        case ScrollFailure(:final reason, :final message):
          setState(() {
            _scrollInfo = null;
            _scrollError = message ?? reason.name;
            _isLoadingScrollInfo = false;
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scrollInfo = null;
        _scrollError = e.toString();
        _isLoadingScrollInfo = false;
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

      int? targetWidth;
      int? targetHeight;
      if (_enableResize) {
        targetWidth = int.tryParse(_targetWidthController.text);
        targetHeight = int.tryParse(_targetHeightController.text);
      }

      final result = await _macosWindowToolkit.captureWindow(
        widget.window.windowId,
        excludeTitlebar: _excludeTitlebar,
        customTitlebarHeight: customHeight,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        preserveAspectRatio: _preserveAspectRatio,
      );

      setState(() {
        _isCapturing = false;
      });

      // Show captured image or handle failure
      if (mounted) {
        switch (result) {
          case CaptureSuccess(imageData: final imageBytes):
            _showCaptureResultDialog(imageBytes);
            break;
          case CaptureFailure(:final reason, :final message, :final details):
            _handleCaptureFailure(reason, message, details);
            break;
        }
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;

        // Build detailed error message
        final errorParts = <String>[];

        if (e is PlatformException) {
          final errorCode = e.errorCode;

          // Add primary error message
          errorParts.add('🔴 System Error');
          errorParts.add(
            '\n💬 ${errorCode?.userMessage ?? e.message ?? 'Unknown error'}',
          );

          // Add error code
          if (e.code.isNotEmpty) {
            errorParts.add('\n🔍 Error Code: ${e.code}');
          }

          // Add details if available
          if (e.details != null) {
            errorParts.add('\n📋 Details: ${e.details}');
          }
        } else {
          errorParts.add('⚠️ Unexpected Error');
          errorParts.add('\n💬 $e');
        }

        _captureError = errorParts.join('\n');
      });
    }
  }

  void _handleCaptureFailure(
    CaptureFailureReason reason,
    String? message,
    String? details,
  ) {
    setState(() {
      // Build detailed error message with all available information
      final errorParts = <String>[];

      // Add reason-based primary message
      switch (reason) {
        case CaptureFailureReason.windowNotFound:
          errorParts.add('❌ Window not found or not capturable');
          break;
        case CaptureFailureReason.windowMinimized:
          errorParts.add('📦 Window is minimized and cannot be captured');
          break;
        case CaptureFailureReason.permissionDenied:
          errorParts.add('🔒 Screen recording permission denied');
          break;
        case CaptureFailureReason.unsupportedVersion:
          errorParts.add('⚠️ macOS version not supported');
          break;
        case CaptureFailureReason.captureInProgress:
          errorParts.add('⏳ Another capture is already in progress');
          break;
        case CaptureFailureReason.windowNotCapturable:
          errorParts.add('🚫 This window cannot be captured');
          break;
        case CaptureFailureReason.unknown:
          errorParts.add('❓ Unknown capture error');
          break;
      }

      // Add message from native side if available
      if (message != null && message.isNotEmpty) {
        errorParts.add('\n💬 $message');
      }

      // Add details from native side if available
      if (details != null && details.isNotEmpty) {
        errorParts.add('\n📋 Details: $details');
      }

      // Add error code for debugging
      errorParts.add('\n🔍 Error Code: ${reason.name}');

      _captureError = errorParts.join('\n');
    });
  }

  bool get _canCapture {
    return _versionInfo?.isScreenCaptureKitAvailable ?? false;
  }

  void _showCaptureResultDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => CaptureResultDialog(
        imageBytes: imageBytes,
        targetWidth: _enableResize
            ? int.tryParse(_targetWidthController.text)
            : null,
        targetHeight: _enableResize
            ? int.tryParse(_targetHeightController.text)
            : null,
      ),
    );
  }

  Future<void> _closeWindow() async {
    setState(() {
      _isClosingWindow = true;
    });

    try {
      final result = await _macosWindowToolkit.closeWindow(
        widget.window.windowId,
      );

      if (!mounted) return;

      switch (result) {
        case OperationSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully closed window: ${widget.window.name}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();

        case OperationFailure(:final reason, :final message):
          // Handle accessibility permission case
          if (reason ==
              WindowOperationFailureReason.accessibilityPermissionDenied) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/permission');
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to close window: ${message ?? reason.name}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage;
      if (e is PlatformException) {
        final errorCode = e.errorCode;
        errorMessage = errorCode?.userMessage ?? e.message ?? 'Unknown error';
      } else {
        errorMessage = 'Unknown error occurred';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('System error: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClosingWindow = false;
        });
      }
    }
  }

  Future<void> _focusWindow() async {
    setState(() {
      _isFocusingWindow = true;
    });

    try {
      final result = await _macosWindowToolkit.focusWindow(
        widget.window.windowId,
      );

      if (!mounted) return;

      switch (result) {
        case OperationSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully focused window: ${widget.window.name}',
              ),
              backgroundColor: Colors.green,
            ),
          );

        case OperationFailure(:final reason, :final message):
          // Handle accessibility permission case
          if (reason ==
              WindowOperationFailureReason.accessibilityPermissionDenied) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/permission');
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to focus window: ${message ?? reason.name}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage;
      if (e is PlatformException) {
        final errorCode = e.errorCode;
        errorMessage = errorCode?.userMessage ?? e.message ?? 'Unknown error';
      } else {
        errorMessage = 'Unknown error occurred';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('System error: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFocusingWindow = false;
        });
      }
    }
  }

  Future<void> _terminateApplication({bool force = false}) async {
    setState(() {
      _isTerminatingApp = true;
    });

    try {
      final result = await _macosWindowToolkit.terminateApplicationByPID(
        widget.window.processId,
        force: force,
      );

      if (!mounted) return;

      switch (result) {
        case OperationSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully ${force ? 'force ' : ''}terminated application: ${widget.window.ownerName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();

        case OperationFailure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to ${force ? 'force ' : ''}terminate: ${message ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e is PlatformException
          ? e.errorCode?.userMessage ?? e.message ?? 'Unknown error'
          : 'Unknown error occurred';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('System error: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
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
      final result = await _macosWindowToolkit.terminateApplicationTree(
        widget.window.processId,
        force: force,
      );

      if (!mounted) return;

      switch (result) {
        case OperationSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully ${force ? 'force ' : ''}terminated application tree: ${widget.window.ownerName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();

        case OperationFailure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to ${force ? 'force ' : ''}terminate tree: ${message ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e is PlatformException
          ? e.errorCode?.userMessage ?? e.message ?? 'Unknown error'
          : 'Unknown error occurred';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('System error: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
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
                    ? Colors.green.withValues(alpha: 0.1)
                    : _isWindowAlive == false
                    ? Colors.red.withValues(alpha: 0.1)
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
                                (_isFocusingWindow || _isWindowAlive == false)
                                ? null
                                : _focusWindow,
                            icon: _isFocusingWindow
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.flip_to_front, size: 16),
                            label: Text('Focus'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(80, 32),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              backgroundColor: Colors.blue.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.blue,
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
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.1,
                              ),
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
                        'Status (ID): ',
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
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Verify with Name (prevents ID reuse issues)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.label_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.window.name.isEmpty
                                      ? '(No name)'
                                      : widget.window.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: widget.window.name.isEmpty
                                        ? colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5)
                                        : colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            (_isCheckingAliveWithName ||
                                widget.window.name.isEmpty)
                            ? null
                            : _checkWindowAliveWithName,
                        icon: _isCheckingAliveWithName
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.verified, size: 16),
                        label: Text('Check'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(80, 32),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Status (ID + Name): ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _isCheckingAliveWithName
                              ? 'Checking...'
                              : _isWindowAliveWithName == true
                              ? 'Match - Window exists and name matches'
                              : _isWindowAliveWithName == false
                              ? 'No match - Window not found or name changed'
                              : 'Not checked yet',
                          style: TextStyle(
                            color: _isWindowAliveWithName == true
                                ? Colors.green
                                : _isWindowAliveWithName == false
                                ? Colors.orange
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scroll Information Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.swap_vert,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scroll Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _isLoadingScrollInfo ? null : _loadScrollInfo,
                        icon: _isLoadingScrollInfo
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.refresh, size: 16),
                        label: Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(90, 32),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingScrollInfo)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_scrollError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _scrollError!,
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_scrollInfo != null)
                    Column(
                      children: [
                        // Vertical Scroll
                        Row(
                          children: [
                            Icon(
                              Icons.swap_vert,
                              size: 16,
                              color: _scrollInfo!.hasVerticalScroll
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Vertical: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: _scrollInfo!.hasVerticalScroll
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: _scrollInfo!.verticalPosition ?? 0,
                                            backgroundColor: colorScheme.surfaceContainerHighest,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${((_scrollInfo!.verticalPosition ?? 0) * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Not available',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Horizontal Scroll
                        Row(
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: _scrollInfo!.hasHorizontalScroll
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Horizontal: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: _scrollInfo!.hasHorizontalScroll
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: _scrollInfo!.horizontalPosition ?? 0,
                                            backgroundColor: colorScheme.surfaceContainerHighest,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${((_scrollInfo!.horizontalPosition ?? 0) * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Not available',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        if (!_scrollInfo!.hasAnyScroll) ...[
                          const SizedBox(height: 8),
                          Text(
                            'This window has no scrollable content or does not expose scroll information.',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Text(
                      'Click Refresh to load scroll information',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Process Termination Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.5),
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
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
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
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
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
                          backgroundColor: Colors.deepOrange.withValues(
                            alpha: 0.1,
                          ),
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
                          backgroundColor: Colors.red.withValues(alpha: 0.2),
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
                      color: colorScheme.onErrorContainer.withValues(
                        alpha: 0.7,
                      ),
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
                        // Titlebar Options
                        Row(
                          children: [
                            Switch(
                              value: _excludeTitlebar,
                              onChanged: _isCapturing
                                  ? null
                                  : (value) {
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
                              helperText:
                                  'Common values: Safari 44pt, Chrome 0pt',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            enabled: !_isCapturing,
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Resize Options
                        Row(
                          children: [
                            Switch(
                              value: _enableResize,
                              onChanged: _isCapturing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _enableResize = value;
                                      });
                                    },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Resize Image',
                              style: TextStyle(
                                color: _isCapturing ? Colors.grey : null,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        if (_enableResize) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _targetWidthController,
                                  decoration: InputDecoration(
                                    labelText: 'Target Width',
                                    hintText: '800',
                                    helperText: 'pixels',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  enabled: !_isCapturing,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _targetHeightController,
                                  decoration: InputDecoration(
                                    labelText: 'Target Height',
                                    hintText: '600',
                                    helperText: 'pixels',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  enabled: !_isCapturing,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: _preserveAspectRatio,
                                onChanged: _isCapturing
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _preserveAspectRatio = value ?? false;
                                        });
                                      },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Preserve aspect ratio (fills extra space with black)',
                                  style: TextStyle(
                                    color: _isCapturing ? Colors.grey : null,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _preserveAspectRatio
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _preserveAspectRatio
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: _preserveAspectRatio
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _preserveAspectRatio
                                        ? 'Aspect ratio will be maintained, extra space filled with black'
                                        : 'Image will be stretched to exact dimensions (may distort)',
                                    style: TextStyle(
                                      color: _preserveAspectRatio
                                          ? Colors.green
                                          : Colors.orange,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                  'ScreenCaptureKit not available (requires macOS 12.3+)',
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
                          onPressed: (_isCapturing || !_canCapture)
                              ? null
                              : _captureWindow,
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
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Capture Failed',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: SelectableText(
                                    _captureError!,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                // Show permission button if error is permission-related
                                if (_captureError!.contains('permission') ||
                                    _captureError!.contains('Permission')) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/permission',
                                        );
                                      },
                                      icon: Icon(Icons.settings, size: 16),
                                      label: Text('Open Permission Settings'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
            _DetailItem(label: 'Window ID', value: '${widget.window.windowId}'),
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
                value: widget.getSharingStateText(widget.window.sharingState!),
              ),
            if (widget.window.memoryUsage != null)
              _DetailItem(
                label: 'Memory Usage',
                value: widget.formatBytes(widget.window.memoryUsage!),
              ),
            if (widget.window.role != null)
              _DetailItem(label: 'Role', value: widget.window.role!),
            if (widget.window.subrole != null)
              _DetailItem(label: 'Subrole', value: widget.window.subrole!),
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

class CaptureResultDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final int? targetWidth;
  final int? targetHeight;

  const CaptureResultDialog({
    super.key,
    required this.imageBytes,
    this.targetWidth,
    this.targetHeight,
  });

  @override
  State<CaptureResultDialog> createState() => _CaptureResultDialogState();
}

class _CaptureResultDialogState extends State<CaptureResultDialog> {
  int? imageWidth;
  int? imageHeight;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  Future<void> _decodeImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    setState(() {
      imageWidth = frame.image.width;
      imageHeight = frame.image.height;
    });
    // ignore: avoid_print
    print('✅ Decoded image size: ${imageWidth}x$imageHeight');
  }

  Future<void> _saveImage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Generate default filename with timestamp
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final defaultFileName = 'screenshot_$timestamp.png';

      // Show save dialog
      final FileSaveLocation? saveLocation = await getSaveLocation(
        suggestedName: defaultFileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'PNG Images', extensions: ['png']),
        ],
      );

      if (saveLocation == null) {
        // User cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Save the file
      final file = File(saveLocation.path);
      await file.writeAsBytes(widget.imageBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to: ${saveLocation.path}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Captured Window'),
              if (imageWidth != null && imageHeight != null)
                Text(
                  '${imageWidth}x$imageHeight px${widget.targetWidth != null ? " (resized from ${widget.targetWidth}x${widget.targetHeight})" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.surface.withValues(alpha: 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageWidth != null && imageHeight != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_size_select_large,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Image Size: ${imageWidth}x$imageHeight pixels',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.targetWidth != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveImage,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final text =
                          'Image Size: ${imageWidth}x$imageHeight pixels (${widget.imageBytes.length} bytes)';
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: $text'),
                          duration: const Duration(seconds: 2),
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
            ],
          ),
        ),
      ),
    );
  }
}
