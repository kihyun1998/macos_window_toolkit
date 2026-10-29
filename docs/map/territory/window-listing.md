# Window listing

## What it is
Enumerates on-screen and off-screen windows through CoreGraphics and filters them: all windows, by title, by owner, by ID, by PID, and an advanced filter with AND conditions. Each entry is enriched with the Accessibility `role`/`subrole`. `isWindowAlive` is built on the same listing.

## Governing decisions
**None.** Issue #3 (closed, commit 9f24f0a) set the per-PID role cache. That is an implementation change, not a recorded decision.

## Design model
From reading the source:
- **Source of truth.** The source of truth is `CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)`, re-run on every call, including `getWindowById`. The options include windows on other Spaces and minimized windows. `isOnScreen` is false for both.
- **One window value, one serializer.** `WindowInfo` reads a `CGWindowListCopyWindowInfo` entry once. A field the entry lacks stays nil there, so a filter can tell it from a default: `getWindowsAdvanced` excludes a window without a `layer` even when asked for layer 0, and one without bounds whenever a bounds condition is given. `WindowInfo.dictionary` is the only place the reply map is built, filling `x`/`y`/`width`/`height`/`layer`/`isOnScreen` with their defaults and leaving the other optional keys out. Every listing call, `getAllWindows` included (a filter on `excludeEmptyNames`), goes through `WindowQuery.windows(where:)` (#12).
- **The Dart model names the keys again.** `MacosWindowInfo.fromMap` reads the same key strings and defaults a missing one silently. A field added or renamed on one side only arrives as its Dart default. A new `kCGWindow` field is three edits: `WindowInfo.init`, `WindowInfo.dictionary`, `fromMap` (folded from the former window-dictionary-shape invariant, whose two duplicated Swift builders #12 removed).
- **Permissions shape the data.** `role`/`subrole` are added only when Accessibility is granted. When it is not, the AX calls fail and the keys are absent. The facade's doc says window titles need Screen Recording (doc claim on `MacosWindowToolkit.hasScreenRecordingPermission`, not verified here).
- **Role lookup is cached per call, per PID.** `AXRoleResolver` fetches an app's AX window list once per listing call (#3). CHANGELOG 1.9.0 reports average `getAllWindows()` latency 27.4ms → 12.9ms with 91 windows (commit 9f24f0a, 2026-06-12).
- **Matching.**
  - `getWindowsByName`/`getWindowsByOwnerName` use case-sensitive `String.contains`.
  - `getWindowsAdvanced` defaults to `exactMatch false`, `caseSensitive true`, `wildcard false`. Wildcard (`*`, `?`) takes priority over exact matching (`PatternMatcher`), with no escape for a literal `*` or `?`.
  - Bounds filters compare `Double` for exact equality.
- **`isWindowAlive`** is `getWindowById` plus an optional exact `expectedName` check, and returns `false` on any failure.
- **Input bounds.** A filter pattern is caller-supplied and unbounded. The `?` matcher is O(text × pattern) per window.

## Code
- `macos/Classes/WindowInfo.swift — WindowInfo`, `WindowInfo.dictionary`
- `macos/Classes/WindowQuery.swift — AXRoleResolver.role`, `AXRoleResolver.fetchEntries`
- `macos/Classes/WindowQuery.swift — WindowQuery.windowInfos`, `windowInfo`, `windows(where:)`, `getAllWindows`, `getWindowsByName`, `getWindowsByOwnerName`, `getWindowById`, `getWindowsByProcessId`, `getWindowsAdvanced`, `isWindowAlive`
- `macos/Classes/PatternMatcher.swift — PatternMatcher.matches`, `matchWildcard`, `findPartMatch`, `findPartMatchWithQuestionMark`
- `macos/Classes/MacosWindowToolkitPlugin.swift — getAllWindows`, `getWindowsByName`, `getWindowsByOwnerName`, `getWindowById`, `getWindowsByProcessId`, `getWindowsAdvanced`, `isWindowAlive`
- `lib/src/method_channel/window_operations_channel.dart — WindowOperationsChannel.getAllWindows` … `isWindowAlive`
- `lib/src/models/macos_window_info.dart — MacosWindowInfo.fromMap`

## Reference behaviour
- `example/integration_test/ax_parity_probe_test.dart` measured latency and a role/subrole histogram before and after #3. Per CHANGELOG 1.9.0 the returned `role`/`subrole` values were unchanged (commit 9f24f0a, 2026-06-12).
- `example/integration_test/native_parity_test.dart` records the raw reply of every listing call, filter variant, the AX lookups' error paths, scroll info and the capture and process error paths, and compares two builds (#12). Its own Tk and AppKit windows pin every field and must be listed in both runs or in neither; other windows are compared, where both runs list them, on the fields that stay put while the desktop is left alone (`role`/`subrole` only when titled). It found no difference between 8763238 and the split (2026-10-29), and each of five mutations (a dropped key, a flipped case default, a dropped scroll bar, a filter dropping one fixture window, focus failing with scroll's reason) reddened it. Focus and scroll are called on a window that has no AX element, where both fail before acting; close and focus are never called on a window that exists.
- `ax_parity_probe_test.dart` after the split (2026-10-29, ~95 windows, alternating runs): average `getAllWindows()` latency 26.9 and 20.0 ms at 8763238, 26.6 and 25.4 ms after. The spread between two runs of one build is as large as the gap, so no change is measured either way.

## Cross-cutting invariants
- [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md)

## Blast radius
- [window-control](window-control.md): close and focus get `processId` and `name` from `getWindowById`. A change to how a window is found or named changes which AX window they act on.
- [scroll-inspection](scroll-inspection.md): it relies on the same `getWindowById` lookup and the same name.
- [window-capture](window-capture.md): callers pass `windowId`s from this listing to `captureWindow`, which looks them up in `SCShareableContent` instead. A window listed here can be missing there.
- [memory-measurement](memory-measurement.md): the polling soak and the AX probe measure this code. Its baseline numbers describe the current implementation.
- [example-app](example-app.md): the window list and the advanced filter section render every field of `MacosWindowInfo`.

## Known holes / open
- `getWindowById` lists every window and resolves AX roles for the target app only to return one entry. Close, focus, scroll and `isWindowAlive` read `WindowQuery.windowInfo` instead, which skips the role lookup but still copies the whole window list.
- Titles empty without Screen Recording is stated in docs, not checked here.
