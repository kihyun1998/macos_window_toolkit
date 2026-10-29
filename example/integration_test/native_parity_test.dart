// Run, once per build, with the desktop left alone in between:
//   flutter test integration_test/native_parity_test.dart -d macos \
//     --dart-define=PARITY_OUT=/path/to/this-build.json \
//     [--dart-define=PARITY_BASELINE=/path/to/other-build.json]
//
// Records the raw channel reply of every read-only call, and of the error path
// of the calls that act on windows and processes, as one JSON object in
// PARITY_OUT. With PARITY_BASELINE it fails on every reply that differs from
// that file. Nothing is closed, focused or terminated: every acting call is
// given a target that does not exist.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _channel = MethodChannel('macos_window_toolkit');

/// A window ID and a PID that no window or process has.
const _missingWindowId = 0x7ffffff0;
const _missingPid = 0x7ffffff0;

/// The reply of one call: its value, or the error it raised.
Future<Object?> _call(String method, [Map<String, Object?>? arguments]) async {
  try {
    return {'value': await _channel.invokeMethod<Object?>(method, arguments)};
  } on PlatformException catch (e) {
    return {
      'error': {'code': e.code, 'message': e.message, 'details': e.details},
    };
  } on MissingPluginException {
    return {'notImplemented': method};
  }
}

/// `value`, with every map's keys sorted, so equal replies encode equally.
Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _sorted(value[k])};
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}

/// Three Tk windows of one process at fixed places: one holding a text view
/// taller than the window, one titled with the first's title as a prefix, and
/// one with no title.
const _fixture = '''
import tkinter
root = tkinter.Tk()
root.title("parity fixture")
root.geometry("360x240+120+160")
bar = tkinter.Scrollbar(root)
bar.pack(side="right", fill="y")
text = tkinter.Text(root, yscrollcommand=bar.set)
text.insert("1.0", "\\n".join("line %d" % i for i in range(300)))
text.pack(side="left", fill="both", expand=True)
bar.config(command=text.yview)
other = tkinter.Toplevel(root)
other.title("parity fixture two")
other.geometry("240x160+520+160")
untitled = tkinter.Toplevel(root)
untitled.title("")
untitled.geometry("200x120+800+160")
root.mainloop()
''';

/// An AppKit window whose content is a scroll view larger than the window
/// both ways, so its scroll bars are Accessibility elements.
const _scrollFixture = r'''
ObjC.import('Cocoa');
var app = $.NSApplication.sharedApplication;
app.setActivationPolicy($.NSApplicationActivationPolicyRegular);
var win = $.NSWindow.alloc.initWithContentRectStyleMaskBackingDefer(
  $.NSMakeRect(120, 480, 360, 240),
  $.NSWindowStyleMaskTitled | $.NSWindowStyleMaskClosable,
  $.NSBackingStoreBuffered, false);
win.title = 'parity scroll fixture';
var scroll = $.NSScrollView.alloc.initWithFrame($.NSMakeRect(0, 0, 360, 240));
scroll.hasVerticalScroller = true;
scroll.hasHorizontalScroller = true;
var text = $.NSTextView.alloc.initWithFrame($.NSMakeRect(0, 0, 900, 4000));
var lines = []; for (var i = 0; i < 300; i++) lines.push('line ' + i + ' ' + 'x'.repeat(120));
text.string = lines.join('\n');
text.horizontallyResizable = true;
text.textContainer.widthTracksTextView = false;
text.textContainer.containerSize = $.NSMakeSize(100000, 100000);
scroll.documentView = text;
win.contentView = scroll;
win.makeKeyAndOrderFront(null);
app.run;
''';

