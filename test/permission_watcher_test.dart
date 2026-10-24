import 'package:flutter_test/flutter_test.dart';
import 'package:macos_window_toolkit/macos_window_toolkit.dart';

/// Fake platform that counts permission checks. Any other platform method
/// throws via [noSuchMethod].
class _FakePlatform extends MacosWindowToolkitPlatform {
  int permissionCalls = 0;
  bool screenRecording = true;
  bool accessibility = true;

  @override
  Future<bool> hasScreenRecordingPermission() async {
    permissionCalls++;
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
