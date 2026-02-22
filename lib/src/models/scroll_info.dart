/// Represents scroll information for a window or scroll area.
///
/// Contains the scroll position and availability for both vertical and horizontal scrolling.
/// Scroll positions are normalized values between 0.0 and 1.0:
/// - Vertical: 0.0 = top, 1.0 = bottom
/// - Horizontal: 0.0 = left, 1.0 = right
class ScrollInfo {
  /// Vertical scroll position (0.0 = top, 1.0 = bottom).
  /// null if vertical scrolling is not available.
  final double? verticalPosition;

  /// Horizontal scroll position (0.0 = left, 1.0 = right).
  /// null if horizontal scrolling is not available.
  final double? horizontalPosition;

  /// Whether vertical scrolling is available for this window.
  final bool hasVerticalScroll;

  /// Whether horizontal scrolling is available for this window.
  final bool hasHorizontalScroll;

  const ScrollInfo({
    this.verticalPosition,
    this.horizontalPosition,
    this.hasVerticalScroll = false,
    this.hasHorizontalScroll = false,
  });

  /// Creates a [ScrollInfo] from a map (typically from native code).
  factory ScrollInfo.fromMap(Map<String, dynamic> map) {
    return ScrollInfo(
      verticalPosition: map['verticalPosition']?.toDouble(),
      horizontalPosition: map['horizontalPosition']?.toDouble(),
      hasVerticalScroll: map['hasVerticalScroll'] ?? false,
      hasHorizontalScroll: map['hasHorizontalScroll'] ?? false,
    );
  }

  /// Converts this [ScrollInfo] to a map.
  Map<String, dynamic> toMap() {
    return {
      if (verticalPosition != null) 'verticalPosition': verticalPosition,
      if (horizontalPosition != null) 'horizontalPosition': horizontalPosition,
      'hasVerticalScroll': hasVerticalScroll,
      'hasHorizontalScroll': hasHorizontalScroll,
    };
  }

  /// Whether any scroll information is available.
  bool get hasAnyScroll => hasVerticalScroll || hasHorizontalScroll;

  @override
  String toString() {
    return 'ScrollInfo('
        'verticalPosition: $verticalPosition, '
        'horizontalPosition: $horizontalPosition, '
        'hasVerticalScroll: $hasVerticalScroll, '
        'hasHorizontalScroll: $hasHorizontalScroll)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScrollInfo &&
        other.verticalPosition == verticalPosition &&
        other.horizontalPosition == horizontalPosition &&
        other.hasVerticalScroll == hasVerticalScroll &&
        other.hasHorizontalScroll == hasHorizontalScroll;
  }

  @override
  int get hashCode {
    return Object.hash(
      verticalPosition,
      horizontalPosition,
      hasVerticalScroll,
      hasHorizontalScroll,
    );
  }
}

/// Result type for scroll information retrieval.
sealed class ScrollOperationResult {
  const ScrollOperationResult();
}

/// Successful scroll information retrieval.
class ScrollSuccess extends ScrollOperationResult {
  final ScrollInfo scrollInfo;

  const ScrollSuccess(this.scrollInfo);
}

/// Scroll operation failed due to various reasons.
class ScrollFailure extends ScrollOperationResult {
  final ScrollFailureReason reason;
  final String? message;
  final String? details;

  const ScrollFailure({
    required this.reason,
    this.message,
    this.details,
  });

  /// User-friendly message for this failure.
  String get userMessage {
    switch (reason) {
      case ScrollFailureReason.windowNotFound:
        return 'Window not found or no longer exists';
      case ScrollFailureReason.windowNotAccessible:
        return 'Window is not accessible (may be on a different Space)';
      case ScrollFailureReason.accessibilityPermissionDenied:
        return 'Accessibility permission required';
      case ScrollFailureReason.noScrollableContent:
        return 'Window has no scrollable content';
      case ScrollFailureReason.unknown:
        return message ?? 'Failed to get scroll information';
    }
  }

  /// Whether this failure can be retried after user action.
  bool get canRetry {
    switch (reason) {
      case ScrollFailureReason.accessibilityPermissionDenied:
        return true;
      case ScrollFailureReason.windowNotFound:
      case ScrollFailureReason.windowNotAccessible:
      case ScrollFailureReason.noScrollableContent:
      case ScrollFailureReason.unknown:
        return false;
    }
  }

  /// Suggested user action for this failure.
  String? get suggestedAction {
    switch (reason) {
      case ScrollFailureReason.accessibilityPermissionDenied:
        return 'Grant accessibility permission in System Settings';
      case ScrollFailureReason.windowNotAccessible:
        return 'Switch to the Space where the window is located';
      case ScrollFailureReason.windowNotFound:
      case ScrollFailureReason.noScrollableContent:
      case ScrollFailureReason.unknown:
        return null;
    }
  }
}

/// Specific reasons for scroll operation failure.
enum ScrollFailureReason {
  /// Window ID is invalid or window no longer exists.
  windowNotFound,

  /// Window exists but cannot be accessed via Accessibility API
  /// (e.g., it is on a different Space or the app does not support AX API).
  windowNotAccessible,

  /// Accessibility permission not granted.
  accessibilityPermissionDenied,

  /// Window has no scrollable content.
  noScrollableContent,

  /// Unknown operation state.
  unknown,
}
