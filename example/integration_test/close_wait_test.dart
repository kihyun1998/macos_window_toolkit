// Run:
//   flutter test integration_test/close_wait_test.dart -d macos
//
// Opens its own windows with the system Python's Tk and closes them through
// the plugin, so it needs Accessibility permission for the test host and
// /usr/bin/python3 with tkinter. Every window it opens is killed in teardown.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

/// A Tk window titled by its first argument. Its close button, by mode:
/// - `close-late`: closes the window 1.5 s later and keeps running, like an
///   app that closes a window late
/// - `exit-late`: leaves the window and exits the process 1.5 s later, like an
///   app that quits when its last window is asked to close
/// - `ignore-close`: does nothing, like an app that keeps the window open
const _tkWindow = '''
import os, sys, tkinter
root = tkinter.Tk()
root.title(sys.argv[1])
root.geometry("320x200+200+200")
mode = sys.argv[2]
if mode == "close-late":
    root.protocol("WM_DELETE_WINDOW", lambda: root.after(1500, root.destroy))
elif mode == "exit-late":
    root.protocol("WM_DELETE_WINDOW", lambda: root.after(1500, lambda: os._exit(0)))
elif mode == "ignore-close":
    root.protocol("WM_DELETE_WINDOW", lambda: None)
root.mainloop()
keeper = tkinter.Tk()
keeper.withdraw()
keeper.mainloop()
''';

/// How long a `close-late` or `exit-late` window takes after the press.
const _late = Duration(milliseconds: 1500);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final toolkit = MacosWindowToolkit();
  late Directory dir;
  late File script;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('close_wait');
    script = File('${dir.path}/tk_window.py')..writeAsStringSync(_tkWindow);
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  /// Opens a Tk window and returns its id once the window list shows it.
  Future<int> openWindow(String title, String mode) async {
    final process = await Process.start('/usr/bin/python3', [
      '-I',
      script.path,
      title,
      mode,
    ]);
    addTearDown(() => process.kill(ProcessSignal.sigkill));
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline)) {
      final windows = await toolkit.getWindowsByName(title);
      final open = windows.where((w) => w.isOnScreen && w.name == title);
      if (open.isNotEmpty) return open.first.windowId;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('window "$title" never appeared');
  }

  Future<bool> isOnScreen(int windowId) async =>
      (await toolkit.getWindowById(windowId)).any((w) => w.isOnScreen);

  test(
    'with waitUntilClosed, success comes only once the window has closed',
    () async {
      final id = await openWindow('close-wait closes late', 'close-late');
      final watch = Stopwatch()..start();
      final result = await toolkit.closeWindow(
        id,
        waitUntilClosed: const Duration(seconds: 5),
      );
      expect(
        result,
        isA<OperationSuccess>(),
        reason: result is OperationFailure ? '${result.reason}' : null,
      );
      expect(watch.elapsed, greaterThanOrEqualTo(_late));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    },
  );

  test(
    'with waitUntilClosed, an app that exits instead of closing counts as closed',
    () async {
      final id = await openWindow('close-wait exits late', 'exit-late');
      final watch = Stopwatch()..start();
      final result = await toolkit.closeWindow(
        id,
        waitUntilClosed: const Duration(seconds: 5),
      );
      expect(
        result,
        isA<OperationSuccess>(),
        reason: result is OperationFailure ? '${result.reason}' : null,
      );
      expect(watch.elapsed, greaterThanOrEqualTo(_late));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    },
  );

  test(
    'with waitUntilClosed, a window that stays open is windowStillOpen',
    () async {
      final id = await openWindow('close-wait stays', 'ignore-close');
      final watch = Stopwatch()..start();
      final result = await toolkit.closeWindow(
        id,
        waitUntilClosed: const Duration(seconds: 1),
      );
      expect(
        result,
        isA<OperationFailure>().having(
          (f) => f.reason,
          'reason',
          WindowOperationFailureReason.windowStillOpen,
        ),
      );
      expect(watch.elapsed, greaterThanOrEqualTo(const Duration(seconds: 1)));
      expect(await isOnScreen(id), isTrue);
    },
  );

  test(
    'without waitUntilClosed, success comes as soon as close is pressed',
    () async {
      final id = await openWindow('close-wait no wait', 'close-late');
      final watch = Stopwatch()..start();
      expect(await toolkit.closeWindow(id), isA<OperationSuccess>());
      expect(watch.elapsed, lessThan(_late));
    },
  );
}
