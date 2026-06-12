import 'dart:async';
import 'dart:io' show ProcessInfo, pid;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

/// Memory measurement harness for issue #1.
///
/// Drives the three suspected-leak scenarios while sampling the process
/// resident set size (RSS), so each one can be judged as a real leak,
/// delayed reclaim, or a transient peak:
///
/// 1. Repeated [MacosWindowToolkit.captureWindow] against a chosen window
/// 2. Continuous [MacosWindowToolkit.getAllWindows] polling
/// 3. Long-running [PermissionWatcher], including the all-listeners-cancelled case
///
/// RSS is sampled in-process via [ProcessInfo.currentRss]. The PID is shown
/// so `leaks <pid>` / `footprint <pid>` / Instruments can be attached for
/// deeper inspection. Results can be copied as markdown for the issue.
class MemoryHarnessPage extends StatefulWidget {
  const MemoryHarnessPage({super.key});

  @override
  State<MemoryHarnessPage> createState() => _MemoryHarnessPageState();
}

class _HarnessResult {
  final String scenario;
  final int iterations;
  final Duration elapsed;
  final int rssStart;
  final int rssEnd;
  final int rssPeak;
  int? rssSettle5;
  int? rssSettle15;
  final String? note;

  _HarnessResult({
    required this.scenario,
    required this.iterations,
    required this.elapsed,
    required this.rssStart,
    required this.rssEnd,
    required this.rssPeak,
    this.note,
  });

  String toMarkdownRow() {
    final delta = rssEnd - rssStart;
    final sign = delta >= 0 ? '+' : '';
    return '| $scenario | $iterations | ${elapsed.inSeconds}s '
        '| ${_mb(rssStart)} | ${_mb(rssEnd)} | ${_mb(rssPeak)} '
        '| $sign${_mb(delta)} '
        '| ${rssSettle5 != null ? _mb(rssSettle5!) : '-'} '
        '| ${rssSettle15 != null ? _mb(rssSettle15!) : '-'} '
        '| ${note ?? ''} |';
  }
}

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';

class _MemoryHarnessPageState extends State<MemoryHarnessPage> {
  final _toolkit = MacosWindowToolkit();

  // Live RSS display
  Timer? _liveRssTimer;
  int _liveRss = ProcessInfo.currentRss;

  // Scenario inputs
  final _captureIterationsController = TextEditingController(text: '300');
  final _pollIterationsController = TextEditingController(text: '300');
  final _pollIntervalMsController = TextEditingController(text: '1000');
  List<CapturableWindowInfo> _capturableWindows = [];
  int? _selectedWindowId;

  // Current run state
  bool _running = false;
  bool _cancelRequested = false;
  String _runStatus = '';
  List<int> _samples = [];
  final List<String> _log = [];

  // Watcher lab state
  final List<StreamSubscription<PermissionStatus>> _watcherSubs = [];
  int _watcherEvents = 0;
  Timer? _watcherSampler;
  List<int> _watcherSamples = [];
  DateTime? _watcherSamplingStart;

  // Results
  final List<_HarnessResult> _results = [];