/// `value` with the fixtures' window IDs and PIDs replaced by labels, since
/// they change from run to run.
Object? _labelled(
  Object? value,
  Map<int, String> windowIds,
  Map<int, String> pids,
) {
  if (value is Map) {
    return {
      for (final e in value.entries)
        e.key: switch (e.key) {
          'windowId' when windowIds.containsKey(e.value) => windowIds[e.value],
          'processId' when pids.containsKey(e.value) => pids[e.value],
          _ => _labelled(e.value, windowIds, pids),
        },
    };
  }
  if (value is List) {
    return value.map((v) => _labelled(v, windowIds, pids)).toList();
  }
  return value;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('native replies, for comparison across builds', () async {
    final dir = Directory.systemTemp.createTempSync('native_parity');
    addTearDown(() => dir.deleteSync(recursive: true));
    final script = File('${dir.path}/fixture.py')..writeAsStringSync(_fixture);
    final fixture = await Process.start('/usr/bin/python3', [
      '-I',
      script.path,
    ]);
    addTearDown(() => fixture.kill(ProcessSignal.sigkill));
    final scrollScript = File('${dir.path}/scroll_fixture.js')
      ..writeAsStringSync(_scrollFixture);
    final scrollFixture = await Process.start('/usr/bin/osascript', [
      '-l',
      'JavaScript',
      scrollScript.path,
    ]);
    addTearDown(() => scrollFixture.kill(ProcessSignal.sigkill));
    final fixtureIds = <int, String>{};
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (fixtureIds.length < 4 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final windows = [
        for (final pid in [fixture.pid, scrollFixture.pid])
          ...?await _channel.invokeListMethod<Map>('getWindowsByProcessId', {
            'processId': pid,
          }),
      ];
      for (final w in windows) {
        if (w['isOnScreen'] != true) continue;
        final label = switch (w['name']) {
          'parity fixture' => 'fixture',
          'parity fixture two' => 'fixture two',
          'parity scroll fixture' => 'scroll fixture',
          '' when w['processId'] == fixture.pid => 'fixture untitled',
          _ => null,
        };
        if (label != null) fixtureIds[w['windowId'] as int] = label;
      }
    }
    expect(fixtureIds, hasLength(4), reason: 'every fixture window appeared');
    // Lets the text view settle before its scroll bar is read.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final out = <String, Object?>{};
    Future<void> record(
      String key,
      String method, [
      Map<String, Object?>? arguments,
    ]) async {
      out[key] = await _call(method, arguments);
    }

    await record('getAllWindows', 'getAllWindows');
    await record('getAllWindows.excludeEmptyNames', 'getAllWindows', {
      'excludeEmptyNames': true,
    });

    final all = ((await _channel.invokeListMethod<Map>('getAllWindows')) ?? [])
        .map((w) => Map<String, Object?>.from(w))
        .toList();
    // The fixture windows, plus two picked by a rule that picks the same
    // windows in both runs while the desktop is left alone: by window ID, the
    // first named on-screen window with an Accessibility element and the
    // first with none.
    final named =
        all
            .where(
              (w) =>
                  (w['name'] as String).length >= 3 &&
                  w['isOnScreen'] == true &&
                  !fixtureIds.containsKey(w['windowId']),
            )
            .toList()
          ..sort(
            (a, b) => (a['windowId'] as int).compareTo(b['windowId'] as int),
          );
    final targets = [
      ...all.where((w) => fixtureIds.containsKey(w['windowId'])),
      ...named.where((w) => w['subrole'] == 'AXStandardWindow').take(1),
      ...named.where((w) => w['role'] == null).take(1),
    ];
    out['targets'] = targets
        .map((w) => {'windowId': w['windowId'], 'name': w['name']})
        .toList();

    for (final w in targets) {
      final id = w['windowId'] as int;
      final label = fixtureIds[id] ?? '$id';
      final name = w['name'] as String;
      final owner = w['ownerName'] as String;
      final pid = w['processId'] as int;
      final head = name.length < 2 ? name : name.substring(0, 2);
      final tail = name.isEmpty ? '' : name.substring(name.length - 1);
      final rest = name.isEmpty ? '' : name.substring(1);
      await record('byName[$label]', 'getWindowsByName', {'name': name});
      await record('byOwner[$label]', 'getWindowsByOwnerName', {
        'ownerName': owner,
      });
      await record('byId[$label]', 'getWindowById', {'windowId': id});
      await record('byPid[$label]', 'getWindowsByProcessId', {
        'processId': pid,
      });
      await record('alive[$label]', 'isWindowAlive', {'windowId': id});
      await record('alive[$label,name]', 'isWindowAlive', {
        'windowId': id,
        'expectedName': name,
      });
      await record('alive[$label,wrongName]', 'isWindowAlive', {
        'windowId': id,
        'expectedName': '$name-',
      });
      // Only the fixture's scroll bars stay put between runs.
      if (fixtureIds.containsKey(id)) {
        await record('scroll[$label]', 'getScrollInfo', {'windowId': id});
      }
      // A window with no Accessibility element: focus and scroll fail before
      // acting, each with its own reason.
      if (w['role'] == null && !fixtureIds.containsKey(id)) {
        await record('scroll[$label]', 'getScrollInfo', {'windowId': id});
        await record('focus[$label]', 'focusWindow', {'windowId': id});
      }
      await record('fullscreen[$label]', 'isWindowFullScreen', {
        'windowId': id,
      });
      final variants = <String, Map<String, Object?>>{
        'exact': {'name': name, 'nameExactMatch': true},
        'exactWrongCase': {'name': name.toUpperCase(), 'nameExactMatch': true},
        'caseInsensitive': {
          'name': name.toUpperCase(),
          'nameCaseSensitive': false,
        },
        'exactCaseInsensitive': {
          'name': name.toLowerCase(),
          'nameExactMatch': true,
          'nameCaseSensitive': false,
        },
        'wildcardStar': {'name': '$head*', 'nameWildcard': true},
        'wildcardStarExact': {
          'name': '$head*$tail',
          'nameWildcard': true,
          'nameExactMatch': true,
        },
        'wildcardQuestion': {'name': '?$rest', 'nameWildcard': true},
        'wildcardCaseInsensitive': {
          'name': '${head.toUpperCase()}*',
          'nameWildcard': true,
          'nameCaseSensitive': false,
        },
        'owner': {'ownerName': owner},
        'ownerExactCaseInsensitive': {
          'ownerName': owner.toLowerCase(),
          'ownerNameExactMatch': true,
          'ownerNameCaseSensitive': false,
        },
        'ownerWildcard': {
          'ownerName': '*${owner.substring(1)}',
          'ownerNameWildcard': true,
        },
        'id': {'windowId': id},
        'pidAndName': {'processId': pid, 'name': name},
        'bounds': {
          'x': w['x'],
          'y': w['y'],
          'width': w['width'],
          'height': w['height'],
        },
        'layerOnScreen': {'layer': w['layer'], 'isOnScreen': true},
      };
      for (final entry in variants.entries) {
        await record(
          'advanced[$label,${entry.key}]',
          'getWindowsAdvanced',
          entry.value,
        );
      }
    }

    await record('advanced[none]', 'getWindowsAdvanced', {});
    await record('advanced[offScreen]', 'getWindowsAdvanced', {
      'isOnScreen': false,
    });
    await record('advanced[noMatch]', 'getWindowsAdvanced', {
      'name': '\u0000no window has this name',
    });
    await record('byName[empty]', 'getWindowsByName', {'name': ''});
    await record('byId[missing]', 'getWindowById', {
      'windowId': _missingWindowId,
    });
    await record('alive[missing]', 'isWindowAlive', {
      'windowId': _missingWindowId,
    });

    await record('close[missing]', 'closeWindow', {
      'windowId': _missingWindowId,
    });
    await record('close[missing,wait]', 'closeWindow', {
      'windowId': _missingWindowId,
      'waitUntilClosedMs': 300,
    });
    await record('focus[missing]', 'focusWindow', {
      'windowId': _missingWindowId,
    });
    await record('scroll[missing]', 'getScrollInfo', {
      'windowId': _missingWindowId,
    });
    await record('capture[missing]', 'captureWindow', {
      'windowId': _missingWindowId,
    });
    await record('fullscreen[missing]', 'isWindowFullScreen', {
      'windowId': _missingWindowId,
    });
    await record('terminate[missing]', 'terminateApplicationByPID', {
      'processId': _missingPid,
    });
    for (final pid in [-1, 0, 1, 0x100000000]) {
      await record('terminate[$pid]', 'terminateApplicationByPID', {
        'processId': pid,
      });
      await record('terminateTree[$pid]', 'terminateApplicationTree', {
        'processId': pid,
      });
    }
    await record('terminateTree[missing]', 'terminateApplicationTree', {
      'processId': _missingPid,
    });
    await record('children[missing]', 'getChildProcesses', {
      'processId': _missingPid,
    });
    await record('children[outOfRange]', 'getChildProcesses', {
      'processId': 0x100000000,
    });

    for (final method in [
      'getWindowsByName',
      'getWindowsByOwnerName',
      'getWindowById',
      'getWindowsByProcessId',
      'isWindowAlive',
      'closeWindow',
      'focusWindow',
      'getScrollInfo',
      'captureWindow',
      'isWindowFullScreen',
      'terminateApplicationByPID',
      'terminateApplicationTree',
      'getChildProcesses',
      'getApplicationByName',
      'openAppStoreSearch',
    ]) {
      await record('missingArguments[$method]', method);
    }
    await record('unknownMethod', 'noSuchMethod');

    await record(
      'hasScreenRecordingPermission',
      'hasScreenRecordingPermission',
    );
    await record('hasAccessibilityPermission', 'hasAccessibilityPermission');
    await record('getMacOSVersionInfo', 'getMacOSVersionInfo');
    await record('getScreenScaleFactor', 'getScreenScaleFactor');
    await record('getAllScreensInfo', 'getAllScreensInfo');

    await record('getCapturableWindows', 'getCapturableWindows');

    final recorded =
        _sorted(
              _labelled(out, fixtureIds, {
                fixture.pid: 'fixture',
                scrollFixture.pid: 'scroll fixture',
              }),
            )
            as Map<String, Object?>;
    const outPath = String.fromEnvironment('PARITY_OUT');
    expect(outPath, isNotEmpty, reason: 'PARITY_OUT names the output file');
    File(outPath).writeAsStringSync(jsonEncode(recorded));

    const baselinePath = String.fromEnvironment('PARITY_BASELINE');
    if (baselinePath.isEmpty) return;
    final baseline =
        jsonDecode(File(baselinePath).readAsStringSync())
            as Map<String, Object?>;
    final differences = <String>[];
    for (final key in {...baseline.keys, ...recorded.keys}) {
      if (!baseline.containsKey(key) || !recorded.containsKey(key)) {
        // A target-keyed reply exists only when both runs chose that target.
        if (key.contains('[') && !key.startsWith('missingArguments')) continue;
        differences.add('$key: recorded in one run only');
        continue;
      }
      _compare(key, baseline[key], recorded[key], differences);
    }
    expect(differences, isEmpty, reason: differences.join('\n'));
  });
}

