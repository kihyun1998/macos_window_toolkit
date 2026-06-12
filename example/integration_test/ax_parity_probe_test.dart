// Temporary probe for issue #3: measures getAllWindows latency and prints a
// role/subrole histogram, to compare before/after the PID-grouped AX lookup
// change. Run:
//   flutter test integration_test/ax_parity_probe_test.dart -d macos
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('getAllWindows latency + role/subrole histogram', () async {
    final toolkit = MacosWindowToolkit();
    final hasAccessibility = await toolkit.hasAccessibilityPermission();

    // Warmup
    await toolkit.getAllWindows();

    const n = 20;
    final stopwatch = Stopwatch()..start();
    var windows = <MacosWindowInfo>[];
    for (var i = 0; i < n; i++) {
      windows = await toolkit.getAllWindows();
    }
    stopwatch.stop();

    final histogram = <String, int>{};
    for (final window in windows) {
      if (window.role != null || window.subrole != null) {
        final key = '${window.role ?? '-'}/${window.subrole ?? '-'}';
        histogram[key] = (histogram[key] ?? 0) + 1;
      }
    }
    final entries = histogram.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer()
      ..writeln('=== AX PROBE START ===')
      ..writeln('accessibility=$hasAccessibility')
      ..writeln('avg getAllWindows latency: '
          '${(stopwatch.elapsedMilliseconds / n).toStringAsFixed(1)}ms '
          'over $n calls')
      ..writeln('windows: ${windows.length}, '
          'with role/subrole: ${histogram.values.fold(0, (a, b) => a + b)}');
    for (final entry in entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln('=== AX PROBE END ===');
    // ignore: avoid_print
    print(buffer.toString());

    expect(windows, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
