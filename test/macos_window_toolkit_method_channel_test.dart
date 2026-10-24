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

  test('every code the native side sends is a PlatformErrorCode', () {
    // The codes macos/Classes can put on the wire: WindowError, CaptureError,
    // ApplicationError, the per-call codes and the dispatcher's own.
    const nativeCodes = [
      'FAILED_TO_RETRIEVE_WINDOW_LIST',
      'WINDOW_NOT_FOUND',
      'INSUFFICIENT_WINDOW_INFO',
      'ACCESSIBILITY_PERMISSION_DENIED',
      'CLOSE_BUTTON_NOT_FOUND',
      'CLOSE_ACTION_FAILED',
      'FOCUS_ACTION_FAILED',
      'PROCESS_NOT_FOUND',
      'TERMINATION_FAILED',
      'FAILED_TO_GET_PROCESS_LIST',
      'WINDOW_NOT_ACCESSIBLE',
      'SPACE_SWITCH_API_UNAVAILABLE',
      'INVALID_WINDOW_ID',
      'WINDOW_MINIMIZED',
      'CAPTURE_FAILED',
      'UNSUPPORTED_MACOS_VERSION',
      'REQUIRES_MACOS_14',
      'SCREEN_RECORDING_PERMISSION_DENIED',
      'OPEN_APP_STORE_ERROR',
      'WINDOW_LIST_ERROR',
      'GET_CHILD_PROCESSES_ERROR',
      'GET_APPLICATIONS_ERROR',
      'INVALID_ARGUMENTS',
      'FULLSCREEN_CHECK_FAILED',
    ];

    final missing =
        nativeCodes.where((c) => PlatformErrorCode.fromCode(c) == null);
    expect(missing, isEmpty);
  });

  test('isWindowFullScreen carries the native fields as a details map',
      () async {
    answer(
      'isWindowFullScreen',
      () => {
        'success': false,
        'reason': 'unsupported_version',
        'code': 'REQUIRES_MACOS_14',
        'message': 'Fullscreen detection requires macOS 14.0 or later',
        'details': 'Current version: 13.6.0, Required: 14.0+',
        'errorCode': null,
        'errorDomain': null,
      },
    );

    await expectLater(
      toolkit.isWindowFullScreen(42),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.details,
          'details',
          {
            'code': 'REQUIRES_MACOS_14',
            'message': 'Fullscreen detection requires macOS 14.0 or later',
            'details': 'Current version: 13.6.0, Required: 14.0+',
            'errorCode': null,
            'errorDomain': null,
          },
        ),
      ),
    );
  });

  // Every state macos/Classes declares (PluginError.stateReason), per method
  // that can raise it, with the native code it travels under.
  group('every native state reaches its typed reason, both shapes', () {
    const windowStates = {
      ('window_not_found', 'WINDOW_NOT_FOUND'):
          WindowOperationFailureReason.windowNotFound,
      ('window_not_accessible', 'WINDOW_NOT_ACCESSIBLE'):
          WindowOperationFailureReason.windowNotAccessible,
      ('accessibility_permission_denied', 'ACCESSIBILITY_PERMISSION_DENIED'):
          WindowOperationFailureReason.accessibilityPermissionDenied,
      ('close_button_not_found', 'CLOSE_BUTTON_NOT_FOUND'):
          WindowOperationFailureReason.closeButtonNotFound,
      ('focus_action_failed', 'FOCUS_ACTION_FAILED'):
          WindowOperationFailureReason.focusActionFailed,
      ('process_not_found', 'PROCESS_NOT_FOUND'):
          WindowOperationFailureReason.processNotFound,
    };
    final windowCalls = <String, Future<WindowOperationResult> Function()>{
      'closeWindow': () => toolkit.closeWindow(42),
      'focusWindow': () => toolkit.focusWindow(42),
      'terminateApplicationByPID': () => toolkit.terminateApplicationByPID(42),
      'terminateApplicationTree': () => toolkit.terminateApplicationTree(42),
    };
    windowCalls.forEach((method, call) {
      windowStates.forEach((wire, expected) {
        final (reason, code) = wire;
        test('$method: state $reason → $expected', () async {
          answer(
              method, () => {'success': false, 'reason': reason, 'code': code});
          expect(((await call()) as OperationFailure).reason, expected);
        });
        test('$method: platform error $code → $expected', () async {
          answer(method, () => throw PlatformException(code: code));
          expect(((await call()) as OperationFailure).reason, expected);
        });
      });
    });

    const scrollStates = {
      ('window_not_found', 'WINDOW_NOT_FOUND'):
          ScrollFailureReason.windowNotFound,
      ('window_not_accessible', 'WINDOW_NOT_ACCESSIBLE'):
          ScrollFailureReason.windowNotAccessible,
      ('accessibility_permission_denied', 'ACCESSIBILITY_PERMISSION_DENIED'):
          ScrollFailureReason.accessibilityPermissionDenied,
    };
    scrollStates.forEach((wire, expected) {
      final (reason, code) = wire;
      test('getScrollInfo: state $reason and platform error $code → $expected',
          () async {
        answer('getScrollInfo',
            () => {'success': false, 'reason': reason, 'code': code});
        expect(
          ((await toolkit.getScrollInfo(42)) as ScrollFailure).reason,
          expected,
        );
        answer('getScrollInfo', () => throw PlatformException(code: code));
        expect(
          ((await toolkit.getScrollInfo(42)) as ScrollFailure).reason,
          expected,
        );
      });
    });

    const captureStates = {
      ('window_not_found', 'INVALID_WINDOW_ID'):
          CaptureFailureReason.windowNotFound,
      ('window_minimized', 'WINDOW_MINIMIZED'):
          CaptureFailureReason.windowMinimized,
      ('unsupported_version', 'UNSUPPORTED_MACOS_VERSION'):
          CaptureFailureReason.unsupportedVersion,
      ('unsupported_version', 'REQUIRES_MACOS_14'):
          CaptureFailureReason.unsupportedVersion,
      ('permission_denied', 'SCREEN_RECORDING_PERMISSION_DENIED'):
          CaptureFailureReason.permissionDenied,
    };
    captureStates.forEach((wire, expected) {
      final (reason, code) = wire;
      test(
          'captureWindow: $code keeps its reason and native error, both shapes',
          () async {
        final fields = {
          'code': code,
          'message': 'm',
          'details': 'd',
          'errorCode': -3801,
          'errorDomain': 'com.apple.ScreenCaptureKit.SCStreamErrorDomain',
        };
        for (final shape in ['state', 'platform error']) {
          answer(
            'captureWindow',
            () => shape == 'state'
                ? {'success': false, 'reason': reason, ...fields}
                : throw PlatformException(
                    code: code, message: 'm', details: fields),
          );
          final failure = (await toolkit.captureWindow(42)) as CaptureFailure;
          expect(failure.reason, expected, reason: shape);
          expect(failure.details, 'd', reason: shape);
          expect(failure.errorCode, -3801, reason: shape);
          expect(failure.errorDomain,
              'com.apple.ScreenCaptureKit.SCStreamErrorDomain',
              reason: shape);
        }
      });
    });
  });

  test('isWindowFullScreen throws the native code of a state reply', () async {
    answer(
      'isWindowFullScreen',
      () => {
        'success': false,
        'reason': 'permission_denied',
        'code': 'SCREEN_RECORDING_PERMISSION_DENIED',
        'message': 'Screen recording permission is required',
      },
    );

    await expectLater(
      toolkit.isWindowFullScreen(42),
      throwsA(
        isA<PlatformException>()
            .having(
              (e) => e.code,
              'code',
              'SCREEN_RECORDING_PERMISSION_DENIED',
            )
            .having(
              (e) => e.errorCode,
              'errorCode',
              PlatformErrorCode.captureScreenRecordingPermissionDenied,
            ),
      ),
    );
  });

  test('a platform error carries the native message and details', () async {
    answer(
      'closeWindow',
      () => throw PlatformException(
        code: 'CLOSE_ACTION_FAILED',
        message: 'Failed to perform close action on window',
        details: {
          'code': 'CLOSE_ACTION_FAILED',
          'details': 'The close button was found but clicking it failed.',
        },
      ),
    );

    final failure = await toolkit.closeWindow(42) as OperationFailure;

    expect(failure.message, 'Failed to perform close action on window');
    expect(
      failure.details,
      'The close button was found but clicking it failed.',
    );
  });

  group('process operations share the window reason table', () {
    for (final method in [
      'terminateApplicationByPID',
      'terminateApplicationTree',
    ]) {
      test('$method maps focus_action_failed like the window operations',
          () async {
        answer(
          method,
          () => {'success': false, 'reason': 'focus_action_failed'},
        );

        final result = method == 'terminateApplicationByPID'
            ? await toolkit.terminateApplicationByPID(42)
            : await toolkit.terminateApplicationTree(42);

        expect(
          (result as OperationFailure).reason,
          WindowOperationFailureReason.focusActionFailed,
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