/// Keys whose values change between two runs on an untouched desktop.
const _volatileKeys = {'memoryUsage'};

/// Keys that change between two runs on a window the test does not own, as
/// its app and the person at the desk move, show and hide it. The fixtures pin
/// these keys.
const _foreignVolatileKeys = {
  'x',
  'y',
  'width',
  'height',
  'frame',
  'isOnScreen',
  'alpha',
};

/// Keys that also change on an untitled window the test does not own: it takes
/// the role of its app's first titled Accessibility window, which changes as
/// the app opens and closes windows.
const _untitledForeignVolatileKeys = {'role', 'subrole'};

/// Adds to `differences` every place where `a` and `b` differ. A list of
/// windows is compared by `windowId`, over the windows both runs saw.
void _compare(String path, Object? a, Object? b, List<String> differences) {
  if (a is List && b is List && _isWindowList(a) && _isWindowList(b)) {
    final byId = {for (final w in b.cast<Map>()) w['windowId']: w};
    final idsA = {for (final w in a.cast<Map>()) w['windowId']};
    // A fixture window's ID is a label by now, and it is in a list in both
    // runs or in neither.
    for (final id in {...idsA, ...byId.keys}.whereType<String>()) {
      if (idsA.contains(id) != byId.containsKey(id)) {
        differences.add('$path#$id: listed in one run only');
      }
    }
    var shared = 0;
    for (final w in a.cast<Map>()) {
      final other = byId[w['windowId']];
      if (other == null || _followsThePointer(w)) continue;
      shared++;
      _compare('$path#${w['windowId']}', w, other, differences);
    }
    if (shared == 0 && (a.isNotEmpty || b.isNotEmpty)) {
      differences.add('$path: no window in common');
    }
    return;
  }
  if (a is Map && b is Map) {
    // A fixture window's ID is a label by now; any other is still a number.
    final foreign = a['windowId'] is int;
    final untitled = a['name'] == '';
    for (final key in {...a.keys, ...b.keys}) {
      if (_volatileKeys.contains(key)) continue;
      if (foreign && _foreignVolatileKeys.contains(key)) continue;
      if (foreign && untitled && _untitledForeignVolatileKeys.contains(key)) {
        continue;
      }
      if (a.containsKey(key) != b.containsKey(key)) {
        differences.add('$path.$key: present in one run only');
        continue;
      }
      _compare('$path.$key', a[key], b[key], differences);
    }
    return;
  }
  if (a is List && b is List) {
    if (a.length != b.length) {
      differences.add('$path: ${a.length} vs ${b.length} items');
      return;
    }
    for (var i = 0; i < a.length; i++) {
      _compare('$path[$i]', a[i], b[i], differences);
    }
    return;
  }
  if (a != b) differences.add('$path: $a vs $b');
}

/// The Window Server's cursor window, which moves with the pointer. Its owner
/// reads `Window Server` in the window list and empty in ScreenCaptureKit.
bool _followsThePointer(Map<Object?, Object?> window) =>
    const {'Window Server', ''}.contains(window['ownerName']) &&
    (window['name'] ?? window['title']) == 'Cursor';

bool _isWindowList(List<Object?> list) =>
    list.isNotEmpty && list.every((w) => w is Map && w.containsKey('windowId'));