  @override
  void initState() {
    super.initState();
    _liveRssTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _liveRss = ProcessInfo.currentRss);
    });
    _refreshCapturableWindows();
  }

  @override
  void dispose() {
    _cancelRequested = true;
    _liveRssTimer?.cancel();
    _watcherSampler?.cancel();
    for (final sub in _watcherSubs) {
      sub.cancel();
    }
    _captureIterationsController.dispose();
    _pollIterationsController.dispose();
    _pollIntervalMsController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _log.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
      if (_log.length > 200) _log.removeRange(200, _log.length);
    });
  }

  Future<void> _refreshCapturableWindows() async {
    try {
      final windows = await _toolkit.getCapturableWindows();
      setState(() {
        _capturableWindows = windows;
        if (_selectedWindowId == null ||
            !windows.any((w) => w.windowId == _selectedWindowId)) {
          _selectedWindowId = windows.isNotEmpty ? windows.first.windowId : null;
        }
      });
    } catch (e) {
      _addLog('Failed to list capturable windows: $e');
    }
  }

  /// Runs [step] [iterations] times, sampling RSS after every iteration,
  /// then takes settle samples 5s and 15s after the loop ends.
  Future<void> _runScenario({
    required String scenario,
    required int iterations,
    required Future<String?> Function(int iteration) step,
    Duration? interval,
  }) async {
    if (_running) return;
    setState(() {
      _running = true;
      _cancelRequested = false;
      _samples = [ProcessInfo.currentRss];
      _runStatus = '$scenario: starting…';
    });
    _addLog('$scenario started ($iterations iterations)');

    final rssStart = ProcessInfo.currentRss;
    var rssPeak = rssStart;
    final stopwatch = Stopwatch()..start();
    String? note;
    var completed = 0;

    for (var i = 0; i < iterations; i++) {
      if (_cancelRequested) {
        note = 'cancelled at iteration $i';
        break;
      }
      try {
        final stepNote = await step(i);
        if (stepNote != null) {
          note = stepNote;
          break;
        }
      } catch (e) {
        note = 'error at iteration $i: $e';
        break;
      }
      completed = i + 1;

      final rss = ProcessInfo.currentRss;
      if (rss > rssPeak) rssPeak = rss;
      _samples.add(rss);
      if (completed % 25 == 0 || completed == iterations) {
        _addLog('$scenario $completed/$iterations — RSS ${_mb(rss)}');
      }
      setState(() {
        _runStatus = '$scenario: $completed/$iterations — RSS ${_mb(rss)} '
            '(peak ${_mb(rssPeak)})';
      });

      if (interval != null) await Future.delayed(interval);
    }

    stopwatch.stop();
    final rssEnd = ProcessInfo.currentRss;
    final result = _HarnessResult(
      scenario: scenario,
      iterations: completed,
      elapsed: stopwatch.elapsed,
      rssStart: rssStart,
      rssEnd: rssEnd,
      rssPeak: rssPeak,
      note: note,
    );
    setState(() {
      _results.add(result);
      _running = false;
      _runStatus = '$scenario: done — RSS ${_mb(rssEnd)} '
          '(Δ ${_mb(rssEnd - rssStart)}, peak ${_mb(rssPeak)}). Settling…';
    });
    _addLog('$scenario finished: start ${_mb(rssStart)} → end ${_mb(rssEnd)}, '
        'peak ${_mb(rssPeak)}${note != null ? ' ($note)' : ''}');

    // Settle samples: distinguish "leak" from "delayed reclaim".
    unawaited(_takeSettleSamples(result, scenario));
  }

  Future<void> _takeSettleSamples(_HarnessResult result, String scenario) async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    setState(() => result.rssSettle5 = ProcessInfo.currentRss);
    _addLog('$scenario settle +5s: ${_mb(result.rssSettle5!)}');
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted) return;
    setState(() => result.rssSettle15 = ProcessInfo.currentRss);
    _addLog('$scenario settle +15s: ${_mb(result.rssSettle15!)}');
  }

  // --- Scenario 1: repeated captureWindow ---

  Future<void> _runCaptureScenario() async {
    final windowId = _selectedWindowId;
    if (windowId == null) {
      _addLog('No window selected for capture scenario');
      return;
    }
    final iterations = int.tryParse(_captureIterationsController.text) ?? 300;
    var lastImageBytes = 0;
    await _runScenario(
      scenario: 'captureWindow',
      iterations: iterations,
      step: (i) async {
        final result = await _toolkit.captureWindow(windowId);
        switch (result) {
          case CaptureSuccess(imageData: final data):
            // Drop the bytes immediately — the harness must not hold onto
            // frames, otherwise Dart-side retention would mask the verdict.
            lastImageBytes = data.length;
            if (i == 0) {
              _addLog('captureWindow frame size: ${_mb(lastImageBytes)}');
            }
            return null;
          case CaptureFailure():
            return 'capture failed: ${result.userMessage}';
        }
      },
    );
  }

  // --- Scenario 2: getAllWindows polling ---

  Future<void> _runPollingScenario() async {
    final iterations = int.tryParse(_pollIterationsController.text) ?? 300;
    final intervalMs = int.tryParse(_pollIntervalMsController.text) ?? 1000;
    await _runScenario(
      scenario: 'getAllWindows',
      iterations: iterations,
      interval: Duration(milliseconds: intervalMs),
      step: (i) async {
        final windows = await _toolkit.getAllWindows();
        if (i == 0) _addLog('getAllWindows returned ${windows.length} windows');
        return null;
      },
    );
  }

  // --- Scenario 3: PermissionWatcher lab ---

  void _watcherStart() {
    PermissionWatcher.instance.startWatching();
    _addLog('PermissionWatcher.startWatching()');
    setState(() {});
  }

  void _watcherStop() {
    PermissionWatcher.instance.stopWatching();
    _addLog('PermissionWatcher.stopWatching()');
    setState(() {});
  }

  void _watcherAddListener() {
    final sub = PermissionWatcher.instance.permissionStream.listen((status) {
      _watcherEvents++;
    });
    _watcherSubs.add(sub);
    _addLog('Listener added (${_watcherSubs.length} active)');
    setState(() {});
  }

  Future<void> _watcherCancelListeners() async {
    for (final sub in _watcherSubs) {
      await sub.cancel();
    }
    final count = _watcherSubs.length;
    _watcherSubs.clear();
    _addLog('$count listener(s) cancelled — watcher isWatching: '
        '${PermissionWatcher.instance.isWatching}');
    setState(() {});
  }

  void _watcherToggleSampling() {
    if (_watcherSampler != null) {
      _watcherSampler!.cancel();
      _watcherSampler = null;
      final samples = _watcherSamples;
      if (samples.length >= 2) {
        final result = _HarnessResult(
          scenario: 'PermissionWatcher (long-run)',
          iterations: samples.length,
          elapsed: DateTime.now().difference(_watcherSamplingStart!),
          rssStart: samples.first,
          rssEnd: samples.last,
          rssPeak: samples.reduce((a, b) => a > b ? a : b),
          note: 'isWatching=${PermissionWatcher.instance.isWatching}, '
              'listeners=${_watcherSubs.length}, events=$_watcherEvents',
        );
        _results.add(result);
        unawaited(_takeSettleSamples(result, 'PermissionWatcher'));
      }
      _addLog('Watcher RSS sampling stopped (${samples.length} samples)');
      setState(() {});
    } else {
      _watcherSamples = [ProcessInfo.currentRss];
      _watcherSamplingStart = DateTime.now();
      _watcherEvents = 0;
      _watcherSampler = Timer.periodic(const Duration(seconds: 2), (_) {
        _watcherSamples.add(ProcessInfo.currentRss);
        if (_watcherSamples.length % 30 == 0) {
          _addLog('Watcher sampling: ${_watcherSamples.length} samples, '
              'RSS ${_mb(_watcherSamples.last)}, events=$_watcherEvents');
        }
      });
      _addLog('Watcher RSS sampling started (every 2s — leave running '
          'for several minutes)');
      setState(() {});
    }
  }

  // --- Results export ---

  String _resultsAsMarkdown() {
    final buffer = StringBuffer()
      ..writeln('### Memory harness results')
      ..writeln()
      ..writeln('- Date: ${DateTime.now().toIso8601String()}')
      ..writeln('- PID: $pid (RSS via `ProcessInfo.currentRss`)')
      ..writeln('- maxRss: ${_mb(ProcessInfo.maxRss)}')
      ..writeln()
      ..writeln('| Scenario | Iterations | Elapsed | RSS start | RSS end '
          '| RSS peak | Δ end-start | settle +5s | settle +15s | Note |')
      ..writeln('|---|---|---|---|---|---|---|---|---|---|');
    for (final result in _results) {
      buffer.writeln(result.toMarkdownRow());
    }
    return buffer.toString();
  }

  Future<void> _copyResults() async {
    await Clipboard.setData(ClipboardData(text: _resultsAsMarkdown()));
    _addLog('Results copied as markdown (${_results.length} rows)');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Harness (issue #1)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(colorScheme),
          const SizedBox(height: 12),
          _buildCaptureCard(),
          const SizedBox(height: 12),
          _buildPollingCard(),
          const SizedBox(height: 12),
          _buildWatcherCard(),
          const SizedBox(height: 12),
          if (_running || _samples.length > 1) _buildRunCard(colorScheme),
          const SizedBox(height: 12),
          _buildResultsCard(),
          const SizedBox(height: 12),
          _buildLogCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Process', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('PID $pid — RSS ${_mb(_liveRss)} '
                      '(maxRss ${_mb(ProcessInfo.maxRss)})'),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy PID',
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: '$pid')),
                ),
              ],
            ),
            Text(
              'Deeper inspection: `leaks $pid`, `footprint $pid`, or attach '
              'Instruments (Allocations/Leaks).',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scenario 1 — repeated captureWindow',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Pick a large window (e.g. a maximized browser) for a '
              'worst-case frame size.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedWindowId,
                    hint: const Text('Select window'),
                    items: _capturableWindows
                        .map((w) => DropdownMenuItem(
                              value: w.windowId,
                              child: Text(
                                '${w.ownerName} — ${w.title} '
                                '(${w.frame.width.toInt()}×${w.frame.height.toInt()})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: _running
                        ? null
                        : (value) => setState(() => _selectedWindowId = value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh window list',
                  onPressed: _running ? null : _refreshCapturableWindows,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _captureIterationsController,
                    enabled: !_running,
                    decoration: const InputDecoration(
                      labelText: 'Iterations',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run'),
                  onPressed: _running ? null : _runCaptureScenario,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scenario 2 — getAllWindows polling',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _pollIterationsController,
                    enabled: !_running,
                    decoration: const InputDecoration(
                      labelText: 'Iterations',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _pollIntervalMsController,
                    enabled: !_running,
                    decoration: const InputDecoration(
                      labelText: 'Interval (ms)',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run'),
                  onPressed: _running ? null : _runPollingScenario,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatcherCard() {
    final watching = PermissionWatcher.instance.isWatching;
    final sampling = _watcherSampler != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scenario 3 — PermissionWatcher long-run',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Start the watcher and RSS sampling, leave it running for '
              'several minutes. Cancel all listeners while watching to '
              'reproduce the "polling with nobody listening" case.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text('isWatching: $watching · listeners: ${_watcherSubs.length} '
                '· events: $_watcherEvents'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: watching ? null : _watcherStart,
                  child: const Text('startWatching'),
                ),
                OutlinedButton(
                  onPressed: watching ? _watcherStop : null,
                  child: const Text('stopWatching'),
                ),
                OutlinedButton(
                  onPressed: _watcherAddListener,
                  child: const Text('Add listener'),
                ),
                OutlinedButton(
                  onPressed: _watcherSubs.isEmpty ? null : _watcherCancelListeners,
                  child: const Text('Cancel all listeners'),
                ),
                FilledButton.icon(
                  icon: Icon(sampling ? Icons.stop : Icons.play_arrow),
                  label: Text(sampling
                      ? 'Stop sampling (${_watcherSamples.length})'
                      : 'Start RSS sampling'),
                  onPressed: _watcherToggleSampling,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Current run',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (_running)
                  TextButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    onPressed: () => _cancelRequested = true,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_runStatus),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(
                  samples: _samples,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Results (${_results.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy markdown'),
                  onPressed: _results.isEmpty ? null : _copyResults,
                ),
              ],
            ),
            for (final result in _results)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${result.scenario}: ${result.iterations} iter, '
                  '${_mb(result.rssStart)} → ${_mb(result.rssEnd)} '
                  '(peak ${_mb(result.rssPeak)}'
                  '${result.rssSettle5 != null ? ', +5s ${_mb(result.rssSettle5!)}' : ''}'
                  '${result.rssSettle15 != null ? ', +15s ${_mb(result.rssSettle15!)}' : ''})'
                  '${result.note != null ? ' — ${result.note}' : ''}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, index) => Text(
                  _log[index],
                  style: const TextStyle(fontSize: 12, fontFamily: 'Menlo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal RSS-over-iterations sparkline: enough to tell a climbing line
/// (leak) from a flat one with spikes (transient peaks).
class _SparklinePainter extends CustomPainter {
  final List<int> samples;
  final Color color;

  _SparklinePainter({required this.samples, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    final minSample = samples.reduce((a, b) => a < b ? a : b);
    final maxSample = samples.reduce((a, b) => a > b ? a : b);
    final range = (maxSample - minSample).clamp(1, double.maxFinite.toInt());

    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = i / (samples.length - 1) * size.width;
      final y = size.height -
          ((samples[i] - minSample) / range) * (size.height - 16) -
          8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final textStyle = TextStyle(fontSize: 10, color: color);
    _drawLabel(canvas, _mb(maxSample), Offset.zero, textStyle);
    _drawLabel(canvas, _mb(minSample), Offset(0, size.height - 12), textStyle);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.color != color;
}
