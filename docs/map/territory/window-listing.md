# Window listing

## What it is
Enumerates on-screen and off-screen windows through CoreGraphics and filters them: all windows, by title, by owner, by ID, by PID, and an advanced filter with AND conditions. Each entry is enriched with the Accessibility `role`/`subrole`. `isWindowAlive` is built on the same listing.

## Governing decisions
**None.** Issue #3 (closed, commit 9f24f0a) set the per-PID role cache. That is an implementation change, not a recorded decision.

## Design model
From reading the source:
- **Source of truth.** The source of truth is `CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)`, re-run on every call, including `getWindowById`. The options include windows on other Spaces and minimized windows. `isOnScreen` is false for both.
- **Permissions shape the data.** `role`/`subrole` are added only when Accessibility is granted. When it is not, the AX calls fail and the keys are absent. The facade's doc says window titles need Screen Recording (doc claim on `MacosWindowToolkit.hasScreenRecordingPermission`, not verified here).
- **Role lookup is cached per call, per PID.** `AXRoleResolver` fetches an app's AX window list once per listing call (#3). CHANGELOG 1.9.0 reports average `getAllWindows()` latency 27.4ms → 12.9ms with 91 windows (commit 9f24f0a, 2026-06-12).
- **Matching.**
  - `getWindowsByName`/`getWindowsByOwnerName` use case-sensitive `String.contains`.
  - `getWindowsAdvanced` defaults to `exactMatch false`, `caseSensitive true`, `wildcard false`. Wildcard (`*`, `?`) takes priority over exact matching (`matchString`, `matchWildcard`, `findPartMatch`, `findPartMatchWithQuestionMark`), with no escape for a literal `*` or `?`.
  - Bounds filters compare `Double` for exact equality.
- **`isWindowAlive`** is `getWindowById` plus an optional exact `expectedName` check, and returns `false` on any failure.
- **Input bounds.** A filter pattern is caller-supplied and unbounded. The `?` matcher is O(text × pattern) per window.

## Code
- `macos/Classes/WindowHandler.swift — AXRoleResolver.role`, `AXRoleResolver.fetchEntries`
- `macos/Classes/WindowHandler.swift — WindowHandler.getAllWindows`, `getFilteredWindows`, `getWindowsByName`, `getWindowsByOwnerName`, `getWindowById`, `getWindowsByProcessId`, `getWindowsAdvanced`, `isWindowAlive`, `matchString`, `matchWildcard`, `findPartMatch`, `findPartMatchWithQuestionMark`
- `macos/Classes/MacosWindowToolkitPlugin.swift — getAllWindows`, `getWindowsByName`, `getWindowsByOwnerName`, `getWindowById`, `getWindowsByProcessId`, `getWindowsAdvanced`, `isWindowAlive`
- `lib/src/method_channel/window_operations_channel.dart — WindowOperationsChannel.getAllWindows` … `isWindowAlive`
- `lib/src/models/macos_window_info.dart — MacosWindowInfo.fromMap`

## Reference behaviour
- `example/integration_test/ax_parity_probe_test.dart` measured latency and a role/subrole histogram before and after #3. Per CHANGELOG 1.9.0 the returned `role`/`subrole` values were unchanged (commit 9f24f0a, 2026-06-12).

## Cross-cutting invariants
- [window-dictionary-shape](../invariant/window-dictionary-shape.md)
- [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md)

## Blast radius
- [window-control](window-control.md): close and focus get `processId` and `name` from `getWindowById`. A change to how a window is found or named changes which AX window they act on.
- [scroll-inspection](scroll-inspection.md): it relies on the same `getWindowById` lookup and the same name.
- [window-capture](window-capture.md): callers pass `windowId`s from this listing to `captureWindow`, which looks them up in `SCShareableContent` instead. A window listed here can be missing there.
- [memory-measurement](memory-measurement.md): the polling soak and the AX probe measure this code. Its baseline numbers describe the current implementation.
- [example-app](example-app.md): the window list and the advanced filter section render every field of `MacosWindowInfo`.

## Known holes / open
- `getWindowById` lists every window and resolves AX roles for the target app only to return one entry. Close, focus, scroll and `isWindowAlive` all pay that cost.
- Titles empty without Screen Recording is stated in docs, not checked here.
