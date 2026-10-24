// Run:
//   flutter test integration_test/process_tree_test.dart -d macos
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

/// A process counts as gone when `ps` no longer lists it or lists it as a
/// zombie, which has exited and only waits to be reaped by its parent.
Future<bool> isGone(int pid) async {
  final ps = await Process.run('ps', ['-o', 'stat=', '-p', '$pid']);
  final stat = (ps.stdout as String).trim();
  return ps.exitCode != 0 || stat.isEmpty || stat.startsWith('Z');
}

Future<bool> allGone(List<int> pids) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final gone = await Future.wait(pids.map(isGone));
    if (gone.every((g) => g)) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return false;
}

/// Polls [MacosWindowToolkit.getChildProcesses] until [pid] has a child.
Future<int> childOf(MacosWindowToolkit toolkit, int pid) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    final children = await toolkit.getChildProcesses(pid);
    if (children.isNotEmpty) return children.single;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  throw StateError('process $pid never started a child');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final toolkit = MacosWindowToolkit();

  for (final force in [false, true]) {
    test(
      'terminateApplicationTree(force: $force) terminates grandchildren',
      () async {
        // root sh → child sh → grandchild sleep
        final root = await Process.start('/bin/sh', [
          '-c',
          '/bin/sh -c "sleep 300 & wait" & wait',
        ]);
        final child = await childOf(toolkit, root.pid);
        final grandchild = await childOf(toolkit, child);
        final tree = [root.pid, child, grandchild];
        addTearDown(() {
          for (final pid in tree) {
            Process.killPid(pid, ProcessSignal.sigkill);
          }
        });

        final result = await toolkit.terminateApplicationTree(
          root.pid,
          force: force,
        );

        expect(
          result,
          isA<OperationSuccess>(),
          reason: result is OperationFailure
              ? '${result.reason} ${result.message} ${result.details}'
              : null,
        );
        expect(
          await allGone(tree),
          isTrue,
          reason: 'root ${root.pid}, child $child, grandchild $grandchild',
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  }

  // Never passes a PID <= 0 to a terminate call, nor PID 1 to tree
  // termination: with the guard broken, those signal the caller's process
  // group, every process the user may signal, or every descendant of launchd.
  // PID 1 alone is safe to pass, since a non-root caller cannot signal launchd.
  group('a PID no terminate call may signal', () {
    const outOfRange = 1 << 40;
    final isRoot =
        (Process.runSync('id', ['-u']).stdout as String).trim() == '0';

    final refused = isA<OperationFailure>()
        .having(
          (f) => f.reason,
          'reason',
          WindowOperationFailureReason.processNotFound,
        )
        .having((f) => f.message, 'message', contains('greater than 1'));

    for (final pid in [1, outOfRange]) {
      test(
        'terminateApplicationByPID($pid) is refused as processNotFound',
        () async {
          expect(await toolkit.terminateApplicationByPID(pid), refused);
        },
        skip: isRoot,
      );
    }

    test(
      'terminateApplicationTree($outOfRange) is refused as processNotFound',
      () async {
        expect(await toolkit.terminateApplicationTree(outOfRange), refused);
      },
    );

    test('getChildProcesses of an out-of-range PID is empty', () async {
      expect(await toolkit.getChildProcesses(outOfRange), isEmpty);
    });

    test(
      'a live process the caller may not signal is not processNotFound',
      () async {
        final ps = await Process.run('ps', ['-U', '0', '-o', 'pid=']);
        final rootPid = (ps.stdout as String)
            .split('\n')
            .map((line) => int.tryParse(line.trim()))
            .firstWhere((pid) => pid != null && pid > 1);

        final result = await toolkit.terminateApplicationByPID(rootPid!);
        expect(
          result,
          isA<OperationFailure>().having(
            (f) => f.reason,
            'reason',
            isNot(WindowOperationFailureReason.processNotFound),
          ),
        );
      },
      skip: isRoot,
    );
  });
}
