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
- **Errors.** A failed check emits a status with both values `null` and `hasChanges: true`, on every failing check (consecutive failures are not deduplicated; maintainer, 2026-11-04). An applied failure is stored as the previous state like a success, so the first success after it reads as a change and is emitted under `emitOnlyChanges` (#45). Storing it was chosen over clearing the previous state, since `null` already means "no check yet" (technical call).
- **Platform access.** It imports the platform interface and `PermissionStatus` directly (not the library entry point, which exports it back), and calls `MacosWindowToolkitPlatform.instance`, which is what lets the unit tests swap in a fake.
- **Change detection.** The last applied check, a failure included, is kept as a `PermissionStatus?` and compared field by field.
- **Check ordering.** Each check takes the next start number. When it finishes, it is applied only if no later-started check has been applied yet; otherwise it neither emits (state or failure) nor writes `_previousState`. So when checks overlap (an interval shorter than one round trip, or `startWatching` again or after `stopWatching` while a check is in flight), an older reading finishing last cannot overwrite a newer one, repeat a change, or emit out of order (#30, maintainer's choice of "keep only the newest result" over skipping ticks, 2026-11-04). Ticks are never skipped, so platform calls are unchanged, and a check that finishes before any newer one is applied still counts, so a platform slower than the interval still produces results.
- **A start's status is never lost to ordering.** `startWatching`'s check is forced to emit. If a later-started tick check is applied first, the forced check is then discarded, so the force is held as `_pendingForcedCheck` and taken by the first applied check numbered at or above it; that check emits even when nothing changed. A failing start check emits its failure, and the success after it is a change anyway (#45), so the failure path does not take the force. Without this, a restart after `stopWatching` under `emitOnlyChanges` emitted nothing when a tick finished first (found in review of #30, 2026-11-04).
- **Where the reordering can come from.** The bundled Swift handlers for both checks reply synchronously on the main thread (`MacosWindowToolkitPlugin.swift — hasScreenRecordingPermission`, `hasAccessibilityPermission`), and each Dart check awaits Screen Recording then Accessibility. If channel replies reach Dart in the order they were sent, an older check always finishes first with the bundled plugin, and the reordering needs a substituted platform or an asynchronous handler. Whether the engine guarantees that order was not read (2026-11-04); reordering has only been seen with the test fake.
- **Dispose supersedes every started check.** `dispose` marks all checks started so far as superseded, so one in flight across it cannot make the next start's first status read `hasChanges: false`, nor reach a stream opened after `dispose` (#21). One start-number rule holds both this and the ordering above; it replaced #21's separate generation counter (#30). `stopWatching` supersedes nothing: a check in flight across a stop still emits into the kept stream, unless a later check was applied first.
- **A closed controller stops nothing.** The controller's `onCancel` acts only while that controller is the current one. A broadcast controller delivers `close`'s done event later, and its listener's cancel then called `onCancel`: a listener kept across `dispose` followed at once by `startWatching` stopped the new timer, and polling stayed off (reproduced on main, 2026-10-29; fixed with #21).
- **Measured cost.** No memory growth from polling with no listeners at 200ms over 30s (issue #1 comment, 2026-06-12).

## Code
- `lib/src/permission_watcher.dart — PermissionWatcher.startWatching`, `stopWatching`, `dispose`, `permissionStream`, `isWatching`, `_checkPermissions`, `_handleFirstListener`, `_handleLastListenerCancelled`
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit.startPermissionWatching`, `stopPermissionWatching`, `permissionStream`, `isPermissionWatching`
- `lib/src/models/permission_status.dart — PermissionStatus`
- `test/permission_watcher_test.dart`

## Reference behaviour
- `test/permission_watcher_test.dart — a check still in flight when dispose runs` holds a platform reply across `dispose` with a fake and pins the three outcomes: the next start's first status has `hasChanges: true`, and neither the held state nor a held failure reaches the new stream. Each was seen red without the generation check (removing the increment, the success-path check, the failure-path check, or flipping the comparison; 2026-10-29). Under the start-number rule, removing the supersede in `dispose` or loosening `<=` to `<` reddens the first; removing the failure-path check reddens the third (2026-11-04).
- `test/permission_watcher_test.dart — overlapping checks` holds two checks and completes them out of and in start order: an older reading or failure finishing last emits nothing, and two checks finishing in start order are both applied. The first two went red without the fix (3 and 2 events); the third went red when the rule was mutated to "only the latest-started check counts" (2026-11-04).
- `overlapping checks — a start still emits its state when a tick finishes before it` went red without `_pendingForcedCheck` (1 event, 2 expected). `a failed start check is the start's status` pinned `[true, null]` until #45, which made the recovery after the failure a third status. Evaluating `forceEmit` before taking the pending force (so it is never cleared) reddens eight tests (2026-11-04).
- `a start right after dispose keeps polling for a listener that stays` pins the closed-controller case; it went red without the identity check in `onCancel` (2026-10-29).
- `test/permission_watcher_test.dart — a failed check` pins the failure rule: `is what the next check compares against` (success → failure → the same success gives the recovery once, with `hasChanges: true`) went red without storing the failure, and `keeps emitting while checks keep failing` counts one status per thrown call and went red when consecutive failures were deduplicated under `emitOnlyChanges` (2026-11-04).

## Cross-cutting invariants
**None.**

## Blast radius
- [permissions](permissions.md): this area polls those two checks. Any change to their cost, prompting or caching changes what the stream reports.
- [channel-bridge](channel-bridge.md): it depends on the `MacosWindowToolkitPlatform.instance` singleton directly.
- [memory-measurement](memory-measurement.md): the harness's watcher scenario and the #1 baseline measure this lifecycle.
- [example-app](example-app.md): `example/lib/test_permission_monitoring.dart` and the permission pages drive it.

## Known holes / open
- `isWatching` can go `false` with no `stopWatching` call (documented). A caller that reads it as "requested" is misled.
