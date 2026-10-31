// Run:
//   flutter test integration_test/focus_wait_test.dart -d macos
//
// Opens its own Tk window with the system Python and focuses it through the
// plugin. Needs Accessibility permission for the test host and
// /usr/bin/python3 with tkinter. It moves the frontmost app between this test
// app, the Tk window and Finder, and kills the Tk window in teardown.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

const _tkWindow = '''
import sys, tkinter
root = tkinter.Tk()
root.title(sys.argv[1])
root.geometry("320x200+240+240")
root.mainloop()
''';

/// The PID of the frontmost application, as LaunchServices reports it.
Future<int?> _frontmostPid() async {
  final front = (await Process.run('/usr/bin/lsappinfo', [
    'front',
  ])).stdout.toString().trim();
  final info = (await Process.run('/usr/bin/lsappinfo', [
    'info',
    '-only',
    'pid',
    front,
  ])).stdout.toString();
  return int.tryParse(RegExp(r'(\d+)\s*$').firstMatch(info)?.group(1) ?? '');
}

/// An applet that activates the process whose PID is in [_pidFile]. An app
/// that `open` launches is frontmost, and a frontmost app may activate
/// another; this test app was not launched through LaunchServices, so `open`
/// cannot bring it forward itself.
const _activator = r'''
ObjC.import('AppKit');
ObjC.import('Foundation');
function run() {
  var pid = parseInt($.NSString.stringWithContentsOfFileEncodingError(
      '/tmp/macos_window_toolkit_focus_pid', $.NSUTF8StringEncoding, null).js);
  $.NSRunningApplication.runningApplicationWithProcessIdentifier(pid)
      .activateWithOptions(0);
}
''';
const _pidFile = '/tmp/macos_window_toolkit_focus_pid';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final toolkit = MacosWindowToolkit();
  late File script;
  late String activatorApp;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('focus_wait');
    script = File('${dir.path}/tk_window.py')..writeAsStringSync(_tkWindow);
    final source = File('${dir.path}/activator.js')
      ..writeAsStringSync(_activator);
    activatorApp = '${dir.path}/Activator.app';
    final compiled = await Process.run('/usr/bin/osacompile', [
      '-l',
      'JavaScript',
      '-o',
      activatorApp,
      source.path,
    ]);
    expect(compiled.exitCode, 0, reason: '${compiled.stderr}');
  });

  tearDownAll(() {
    final file = File(_pidFile);
    if (file.existsSync()) file.deleteSync();
  });

  /// Opens a Tk window and returns its process and window id once listed.
  Future<(Process, int)> openWindow(String title) async {
    final process = await Process.start('/usr/bin/python3', [
      '-I',
      script.path,
      title,
    ]);
    addTearDown(() => process.kill(ProcessSignal.sigkill));
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      final windows = await toolkit.getWindowsByName(title);
      final open = windows.where((w) => w.isOnScreen && w.name == title);
      if (open.isNotEmpty) return (process, open.first.windowId);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('window "$title" never appeared');
  }

  /// Puts Finder in front and waits until it stays there for two reads.
  Future<int> finderInFront() async {
    await Process.run('/usr/bin/open', [
      '/System/Library/CoreServices/Finder.app',
    ]);
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    int? previous;
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final now = await _frontmostPid();
      if (now != null && now != pid && now == previous) return now;
      previous = now;
    }
    throw StateError('Finder did not come to the front');
  }

  /// Puts this test app in front, through the activator applet. Another app
  /// can take the front back meanwhile, so it tries up to three times.
  Future<void> testAppInFront() async {
    File(_pidFile).writeAsStringSync('$pid');
    for (var attempt = 0; attempt < 3; attempt++) {
      await Process.run('/usr/bin/open', [activatorApp]);
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (await _frontmostPid() == pid) return;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    throw StateError('this test app did not come to the front');
  }

  test(
    'with waitUntilFocused, a frontmost caller sees the window focused',
    () async {
      final (tk, id) = await openWindow('focus-wait target');
      await testAppInFront();

      final result = await toolkit.focusWindow(
        id,
        waitUntilFocused: const Duration(seconds: 5),
      );

      expect(result, isA<OperationSuccess>(), reason: '$result');
      expect(await _frontmostPid(), tk.pid, reason: 'the Tk app is in front');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'with waitUntilFocused, a refused activation is windowNotFocused',
    () async {
      final (tk, id) = await openWindow('focus-wait refused');
      await finderInFront();

      final watch = Stopwatch()..start();
      final result = await toolkit.focusWindow(
        id,
        waitUntilFocused: const Duration(seconds: 2),
      );
      watch.stop();

      expect(
        result,
        isA<OperationFailure>().having(
          (f) => f.reason,
          'reason',
          WindowOperationFailureReason.windowNotFocused,
        ),
      );
      expect(watch.elapsed, greaterThanOrEqualTo(const Duration(seconds: 2)));
      expect(await _frontmostPid(), isNot(tk.pid));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'without waitUntilFocused, a refused activation still reports success',
    () async {
      final (tk, id) = await openWindow('focus-wait unconfirmed');
      await finderInFront();

      final result = await toolkit.focusWindow(id);

      expect(result, isA<OperationSuccess>(), reason: '$result');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(await _frontmostPid(), isNot(tk.pid));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
