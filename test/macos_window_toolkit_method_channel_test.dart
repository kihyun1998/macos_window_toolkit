import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('macos_window_toolkit');
  final toolkit = MacosWindowToolkit();

  /// Answers every call to [method] with [respond], which returns the
  /// native reply or throws a [PlatformException] the way a native
  /// `FlutterError` arrives in Dart.
  void answer(String method, Object? Function() respond) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method != method) {
        throw MissingPluginException('unexpected ${call.method}');
      }
      return respond();
    });
  }

  setUp(() {
    MacosWindowToolkitPlatform.instance = MethodChannelMacosWindowToolkit();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('closeWindow', () {
    test('an inaccessible window is reported as windowNotAccessible', () async {
      answer(
        'closeWindow',
        () => throw PlatformException(
          code: 'WINDOW_NOT_ACCESSIBLE',
          message: 'Window is not accessible via Accessibility API',
        ),
      );

      final result = await toolkit.closeWindow(42);

      expect(
        result,
        isA<OperationFailure>().having(
          (f) => f.reason,
          'reason',
          WindowOperationFailureReason.windowNotAccessible,
        ),
      );
    });

    test(
        'an inaccessible-window state reply is reported as windowNotAccessible',
        () async {
      answer(
        'closeWindow',
        () => {
          'success': false,
          'reason': 'window_not_accessible',
          'message': 'Window is not accessible via Accessibility API',
        },
      );

      final result = await toolkit.closeWindow(42);

      expect(
        result,
        isA<OperationFailure>().having(
          (f) => f.reason,
          'reason',
          WindowOperationFailureReason.windowNotAccessible,
        ),
      );
    });
  });

  test('windowNotAccessible is not retryable and names both causes', () {
    const failure = OperationFailure(
      reason: WindowOperationFailureReason.windowNotAccessible,
    );

    expect(failure.canRetry, isFalse);
    expect(failure.userMessage, contains('different Space'));
    expect(failure.userMessage, contains('Accessibility'));
    expect(failure.suggestedAction, contains('Space'));
    expect(failure.suggestedAction, contains('Accessibility'));
  });

  group('closeWindow keeps every existing reason', () {
    const byCode = {
      'WINDOW_NOT_FOUND': WindowOperationFailureReason.windowNotFound,
      'INVALID_WINDOW_ID': WindowOperationFailureReason.windowNotFound,
      'PROCESS_NOT_FOUND': WindowOperationFailureReason.processNotFound,
      'ACCESSIBILITY_PERMISSION_DENIED':
          WindowOperationFailureReason.accessibilityPermissionDenied,
      'CLOSE_BUTTON_NOT_FOUND':
          WindowOperationFailureReason.closeButtonNotFound,
      'FOCUS_ACTION_FAILED': WindowOperationFailureReason.focusActionFailed,
      'CLOSE_ACTION_FAILED': WindowOperationFailureReason.unknown,
    };
    const byReason = {
      'window_not_found': WindowOperationFailureReason.windowNotFound,
      'process_not_found': WindowOperationFailureReason.processNotFound,
      'accessibility_permission_denied':
          WindowOperationFailureReason.accessibilityPermissionDenied,
      'close_button_not_found':
          WindowOperationFailureReason.closeButtonNotFound,
      'focus_action_failed': WindowOperationFailureReason.focusActionFailed,
      'something_new': WindowOperationFailureReason.unknown,
    };

    byCode.forEach((code, expected) {
      test('platform error $code → $expected', () async {
        answer('closeWindow', () => throw PlatformException(code: code));
        final result = await toolkit.closeWindow(42);
        expect((result as OperationFailure).reason, expected);
      });
    });
    byReason.forEach((reason, expected) {
      test('state reply $reason → $expected', () async {
        answer('closeWindow', () => {'success': false, 'reason': reason});
        final result = await toolkit.closeWindow(42);
        expect((result as OperationFailure).reason, expected);
      });
    });

    test('INVALID_ARGUMENTS is rethrown', () async {
      answer(
        'closeWindow',
        () => throw PlatformException(code: 'INVALID_ARGUMENTS'),
      );
      expect(
        toolkit.closeWindow(42),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')),
      );
    });
  });

  group('getScrollInfo keeps every existing reason', () {
    const byCode = {
      'WINDOW_NOT_FOUND': ScrollFailureReason.windowNotFound,
      'INVALID_WINDOW_ID': ScrollFailureReason.windowNotFound,
      'ACCESSIBILITY_PERMISSION_DENIED':
          ScrollFailureReason.accessibilityPermissionDenied,
      'NO_SCROLLABLE_CONTENT': ScrollFailureReason.noScrollableContent,
    };
    const byReason = {
      'window_not_found': ScrollFailureReason.windowNotFound,
      'accessibility_permission_denied':
          ScrollFailureReason.accessibilityPermissionDenied,
      'no_scrollable_content': ScrollFailureReason.noScrollableContent,
      'something_new': ScrollFailureReason.unknown,
    };

    byCode.forEach((code, expected) {
      test('platform error $code → $expected', () async {
        answer('getScrollInfo', () => throw PlatformException(code: code));
        final result = await toolkit.getScrollInfo(42);
        expect((result as ScrollFailure).reason, expected);
      });
    });
    byReason.forEach((reason, expected) {
      test('state reply $reason → $expected', () async {
        answer('getScrollInfo', () => {'success': false, 'reason': reason});
        final result = await toolkit.getScrollInfo(42);
        expect((result as ScrollFailure).reason, expected);
      });
    });
  });

  group('captureWindow keeps every existing reason', () {
    const byCode = {
      'WINDOW_MINIMIZED': CaptureFailureReason.windowMinimized,
      'INVALID_WINDOW_ID': CaptureFailureReason.windowNotFound,
      'UNSUPPORTED_MACOS_VERSION': CaptureFailureReason.unsupportedVersion,
      'PERMISSION_DENIED': CaptureFailureReason.permissionDenied,
      'SCREEN_RECORDING_PERMISSION_DENIED':
          CaptureFailureReason.permissionDenied,
      'CAPTURE_IN_PROGRESS': CaptureFailureReason.captureInProgress,
      'WINDOW_NOT_CAPTURABLE': CaptureFailureReason.windowNotCapturable,
      'CAPTURE_FAILED': CaptureFailureReason.unknown,
    };
    const byReason = {
      'window_minimized': CaptureFailureReason.windowMinimized,
      'window_not_found': CaptureFailureReason.windowNotFound,
      'unsupported_version': CaptureFailureReason.unsupportedVersion,
      'permission_denied': CaptureFailureReason.permissionDenied,
      'capture_in_progress': CaptureFailureReason.captureInProgress,
      'window_not_capturable': CaptureFailureReason.windowNotCapturable,
      'something_new': CaptureFailureReason.unknown,
    };

    byCode.forEach((code, expected) {
      test('platform error $code → $expected', () async {
        answer('captureWindow', () => throw PlatformException(code: code));
        final result = await toolkit.captureWindow(42);
        expect((result as CaptureFailure).reason, expected);
      });
    });
    byReason.forEach((reason, expected) {
      test('state reply $reason → $expected', () async {
        answer('captureWindow', () => {'success': false, 'reason': reason});
        final result = await toolkit.captureWindow(42);
        expect((result as CaptureFailure).reason, expected);
      });
    });
  });

  group('getScrollInfo', () {
    for (final (shape, respond) in <(String, Object? Function())>[
      (
        'platform error',
        () => throw PlatformException(code: 'WINDOW_NOT_ACCESSIBLE'),
      ),
      (
        'state reply',
        () => {'success': false, 'reason': 'window_not_accessible'},
      ),
    ]) {
      test('an inaccessible window ($shape) is reported as windowNotAccessible',
          () async {
        answer('getScrollInfo', respond);

        final result = await toolkit.getScrollInfo(42);

        expect(
          result,
          isA<ScrollFailure>().having(
            (f) => f.reason,
            'reason',
            ScrollFailureReason.windowNotAccessible,
          ),
        );
      });
    }
  });

  group('captureWindow', () {
    test('capture on macOS before 14.0 is reported as unsupportedVersion',
        () async {
      answer(
        'captureWindow',
        () => throw PlatformException(
          code: 'REQUIRES_MACOS_14',
          message: 'Window capture requires macOS 14.0 or later',
          details: {
            'code': 'REQUIRES_MACOS_14',
            'details': 'Current version: 13.6.0, Required: 14.0+',
          },
        ),
      );

      final result = await toolkit.captureWindow(42);

      expect(
        result,
        isA<CaptureFailure>().having(
          (f) => f.reason,
          'reason',
          CaptureFailureReason.unsupportedVersion,
        ),
      );
    });
  });
}
