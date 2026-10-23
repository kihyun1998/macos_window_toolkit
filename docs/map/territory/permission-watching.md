# Permission watching

## What it is
A Dart-only singleton that polls both permissions on a timer and emits a `PermissionStatus` stream. It is exposed through `PermissionWatcher.instance` and the facade's `startPermissionWatching`, `stopPermissionWatching`, `permissionStream` and `isPermissionWatching`.

## Governing decisions
**None.** Issue #2 (closed, commit 49e8fff) set the listener-tied lifecycle. CHANGELOG 1.9.0 describes it.

## Design model
From the source and its doc comment (`lib/src/permission_watcher.dart`):
- **Polling.** `startWatching` cancels any timer, stores `interval` (default 2s) and `emitOnlyChanges`, and sets `_watchRequested`. It checks once with `forceEmit` and then starts `Timer.periodic`. Polling starts even before any listener subscribes.
- **Broadcast controller tied to listeners.**
  - Polling stops when the last listener cancels (`onCancel`) and resumes for the next listener (`onListen`) while `_watchRequested` holds (#2).
  - `stopWatching` withdraws the request and keeps the controller.
  - `dispose` closes the controller and clears state. The watcher can be used again afterwards.
- **Errors.** A failed check emits a status with both values `null` and `hasChanges: true`.
- **Platform access.** It calls `MacosWindowToolkitPlatform.instance` directly, which is what lets the unit tests swap in a fake.
- **Measured cost.** No memory growth from polling with no listeners at 200ms over 30s (issue #1 comment, 2026-06-12).

## Code
- `lib/src/permission_watcher.dart — PermissionWatcher.startWatching`, `stopWatching`, `dispose`, `permissionStream`, `isWatching`, `_checkPermissions`, `_handleFirstListener`, `_handleLastListenerCancelled`
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit.startPermissionWatching`, `stopPermissionWatching`, `permissionStream`, `isPermissionWatching`
- `lib/src/models/permission_status.dart — PermissionStatus`
- `test/permission_watcher_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [permissions](permissions.md): this area polls those two checks. Any change to their cost, prompting or caching changes what the stream reports.
- [channel-bridge](channel-bridge.md): it depends on the `MacosWindowToolkitPlatform.instance` singleton directly.
- [memory-measurement](memory-measurement.md): the harness's watcher scenario and the #1 baseline measure this lifecycle.
- [example-app](example-app.md): `example/lib/test_permission_monitoring.dart` and the permission pages drive it.

## Known holes / open
- `_checkPermissions` is async with no in-flight guard. If an interval is shorter than one round-trip, checks overlap.
- `isWatching` can go `false` with no `stopWatching` call (documented). A caller that reads it as "requested" is misled.
