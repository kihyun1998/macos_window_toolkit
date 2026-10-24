import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('macos_window_toolkit');
  final toolkit = MacosWindowToolkit();
  final calls = <MethodCall>[];

  /// Records every call and answers it with [respond], which returns the
  /// native reply or throws a [PlatformException] the way a native
  /// `FlutterError` arrives in Dart.
  void answer(Object? Function(MethodCall call) respond) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return respond(call);
    });
  }

  /// Answers every call with [reply].
  void reply(Object? reply) => answer((_) => reply);

  /// The single recorded call, checked against [method] and [arguments].
  void expectCall(String method, [Object? arguments]) {
    expect(calls, hasLength(1));
    expect(calls.single.method, method);
    expect(calls.single.arguments, arguments);
  }

  setUp(() {
    calls.clear();
    MacosWindowToolkitPlatform.instance = MethodChannelMacosWindowToolkit();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  const windowMap = {
    'windowId': 7,
    'name': 'Doc',
    'ownerName': 'Pages',
    'x': 1,
    'y': 2.5,
    'width': 300,
    'height': 200.0,
    'layer': 0,
    'isOnScreen': true,
    'processId': 42,
    'storeType': 1,
    'sharingState': 1,
    'alpha': 1,
    'memoryUsage': 2048,
    'isInVideoMemory': false,
    'role': 'AXWindow',
    'subrole': 'AXStandardWindow',
  };

  const window = MacosWindowInfo(
    windowId: 7,
    name: 'Doc',
    ownerName: 'Pages',
    x: 1,
    y: 2.5,
    width: 300,
    height: 200,
    layer: 0,
    isOnScreen: true,
    processId: 42,
    storeType: 1,
    sharingState: 1,
    alpha: 1,
    memoryUsage: 2048,
    isInVideoMemory: false,
    role: 'AXWindow',
    subrole: 'AXStandardWindow',
  );

  const emptyWindow = MacosWindowInfo(
    windowId: 0,
    name: '',
    ownerName: '',
    x: 0,
    y: 0,
    width: 0,
    height: 0,
    layer: 0,
    isOnScreen: false,
    processId: 0,
  );

  group('windows', () {
    final queries =
        <String, (Future<List<MacosWindowInfo>> Function(), Object?)>{
      'getAllWindows': (() => toolkit.getAllWindows(), null),
      'getWindowsByName': (
        () => toolkit.getWindowsByName('Doc'),
        {'name': 'Doc'}
      ),
      'getWindowsByOwnerName': (
        () => toolkit.getWindowsByOwnerName('Pages'),
        {'ownerName': 'Pages'},
      ),
      'getWindowById': (() => toolkit.getWindowById(7), {'windowId': 7}),
      'getWindowsByProcessId': (
        () => toolkit.getWindowsByProcessId(42),
        {'processId': 42},
      ),
      'getWindowsAdvanced': (() => toolkit.getWindowsAdvanced(), null),
    };

    for (final MapEntry(key: method, value: (query, arguments))
        in queries.entries) {
      test('$method sends its arguments and parses each window', () async {
        reply([windowMap]);
        expect(await query(), [window]);
        expectCall(method, arguments);
      });

      test('$method: missing keys take their defaults', () async {
        reply([<Object?, Object?>{}]);
        expect(await query(), [emptyWindow]);
      });

      test('$method: no reply is an empty list', () async {
        reply(null);
        expect(await query(), isEmpty);
      });
    }

    test('getAllWindows sends excludeEmptyNames only when set', () async {
      reply(<Object?>[]);
      await toolkit.getAllWindows(excludeEmptyNames: true);
      expectCall('getAllWindows', {'excludeEmptyNames': true});
    });

    test('getWindowsAdvanced sends only the filters that are set', () async {
      reply(<Object?>[]);
      await toolkit.getWindowsAdvanced(
        windowId: 1,
        name: 'n',
        nameExactMatch: true,
        nameCaseSensitive: false,
        nameWildcard: true,
        ownerName: 'o',
        ownerNameExactMatch: false,
        ownerNameCaseSensitive: true,
        ownerNameWildcard: false,
        processId: 2,
        isOnScreen: true,
        layer: 3,
        x: 4,
        y: 5,
        width: 6,
        height: 7,
      );
      expectCall('getWindowsAdvanced', {
        'windowId': 1,
        'name': 'n',
        'nameExactMatch': true,
        'nameCaseSensitive': false,
        'nameWildcard': true,
        'ownerName': 'o',
        'ownerNameExactMatch': false,
        'ownerNameCaseSensitive': true,
        'ownerNameWildcard': false,
        'processId': 2,
        'isOnScreen': true,
        'layer': 3,
        'x': 4.0,
        'y': 5.0,
        'width': 6.0,
        'height': 7.0,
      });
    });

    test('isWindowAlive sends expectedName only when set', () async {
      reply(true);
      expect(await toolkit.isWindowAlive(7), isTrue);
      expectCall('isWindowAlive', {'windowId': 7});

      calls.clear();
      reply(null);
      expect(await toolkit.isWindowAlive(7, expectedName: 'Doc'), isFalse);
      expectCall('isWindowAlive', {'windowId': 7, 'expectedName': 'Doc'});
    });

    for (final method in ['closeWindow', 'focusWindow']) {
      Future<WindowOperationResult> call() => method == 'closeWindow'
          ? toolkit.closeWindow(7)
          : toolkit.focusWindow(7);

      test('$method sends the window id and parses a success map', () async {
        reply({'success': true});
        expect(await call(), isA<OperationSuccess>());
        expectCall(method, {'windowId': 7});
      });

      test('$method accepts a bool reply', () async {
        reply(true);
        expect(await call(), isA<OperationSuccess>());
        reply(false);
        expect(
          await call(),
          isA<OperationFailure>()
              .having((f) => f.reason, 'reason',
                  WindowOperationFailureReason.unknown)
              .having((f) => f.message, 'message', 'Operation returned false'),
        );
      });
    }

    test('isWindowFullScreen sends the window id and returns the bool',
        () async {
      reply(true);
      expect(await toolkit.isWindowFullScreen(7), isTrue);
      expectCall('isWindowFullScreen', {'windowId': 7});

      reply(null);
      expect(await toolkit.isWindowFullScreen(7), isFalse);
    });

    test('getScrollInfo sends the window id and parses the scroll info',
        () async {
      reply({
        'success': true,
        'scrollInfo': {
          'verticalPosition': 1,
          'horizontalPosition': 0.5,
          'hasVerticalScroll': true,
          'hasHorizontalScroll': true,
        },
      });
      expect(
        await toolkit.getScrollInfo(7),
        isA<ScrollSuccess>().having(
          (s) => s.scrollInfo,
          'scrollInfo',
          const ScrollInfo(
            verticalPosition: 1,
            horizontalPosition: 0.5,
            hasVerticalScroll: true,
            hasHorizontalScroll: true,
          ),
        ),
      );
      expectCall('getScrollInfo', {'windowId': 7});
    });

    test('getScrollInfo: missing scroll keys take their defaults', () async {
      reply({'success': true, 'scrollInfo': <Object?, Object?>{}});
      expect(
        await toolkit.getScrollInfo(7),
        isA<ScrollSuccess>()
            .having((s) => s.scrollInfo, 'scrollInfo', const ScrollInfo()),
      );
    });

    test('getScrollInfo: success without scroll info is a failure', () async {
      reply({'success': true});
      expect(
        await toolkit.getScrollInfo(7),
        isA<ScrollFailure>()
            .having((f) => f.reason, 'reason', ScrollFailureReason.unknown),
      );
    });
  });

  group('capture', () {
    test('captureWindow sends its defaults and returns the image', () async {
      final image = Uint8List.fromList([1, 2, 3]);
      reply({'success': true, 'imageData': image});
      expect(
        await toolkit.captureWindow(7),
        isA<CaptureSuccess>().having((s) => s.imageData, 'imageData', image),
      );
      expectCall('captureWindow', {
        'windowId': 7,
        'excludeTitlebar': false,
        'preserveAspectRatio': false,
        'resizeCroppedToWindowSize': true,
      });
    });

    test('captureWindow sends every optional argument that is set', () async {
      reply({'success': true, 'imageData': Uint8List(0)});
      await toolkit.captureWindow(
        7,
        excludeTitlebar: true,
        customTitlebarHeight: 28,
        targetWidth: 1,
        targetHeight: 2,
        preserveAspectRatio: true,
        cropContentWidth: 3,
        cropContentHeight: 4,
        cropX: 5,
        cropY: 6,
        cropWidth: 7,
        cropHeight: 8,
        resizeCroppedToWindowSize: false,
      );
      expectCall('captureWindow', {
        'windowId': 7,
        'excludeTitlebar': true,
        'preserveAspectRatio': true,
        'resizeCroppedToWindowSize': false,
        'customTitlebarHeight': 28.0,
        'targetWidth': 1,
        'targetHeight': 2,
        'cropContentWidth': 3,
        'cropContentHeight': 4,
        'cropX': 5,
        'cropY': 6,
        'cropWidth': 7,
        'cropHeight': 8,
      });
    });

    test('captureWindow: success without image data is a failure', () async {
      reply({'success': true});
      expect(
        await toolkit.captureWindow(7),
        isA<CaptureFailure>()
            .having((f) => f.reason, 'reason', CaptureFailureReason.unknown),
      );
    });

    test('getCapturableWindows parses each window and its nested frame',
        () async {
      reply([
        {
          'windowId': 9,
          'title': 'T',
          'ownerName': 'O',
          'bundleIdentifier': 'com.example',
          'frame': {'x': 1, 'y': 2, 'width': 3.5, 'height': 4},
          'isOnScreen': true,
        },
      ]);
      expect(await toolkit.getCapturableWindows(), [
        const CapturableWindowInfo(
          windowId: 9,
          title: 'T',
          ownerName: 'O',
          bundleIdentifier: 'com.example',
          frame: CapturableWindowFrame(x: 1, y: 2, width: 3.5, height: 4),
          isOnScreen: true,
        ),
      ]);
      expectCall('getCapturableWindows');
    });

    test('getCapturableWindows: missing keys take their defaults', () async {
      reply([<Object?, Object?>{}]);
      expect(await toolkit.getCapturableWindows(), [
        const CapturableWindowInfo(
          windowId: 0,
          title: '',
          ownerName: '',
          bundleIdentifier: '',
          frame: CapturableWindowFrame(x: 0, y: 0, width: 0, height: 0),
          isOnScreen: false,
        ),
      ]);
    });
  });

  group('permissions', () {
    final checks = <String, Future<bool> Function()>{
      'hasScreenRecordingPermission': toolkit.hasScreenRecordingPermission,
      'requestScreenRecordingPermission':
          toolkit.requestScreenRecordingPermission,
      'openScreenRecordingSettings': toolkit.openScreenRecordingSettings,
      'hasAccessibilityPermission': toolkit.hasAccessibilityPermission,
      'requestAccessibilityPermission': toolkit.requestAccessibilityPermission,
      'openAccessibilitySettings': toolkit.openAccessibilitySettings,
    };

    for (final MapEntry(key: method, value: check) in checks.entries) {
      test('$method returns the bool, and false for no reply', () async {
        reply(true);
        expect(await check(), isTrue);
        expectCall(method);

        reply(null);
        expect(await check(), isFalse);
      });
    }
  });

  group('processes', () {
    for (final method in [
      'terminateApplicationByPID',
      'terminateApplicationTree',
    ]) {
      Future<WindowOperationResult> call({bool? force}) {
        final terminate = method == 'terminateApplicationByPID'
            ? toolkit.terminateApplicationByPID
            : toolkit.terminateApplicationTree;
        return force == null ? terminate(42) : terminate(42, force: force);
      }

      test('$method sends the pid and force, and parses success', () async {
        reply({'success': true});
        expect(await call(), isA<OperationSuccess>());
        expectCall(method, {'processId': 42, 'force': false});

        calls.clear();
        reply(true);
        expect(await call(force: true), isA<OperationSuccess>());
        expectCall(method, {'processId': 42, 'force': true});
      });
    }

    test('getChildProcesses sends the pid and returns the pids', () async {
      reply([3, 4]);
      expect(await toolkit.getChildProcesses(42), [3, 4]);
      expectCall('getChildProcesses', {'processId': 42});

      reply(null);
      expect(await toolkit.getChildProcesses(42), isEmpty);
    });
  });

  group('applications', () {
    const appMap = {
      'name': 'Pages',
      'bundleId': 'com.apple.Pages',
      'version': '14.0',
      'path': '/Applications/Pages.app',
      'iconPath': '/Applications/Pages.app/icon.icns',
    };
    const app = MacosApplicationInfo(
      name: 'Pages',
      bundleId: 'com.apple.Pages',
      version: '14.0',
      path: '/Applications/Pages.app',
      iconPath: '/Applications/Pages.app/icon.icns',
    );
    const emptyApp = MacosApplicationInfo(
      name: '',
      bundleId: '',
      version: '',
      path: '',
      iconPath: '',
    );

    test('getAllInstalledApplications parses each application', () async {
      reply([appMap, <Object?, Object?>{}]);
      expect(
        await toolkit.getAllInstalledApplications(),
        isA<ApplicationSuccess>()
            .having((s) => s.applications, 'applications', [app, emptyApp]),
      );
      expectCall('getAllInstalledApplications');
    });

    test('getAllInstalledApplications: an empty list is notFound', () async {
      reply(<Object?>[]);
      expect(
        await toolkit.getAllInstalledApplications(),
        isA<ApplicationFailure>().having(
            (f) => f.reason, 'reason', ApplicationFailureReason.notFound),
      );
    });

    test('getApplicationByName sends the name; an empty list is success',
        () async {
      reply([appMap]);
      expect(
        await toolkit.getApplicationByName('Pages'),
        isA<ApplicationSuccess>()
            .having((s) => s.applications, 'applications', [app]),
      );
      expectCall('getApplicationByName', {'name': 'Pages'});

      reply(<Object?>[]);
      expect(
        await toolkit.getApplicationByName('Pages'),
        isA<ApplicationSuccess>()
            .having((s) => s.applications, 'applications', isEmpty),
      );
    });

    test('application calls turn any error into systemError', () async {
      answer((_) => throw PlatformException(code: 'GET_APPLICATIONS_ERROR'));
      for (final result in [
        await toolkit.getAllInstalledApplications(),
        await toolkit.getApplicationByName('Pages'),
      ]) {
        expect(
          result,
          isA<ApplicationFailure>().having(
              (f) => f.reason, 'reason', ApplicationFailureReason.systemError),
        );
      }
    });

    test('openAppStoreSearch sends the term and returns the bool', () async {
      reply(true);
      expect(await toolkit.openAppStoreSearch('notes'), isTrue);
      expectCall('openAppStoreSearch', {'searchTerm': 'notes'});

      reply(null);
      expect(await toolkit.openAppStoreSearch('notes'), isFalse);
    });
  });

  group('system info', () {
    test('getMacOSVersionInfo parses the version', () async {
      reply({
        'majorVersion': 14,
        'minorVersion': 2,
        'patchVersion': 1,
        'versionString': '14.2.1',
        'isScreenCaptureKitAvailable': true,
      });
      expect(
        await toolkit.getMacOSVersionInfo(),
        const MacosVersionInfo(
          majorVersion: 14,
          minorVersion: 2,
          patchVersion: 1,
          versionString: '14.2.1',
          isScreenCaptureKitAvailable: true,
        ),
      );
      expectCall('getMacOSVersionInfo');
    });

    test('getMacOSVersionInfo: no reply takes the defaults', () async {
      reply(null);
      expect(
        await toolkit.getMacOSVersionInfo(),
        const MacosVersionInfo(
          majorVersion: 0,
          minorVersion: 0,
          patchVersion: 0,
          versionString: '',
          isScreenCaptureKitAvailable: false,
        ),
      );
    });

    test('getScreenScaleFactor returns the factor, and 1.0 for no reply',
        () async {
      reply(2.0);
      expect(await toolkit.getScreenScaleFactor(), 2.0);
      expectCall('getScreenScaleFactor');

      reply(null);
      expect(await toolkit.getScreenScaleFactor(), 1.0);
    });

    test('getAllScreensInfo parses each screen and its nested frames',
        () async {
      reply([
        {
          'index': 1,
          'isMain': true,
          'scaleFactor': 2,
          'frame': {'x': 0, 'y': 0, 'width': 1440, 'height': 900},
          'visibleFrame': {'x': 0, 'y': 25, 'width': 1440, 'height': 875},
          'pixelWidth': 2880,
          'pixelHeight': 1800,
        },
        <Object?, Object?>{},
      ]);
      expect(await toolkit.getAllScreensInfo(), [
        const MacosScreenInfo(
          index: 1,
          isMain: true,
          scaleFactor: 2,
          frame: ScreenRect(x: 0, y: 0, width: 1440, height: 900),
          visibleFrame: ScreenRect(x: 0, y: 25, width: 1440, height: 875),
          pixelWidth: 2880,
          pixelHeight: 1800,
        ),
        const MacosScreenInfo(
          index: 0,
          isMain: false,
          scaleFactor: 1,
          frame: ScreenRect(x: 0, y: 0, width: 0, height: 0),
          visibleFrame: ScreenRect(x: 0, y: 0, width: 0, height: 0),
          pixelWidth: 0,
          pixelHeight: 0,
        ),
      ]);
      expectCall('getAllScreensInfo');
    });
  });

  group('every result-typed call fails the same way', () {
    final resultCalls = <String, Future<Object> Function()>{
      'closeWindow': () => toolkit.closeWindow(7),
      'focusWindow': () => toolkit.focusWindow(7),
      'terminateApplicationByPID': () => toolkit.terminateApplicationByPID(42),
      'terminateApplicationTree': () => toolkit.terminateApplicationTree(42),
      'captureWindow': () => toolkit.captureWindow(7),
      'getScrollInfo': () => toolkit.getScrollInfo(7),
    };

    /// The reason name and message of any failure result, or `null` for a
    /// success.
    (String, String?)? failureOf(Object result) => switch (result) {
          OperationFailure(:final reason, :final message) => (
              reason.name,
              message
            ),
          CaptureFailure(:final reason, :final message) => (
              reason.name,
              message
            ),
          ScrollFailure(:final reason, :final message) => (
              reason.name,
              message
            ),
          _ => null,
        };

    for (final MapEntry(key: method, value: call) in resultCalls.entries) {
      test('$method: no reply', () async {
        reply(null);
        expect(
            failureOf(await call()), ('unknown', 'No response from $method'));
      });

      test('$method: a reply of an unexpected type', () async {
        reply('surprise');
        expect(failureOf(await call()),
            ('unknown', 'Unexpected response from $method'));
      });

      test('$method: a system-code platform error is rethrown', () async {
        answer((_) => throw PlatformException(code: 'INVALID_ARGUMENTS'));
        await expectLater(
          call(),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'INVALID_ARGUMENTS')),
        );
      });

      test('$method: any other platform error is a failure', () async {
        answer((_) => throw PlatformException(
              code: 'WINDOW_NOT_FOUND',
              message: 'gone',
            ));
        expect(failureOf(await call()), ('windowNotFound', 'gone'));
      });
    }
  });
}
