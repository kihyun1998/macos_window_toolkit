// Automated memory measurement for issue #1.
//
// Runs the three suspected-leak scenarios while sampling RSS and prints a
// markdown report to stdout between REPORT markers:
//
//   flutter test integration_test/memory_harness_test.dart -d macos
//
// Iteration counts are kept moderate so the whole run stays under ~3 minutes;
// raise them (or use the in-app Memory Harness page) for longer soak runs.
import 'dart:io' show ProcessInfo;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

String _mb(num bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';

class ScenarioReport {
  final String scenario;
  final int iterations;
  final Duration elapsed;
  final List<int> samples;
  String? note;
  int? settle5;
  int? settle15;

  ScenarioReport({
    required this.scenario,
    required this.iterations,
    required this.elapsed,
    required this.samples,
    this.note,
  });

  int get rssStart => samples.first;
  int get rssEnd => samples.last;
  int get rssPeak => samples.reduce((a, b) => a > b ? a : b);

  /// Median of the first/last 10 samples — crude trend signal that is robust
  /// against single-sample spikes.
  String get trend {
    if (samples.length < 20) return 'n/a';
    final head = _median(samples.take(10).toList());
    final tail = _median(samples.skip(samples.length - 10).toList());
    final growth = tail - head;
    return '${growth >= 0 ? '+' : ''}${_mb(growth)} (first10→last10 median)';
  }

  static int _median(List<int> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  String toMarkdownRow() {
    final delta = rssEnd - rssStart;
    return '| $scenario | $iterations | ${elapsed.inSeconds}s '
        '| ${_mb(rssStart)} | ${_mb(rssEnd)} | ${_mb(rssPeak)} '
        '| ${delta >= 0 ? '+' : ''}${_mb(delta)} | $trend '
        '| ${settle5 != null ? _mb(settle5!) : '-'} '
        '| ${settle15 != null ? _mb(settle15!) : '-'} '
        '| ${note ?? ''} |';
  }
}

Future<ScenarioReport> runScenario({
  required String scenario,
  required int iterations,
  required Future<String?> Function(int iteration) step,
  Duration? interval,
}) async {
  // ignore: avoid_print
  print('--- $scenario: $iterations iterations starting, '
      'RSS ${_mb(ProcessInfo.currentRss)}');
  final samples = <int>[ProcessInfo.currentRss];
  final stopwatch = Stopwatch()..start();
  String? note;
  var completed = 0;

  for (var i = 0; i < iterations; i++) {
    final stepNote = await step(i);
    if (stepNote != null) {
      note = stepNote;
      break;
    }
    completed = i + 1;
    samples.add(ProcessInfo.currentRss);
    if (completed % 25 == 0) {
      // ignore: avoid_print
      print('    $scenario $completed/$iterations — '
          'RSS ${_mb(samples.last)}');
    }
    if (interval != null) await Future.delayed(interval);
  }
  stopwatch.stop();

  final report = ScenarioReport(
    scenario: scenario,
    iterations: completed,
    elapsed: stopwatch.elapsed,
    samples: samples,
    note: note,
  );
  await Future.delayed(const Duration(seconds: 5));
  report.settle5 = ProcessInfo.currentRss;
  await Future.delayed(const Duration(seconds: 10));
  report.settle15 = ProcessInfo.currentRss;
  // ignore: avoid_print
  print('--- $scenario done: ${_mb(report.rssStart)} → ${_mb(report.rssEnd)} '
      '(peak ${_mb(report.rssPeak)}, settle ${_mb(report.settle15!)})');
  return report;
}

// Soak-run knobs, e.g.:
//   flutter test integration_test/memory_harness_test.dart -d macos \
//     --dart-define=CAPTURE_ITERATIONS=300 --dart-define=CAPTURE_ONLY=true \
//     --dart-define=HOLD_SECONDS=60
// HOLD_SECONDS keeps the app alive after the scenarios so `leaks <pid>` can
// be attached from another shell.
const int captureIterations =
    int.fromEnvironment('CAPTURE_ITERATIONS', defaultValue: 100);
const bool captureOnly = bool.fromEnvironment('CAPTURE_ONLY');
const int holdSeconds = int.fromEnvironment('HOLD_SECONDS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test(
    'memory harness: capture / window-list / permission-watcher scenarios',
    () async {
      final toolkit = MacosWindowToolkit();
      final reports = <ScenarioReport>[];

      final hasScreenRecording = await toolkit.hasScreenRecordingPermission();
      final hasAccessibility = await toolkit.hasAccessibilityPermission();

      // Scenario 1: repeated captureWindow against the largest capturable
      // window (worst-case frame size).
      if (hasScreenRecording) {
        final windows = await toolkit.getCapturableWindows();
        final candidates = windows
            .where((w) => w.frame.width >= 200 && w.frame.height >= 200)
            .toList()
          ..sort((a, b) => (b.frame.width * b.frame.height)
              .compareTo(a.frame.width * a.frame.height));
        if (candidates.isEmpty) {
          // ignore: avoid_print
          print('--- captureWindow: no capturable window ≥200x200, skipped');
        } else {
          final target = candidates.first;
          // ignore: avoid_print
          print('--- captureWindow target: ${target.ownerName} — '
              '"${target.title}" '
              '(${target.frame.width.toInt()}x${target.frame.height.toInt()})');
          reports.add(await runScenario(
            scenario: 'captureWindow',
            iterations: captureIterations,
            step: (i) async {
              final result = await toolkit.captureWindow(target.windowId);
              return switch (result) {
                CaptureSuccess() => null,
                CaptureFailure() => 'capture failed: ${result.userMessage}',
              };
            },
          ));
        }
      } else {
        // ignore: avoid_print
        print('--- captureWindow: screen recording permission missing, '
            'skipped');
      }

      // Scenario 2: getAllWindows polling. Role/subrole lookups (the churn
      // suspect) only run when accessibility permission is granted, so note
      // the permission state in the report.
      if (!captureOnly) {
      reports.add(await runScenario(
        scenario: 'getAllWindows',
        iterations: 100,
        interval: const Duration(milliseconds: 100),
        step: (_) async {
          await toolkit.getAllWindows();
          return null;
        },
        // ignore: avoid_redundant_argument_values
      )
        ..note = 'accessibility=$hasAccessibility');

      // Scenario 3: PermissionWatcher polling with no listeners — interval
      // shortened to 200ms so ~150 poll cycles fit in 30s of sampling.
      final watcher = PermissionWatcher.instance;
      final sub = watcher.permissionStream.listen((_) {});
      watcher.startWatching(interval: const Duration(milliseconds: 200));
      await Future.delayed(const Duration(seconds: 2));
      await sub.cancel(); // nobody listening, polling should ideally stop
      reports.add(await runScenario(
        scenario: 'PermissionWatcher (no listeners)',
        iterations: 30,
        interval: const Duration(seconds: 1),
        step: (_) async => null,
      )
        ..note = 'poll interval 200ms, listener cancelled after 2s, '
            'isWatching=${watcher.isWatching}');
      watcher.stopWatching();
      }

      // Report
      final buffer = StringBuffer()
        ..writeln('=== MEMORY HARNESS REPORT START ===')
        ..writeln('- maxRss: ${_mb(ProcessInfo.maxRss)}')
        ..writeln('- screenRecording=$hasScreenRecording, '
            'accessibility=$hasAccessibility')
        ..writeln()
        ..writeln('| Scenario | Iterations | Elapsed | RSS start | RSS end '
            '| RSS peak | Δ end-start | Trend | settle +5s | settle +15s '
            '| Note |')
        ..writeln('|---|---|---|---|---|---|---|---|---|---|---|');
      for (final report in reports) {
        buffer.writeln(report.toMarkdownRow());
      }
      buffer.writeln('=== MEMORY HARNESS REPORT END ===');
      // ignore: avoid_print
      print(buffer.toString());

      if (holdSeconds > 0) {
        // ignore: avoid_print
        print('--- holding app alive ${holdSeconds}s for `leaks` attach '
            '(pid via: pgrep -f macos_window_toolkit_example)');
        await Future.delayed(Duration(seconds: holdSeconds));
      }

      expect(reports, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
