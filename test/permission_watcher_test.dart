import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

/// Fake platform that counts permission checks. Any other platform method
/// throws via [noSuchMethod]. While [failing] is set, each Screen Recording
/// check throws and is counted in [failedCalls]; while [holding] is set, it
/// waits for its entry in [held].
class _FakePlatform extends MacosWindowToolkitPlatform {
  int permissionCalls = 0;
  bool screenRecording = true;
  bool accessibility = true;
  bool holding = false;
  bool failing = false;
  int failedCalls = 0;
  final held = <Completer<bool>>[];

  @override
  Future<bool> hasScreenRecordingPermission() async {
    permissionCalls++;
    if (failing) {
      failedCalls++;
      throw StateError('platform failed');
    }
    if (holding) {
      final reply = Completer<bool>();
      held.add(reply);
      return reply.future;
    }
    return screenRecording;
  }

  @override
  Future<bool> hasAccessibilityPermission() async {
    permissionCalls++;
    return accessibility;
  }
}

void main() {
  late _FakePlatform platform;
  final watcher = PermissionWatcher.instance;

  const tick = Duration(milliseconds: 20);

  /// Long enough for several polling ticks.
  Future<void> pumpTicks() => Future.delayed(tick * 5);

  setUp(() {
    platform = _FakePlatform();
    MacosWindowToolkitPlatform.instance = platform;
  });

  tearDown(() {
    // Reset singleton state between tests.
    watcher.dispose();
  });

  test('polls while a listener is subscribed', () async {
    final events = <PermissionStatus>[];
    final sub = watcher.permissionStream.listen(events.add);
    watcher.startWatching(interval: tick, emitOnlyChanges: false);

    await pumpTicks();

    expect(watcher.isWatching, isTrue);
    expect(platform.permissionCalls, greaterThanOrEqualTo(2));
    expect(events, isNotEmpty);
    expect(events.first.screenRecording, isTrue);
    expect(events.first.accessibility, isTrue);

    await sub.cancel();
  });

  test('auto-stops polling when the last listener cancels', () async {
    final sub = watcher.permissionStream.listen((_) {});
    watcher.startWatching(interval: tick);
    await pumpTicks();
    expect(watcher.isWatching, isTrue);

    await sub.cancel();

    expect(watcher.isWatching, isFalse);
    // Allow in-flight async checks to finish, then verify calls stop.
    await pumpTicks();
    final callsAfterCancel = platform.permissionCalls;
    await pumpTicks();
    expect(platform.permissionCalls, callsAfterCancel,
        reason: 'no platform calls may occur while nobody listens');
  });

  test('resumes polling when a new listener subscribes after auto-stop',
      () async {
    final sub1 = watcher.permissionStream.listen((_) {});
    watcher.startWatching(interval: tick);
    await sub1.cancel();
    expect(watcher.isWatching, isFalse);

    final events = <PermissionStatus>[];
    final sub2 = watcher.permissionStream.listen(events.add);

    expect(watcher.isWatching, isTrue,
        reason: 'watch request is still active, so listening resumes polling');
    final callsBefore = platform.permissionCalls;
    await pumpTicks();
    expect(platform.permissionCalls, greaterThan(callsBefore));

    await sub2.cancel();
  });

  test('explicit stopWatching prevents resume on new listener', () async {
    watcher.startWatching(interval: tick);
    watcher.stopWatching();
    expect(watcher.isWatching, isFalse);

    // Let the initial in-flight check from startWatching finish first.
    await pumpTicks();

    final sub = watcher.permissionStream.listen((_) {});
    expect(watcher.isWatching, isFalse,
        reason: 'stopWatching withdraws the watch request');

    final callsBefore = platform.permissionCalls;
    await pumpTicks();
    expect(platform.permissionCalls, callsBefore);

    await sub.cancel();
  });

  test('startWatching without listeners polls until listeners come and go',
      () async {
    watcher.startWatching(interval: tick);
    expect(watcher.isWatching, isTrue,
        reason: 'explicit start polls even before a listener subscribes');
    await pumpTicks();
    expect(platform.permissionCalls, greaterThanOrEqualTo(2));
  });

  test('emitOnlyChanges emits the initial state, then only changes', () async {
    final events = <PermissionStatus>[];
    final sub = watcher.permissionStream.listen(events.add);
    watcher.startWatching(interval: tick);
    await pumpTicks();
    expect(events, hasLength(1), reason: 'unchanged polls emit nothing');

    platform.accessibility = false;
    await pumpTicks();
    expect(events, hasLength(2));
    expect(events.last.accessibility, isFalse);
    expect(events.last.hasChanges, isTrue);

    platform.screenRecording = false;
    await pumpTicks();
    expect(events, hasLength(3));
    expect(events.last.screenRecording, isFalse);

    await sub.cancel();
  });

  group('a check still in flight when dispose runs', () {
    test('does not carry its state into the next start', () async {
      platform.holding = true;
      watcher.startWatching(interval: tick);
      watcher.dispose();
      platform.holding = false;
      platform.held.single.complete(true);
      await pumpTicks();

      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      watcher.startWatching(interval: tick);
      await pumpTicks();

      expect(events, hasLength(1));
      expect(events.single.hasChanges, isTrue,
          reason: 'the first status after dispose compares with nothing');
      await sub.cancel();
    });

    test('does not emit into the stream opened after it', () async {
      platform.holding = true;
      watcher.startWatching(interval: tick);
      watcher.dispose();
      platform.holding = false;

      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      watcher.startWatching(interval: tick);
      await pumpTicks();
      expect(events, hasLength(1), reason: 'the new start emits its own state');

      platform.held.single.complete(false);
      await pumpTicks();
      expect(events, hasLength(1),
          reason: 'the check from before dispose emits nothing');
      expect(events.single.screenRecording, isTrue);
      await sub.cancel();
    });

    test('does not emit its failure into the stream opened after it', () async {
      platform.holding = true;
      watcher.startWatching(interval: tick);
      watcher.dispose();
      platform.holding = false;

      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      watcher.startWatching(interval: tick);
      await pumpTicks();

      platform.held.single.completeError(StateError('platform failed'));
      await pumpTicks();
      expect(events, hasLength(1));
      expect(events.single.screenRecording, isTrue);
      await sub.cancel();
    });
  });

  group('overlapping checks', () {
    /// Starts watching twice while Screen Recording replies are held, so two
    /// checks are in flight: `held[0]` is the older, `held[1]` the newer.
    Future<List<PermissionStatus>> startTwoHeldChecks() async {
      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      addTearDown(sub.cancel);
      platform.holding = true;
      watcher.startWatching(interval: tick);
      await Future<void>.delayed(Duration.zero);
      watcher.startWatching(interval: tick);
      await Future<void>.delayed(Duration.zero);
      expect(platform.held, hasLength(2));
      return events;
    }

    test('an older reading finishing last is discarded', () async {
      final events = await startTwoHeldChecks();

      platform.held[1].complete(false);
      await Future<void>.delayed(Duration.zero);
      platform.held[0].complete(true);
      platform.holding = false;
      platform.screenRecording = false;
      final callsBefore = platform.permissionCalls;
      await pumpTicks();

      expect(platform.permissionCalls, greaterThan(callsBefore),
          reason: 'polling ticks ran after both replies');
      expect(events, hasLength(1),
          reason: 'neither the older reading nor a repeat of the change');
      expect(events.single.screenRecording, isFalse);
      expect(events.single.hasChanges, isTrue);
    });

    test('an older failure finishing last is discarded', () async {
      final events = await startTwoHeldChecks();

      platform.held[1].complete(true);
      await Future<void>.delayed(Duration.zero);
      platform.held[0].completeError(StateError('platform failed'));
      platform.holding = false;
      await pumpTicks();

      expect(events, hasLength(1));
      expect(events.single.screenRecording, isTrue);
    });

    test('a start still emits its state when a tick finishes before it',
        () async {
      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      addTearDown(sub.cancel);
      watcher.startWatching(interval: tick);
      await pumpTicks();
      watcher.stopWatching();
      expect(events, hasLength(1));

      platform.holding = true;
      watcher.startWatching(interval: tick);
      await Future<void>.delayed(tick * 1.5);
      platform.holding = false;
      expect(platform.held.length, greaterThanOrEqualTo(2),
          reason: 'the start check and a tick check are both in flight');

      platform.held[1].complete(true);
      await Future<void>.delayed(Duration.zero);
      platform.held[0].complete(true);
      await pumpTicks();

      expect(events, hasLength(2),
          reason: 'the second start emits its state although nothing changed');
      expect(events.last.screenRecording, isTrue);
      expect(events.last.hasChanges, isFalse);
    });

    test('a failed start check is the start\'s status', () async {
      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      addTearDown(sub.cancel);
      watcher.startWatching(interval: tick);
      await pumpTicks();
      watcher.stopWatching();

      platform.holding = true;
      watcher.startWatching(interval: tick);
      await Future<void>.delayed(Duration.zero);
      platform.holding = false;
      platform.held.single.completeError(StateError('platform failed'));
      await pumpTicks();

      expect(events.map((e) => e.screenRecording), [true, null, true],
          reason: 'the start emits its failure, then the reading after it '
              'once, as a change');
    });

    test('checks finishing in start order are both applied', () async {
      final events = await startTwoHeldChecks();

      platform.held[0].complete(true);
      await Future<void>.delayed(Duration.zero);
      platform.held[1].complete(false);
      platform.holding = false;
      platform.screenRecording = false;
      await pumpTicks();

      expect(events.map((e) => e.screenRecording), [true, false]);
      expect(events.map((e) => e.hasChanges), [true, true]);
    });
  });

  group('a failed check', () {
    /// Sets [failing] until [count] polling checks have failed.
    Future<void> failChecks([int count = 1]) async {
      platform.failing = true;
      while (platform.failedCalls < count) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      platform.failing = false;
    }

    test('is what the next check compares against', () async {
      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      addTearDown(sub.cancel);
      watcher.startWatching(interval: tick);
      await pumpTicks();

      await failChecks();
      await pumpTicks();

      final readings = events.map((e) => e.screenRecording).toList();
      expect(readings.length, greaterThanOrEqualTo(3));
      expect(readings.first, isTrue);
      expect(readings.sublist(1, readings.length - 1), everyElement(isNull),
          reason: 'the start, then only failures, then the recovery once');
      expect(readings.last, isTrue, reason: 'the recovery is reported');
      expect(events.last.hasChanges, isTrue);
    });

    test('keeps emitting while checks keep failing', () async {
      final events = <PermissionStatus>[];
      final sub = watcher.permissionStream.listen(events.add);
      addTearDown(sub.cancel);
      watcher.startWatching(interval: tick);
      await pumpTicks();

      await failChecks(2);
      await pumpTicks();

      final failures = events.where((e) => e.screenRecording == null);
      expect(failures.length, platform.failedCalls,
          reason: 'every failing check emits');
      expect(failures.length, greaterThanOrEqualTo(2));
      expect(failures.every((e) => e.hasChanges), isTrue);
    });
  });

  test('a start right after dispose keeps polling for a listener that stays',
      () async {
    final oldSub = watcher.permissionStream.listen((_) {});
    watcher.startWatching(interval: tick);
    await pumpTicks();

    watcher.dispose();
    final events = <PermissionStatus>[];
    final sub = watcher.permissionStream.listen(events.add);
    watcher.startWatching(interval: tick, emitOnlyChanges: false);
    await pumpTicks();

    expect(watcher.isWatching, isTrue,
        reason: 'the closed stream cancelling its listener stops nothing');
    final callsBefore = platform.permissionCalls;
    await pumpTicks();
    expect(platform.permissionCalls, greaterThan(callsBefore));
    expect(events.length, greaterThan(1));
    await oldSub.cancel();
    await sub.cancel();
  });

  test('dispose resets the watcher and it can be reused', () async {
    final doneEvents = <String>[];
    final sub = watcher.permissionStream
        .listen((_) {}, onDone: () => doneEvents.add('done'));
    watcher.startWatching(interval: tick);

    watcher.dispose();
    expect(watcher.isWatching, isFalse);
    await Future.delayed(Duration.zero);
    expect(doneEvents, ['done'],
        reason: 'existing listeners receive done on dispose');

    // Reuse after dispose: fresh stream + restart works.
    final events = <PermissionStatus>[];
    final sub2 = watcher.permissionStream.listen(events.add);
    expect(watcher.isWatching, isFalse,
        reason: 'dispose withdraws the watch request, so no auto-resume');
    watcher.startWatching(interval: tick, emitOnlyChanges: false);
    await pumpTicks();
    expect(watcher.isWatching, isTrue);
    expect(events, isNotEmpty);

    await sub.cancel();
    await sub2.cancel();
  });
}
