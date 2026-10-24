// Run:
//   flutter test integration_test/channel_replies_test.dart -d macos
//
// Needs Screen Recording permission for the test host; without it the test
// is skipped.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

/// Frames rendered while [work] runs, from a live binding and a widget that
/// always wants the next frame.
Future<(int frames, Duration elapsed)> framesDuring(
  WidgetTester tester,
  Future<void> Function() work,
) async {
  var frames = 0;
  var counting = true;
  SchedulerBinding.instance.addPersistentFrameCallback((_) {
    if (counting) frames++;
  });
  final watch = Stopwatch()..start();
  await tester.runAsync(work);
  watch.stop();
  counting = false;
  return (frames, watch.elapsed);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final toolkit = MacosWindowToolkit();

  const batch = 20;
  const replyTimeout = Duration(seconds: 30);

  testWidgets(
    'concurrent capture calls all reply while the UI keeps rendering',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: CircularProgressIndicator())),
      );

      var permitted = false;
      await tester.runAsync(() async {
        permitted = await toolkit.hasScreenRecordingPermission().timeout(
          replyTimeout,
        );
      });
      if (!permitted) {
        markTestSkipped('Screen Recording permission is not granted');
        return;
      }

      var windowId = 0;
      await tester.runAsync(() async {
        final windows = await toolkit.getCapturableWindows().timeout(
          replyTimeout,
        );
        windowId = windows
            .firstWhere((w) => w.isOnScreen && w.frame.width > 0)
            .windowId;
      });

      // The frame check below means something only if this window renders
      // while idle: macOS stops frames for a window it considers hidden.
      final (idleFrames, _) = await framesDuring(
        tester,
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      expect(
        idleFrames,
        greaterThanOrEqualTo(10),
        reason:
            'the test window renders no frames while idle; '
            'keep it visible so the frame check can mean anything',
      );

      late List<CaptureResult> captures;
      late List<List<CapturableWindowInfo>> listings;
      late List<bool> fullScreen;
      final (frames, elapsed) = await framesDuring(tester, () async {
        final results = await Future.wait([
          Future.wait([
            for (var i = 0; i < batch; i++) toolkit.captureWindow(windowId),
          ]),
          Future.wait([
            for (var i = 0; i < batch; i++) toolkit.getCapturableWindows(),
          ]),
          Future.wait([
            for (var i = 0; i < batch; i++)
              toolkit.isWindowFullScreen(windowId),
          ]),
        ]).timeout(replyTimeout);
        captures = results[0].cast<CaptureResult>();
        listings = results[1].cast<List<CapturableWindowInfo>>();
        fullScreen = results[2].cast<bool>();
      });

      expect(captures, hasLength(batch));
      expect(
        captures.whereType<CaptureSuccess>(),
        hasLength(batch),
        reason: '${captures.whereType<CaptureFailure>().map((f) => f.reason)}',
      );
      expect(listings, hasLength(batch));
      expect(listings.every((l) => l.isNotEmpty), isTrue);
      expect(fullScreen, hasLength(batch));

      // At 60 Hz a live UI renders about one frame per 16 ms. Require at least
      // one frame per 100 ms of in-flight work: a main thread blocked for the
      // whole batch renders none.
      final floor = elapsed.inMilliseconds ~/ 100;
      expect(frames, greaterThanOrEqualTo(floor));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets('closeWindow still replies with its result', (tester) async {
    late WindowOperationResult result;
    await tester.runAsync(() async {
      result = await toolkit.closeWindow(0x7fffffff).timeout(replyTimeout);
    });
    expect(
      result,
      isA<OperationFailure>().having(
        (f) => f.reason,
        'reason',
        anyOf(
          WindowOperationFailureReason.windowNotFound,
          WindowOperationFailureReason.accessibilityPermissionDenied,
        ),
      ),
    );
  });
}
