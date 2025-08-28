import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  /// Show error message
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show warning message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Handle platform exception and show appropriate error
  static void handlePlatformException(
    BuildContext context,
    PlatformException exception,
    String operation,
  ) {
    // Handle special cases for better user experience
    switch (exception.code) {
      case 'WINDOW_MINIMIZED':
        showWarning(
          context,
          'Cannot capture minimized window. Please restore the window first.',
          duration: const Duration(seconds: 4),
        );
        return;
      case 'SCREEN_RECORDING_PERMISSION_DENIED':
        _showPermissionErrorDialog(context, 'Screen Recording');
        return;
      case 'ACCESSIBILITY_PERMISSION_DENIED':
        _showPermissionErrorDialog(context, 'Accessibility');
        return;
      case 'REQUIRES_MACOS_14':
        showWarning(
          context,
          'This capture method requires macOS 14.0 or later. Your system may not support this feature.',
          duration: const Duration(seconds: 5),
        );
        return;
      case 'UNSUPPORTED_MACOS_VERSION':
        showWarning(
          context,
          'Your macOS version does not support this feature. Please update to a newer version.',
          duration: const Duration(seconds: 5),
        );
        return;
    }

    showError(context, 'Error $operation: ${exception.message}');
  }

  /// Show permission error dialog with action buttons
  static void _showPermissionErrorDialog(
    BuildContext context,
    String permissionType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.security,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text('$permissionType Permission Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$permissionType permission is required for this operation.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Please grant permission in System Settings > Privacy & Security > $permissionType.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/permission');
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show permission result message
  static void showPermissionResult(
    BuildContext context, {
    required bool granted,
    required String permissionName,
    String? additionalInfo,
  }) {
    final message = granted
        ? '$permissionName permission granted!${additionalInfo != null ? ' $additionalInfo' : ''}'
        : '$permissionName permission denied.${additionalInfo != null ? ' $additionalInfo' : ''}';

    if (granted) {
      showSuccess(context, message, duration: const Duration(seconds: 4));
    } else {
      showError(context, message, duration: const Duration(seconds: 4));
    }
  }

  /// Show settings opening result
  static void showSettingsResult(
    BuildContext context, {
    required bool success,
    required String settingsType,
  }) {
    final message = success
        ? 'Opening System Preferences - please enable $settingsType.'
        : 'Failed to open System Preferences. Please open it manually.';

    if (success) {
      showWarning(context, message);
    } else {
      showError(context, message);
    }
  }
}
