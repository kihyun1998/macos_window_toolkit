# Window control

## What it is
Closes or focuses a window by `windowId` through the Accessibility API. Closing also covers a window that sits on another Space, by switching to that Space with private CoreGraphics Services (CGS) calls, closing it, and switching back.

## Governing decisions
**None.** The Space-switch behaviour came in with commit fef6b4d and is described only in CHANGELOG 1.8.3.

## Design model
From reading the source:
- **Precondition.** Both calls check `AXIsProcessTrusted` first (a new `PermissionHandler()` each time) and fail with `accessibilityPermissionDenied`.
- **Finding the window.** Both look the window up with `getWindowById`, then find its AX element with `findWindowElementFlexible`, falling back to `findWindowElement`. That match is by title: [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md).
- **Close.**
  - Finds the close button through `findCloseButton`: `kAXCloseButtonAttribute`, else a child search to depth 3 for an `AXCloseButton` subrole or a description containing "close". It then presses it (`kAXPressAction`).
  - When no AX element is found (`windowNotAccessible`), it falls back to `closeWindowViaSpaceSwitch`:
    1. checks the four CGS symbols with `dlsym(UnsafeMutableRawPointer(bitPattern: -2), …)` (the `RTLD_DEFAULT` replacement, commit c59ae7b);
    2. reads the window's Space (`CGSCopySpacesForWindows`, mask 7) and the display from the window bounds;
    3. switches Space and polls `findWindowElement*` every 50ms for up to 1.0s with `WindowHandler.pollOnMain`, which schedules each retry on the main queue: `handle` has already returned, so nothing blocks or spins the main thread, and nothing runs nested inside the close (#13);
    4. closes the window, switches back on every exit after the switch (closed, close action failed, close button missing, timeout), then completes.
  - Space-switch closes run one at a time through `WindowHandler.spaceSwitchGate` (a `SerialGate`): the next one starts after the previous has switched back (#13). A close whose window is reachable on the current Space does not wait for the gate.
  - `closeWindow` takes a completion: it completes at once on the current-Space path and after the wait otherwise; the dispatcher replies through `onMain`. The Dart API is unchanged.
- **Focus.** Sets `kAXMainAttribute = true`, activates the app with `.activateIgnoringOtherApps`, then sends `kAXRaiseAction`. It succeeds if either AX call succeeds. Focus does **no** Space switch, and when no element is found it returns `windowNotFound` (close and scroll say `windowNotAccessible`).
- **Results.** Results return as `WindowOperationResult`. An inaccessible window is `windowNotAccessible` (#7). Which codes arrive typed is [failure-code-vocabulary](../invariant/failure-code-vocabulary.md).

## Code
- `macos/Classes/WindowHandler.swift — WindowHandler.closeWindow`, `closeWindowOnCurrentSpace`, `closeWindowWithAccessibilityAPI`, `closeWindowViaSpaceSwitch`, `pollOnMain`, `SerialGate`, `findCloseButton`, `findCloseButtonInChildren`, `searchForCloseButton`, `clickCloseButton`, `focusWindow`, `findWindowElement`, `findWindowElementFlexible`
- `macos/Classes/WindowHandler.swift — spaceForWindow`, `displayForWindow`, `displayUUIDString`, `activateSpace`, and the `_cgs*` `@_silgen_name` declarations at the top of the file
- `macos/Classes/MacosWindowToolkitPlugin.swift — closeWindow`, `focusWindow`
- `lib/src/method_channel/window_operations_channel.dart — WindowOperationsChannel.closeWindow`, `focusWindow`
- `lib/src/models/window_operation_result.dart — WindowOperationResult`, `OperationFailure`, `WindowOperationFailureReason`

## Reference behaviour
- `example/macos/RunnerTests/RunnerTests.swift — SpaceSwitchWaitTests` pins `pollOnMain` (returns to its caller before retrying, gives up at the deadline) and `SerialGate` ordering (#13). The Space-switch close itself needs real Spaces and is checked by hand in the example app's window detail sheet.
- The private CGS calls have no published reference. `.activateIgnoringOtherApps` is believed deprecated since macOS 14, which needs confirming against Apple's docs (a summarized source).

## Cross-cutting invariants
- [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md)
- [window-dictionary-shape](../invariant/window-dictionary-shape.md)
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [scroll-inspection](scroll-inspection.md): it shares `findWindowElementFlexible`/`findWindowElement` and the permission precheck. Changing how an element is found changes which window's scroll bars are read.
- [permissions](permissions.md): the precheck is `PermissionHandler.hasAccessibilityPermission`. If that check changes meaning, close and focus fail or proceed differently.
- [window-listing](window-listing.md): `processId` and `name` come from `getWindowById`'s dictionary.
- [shipping](shipping.md): `WindowOperationFailureReason` is a public enum, so adding a value breaks consumers' exhaustive `switch`es and needs a release note and version decision.
- [user-docs](user-docs.md): `documentations/api/error_handling.md` and the README's close example list close failure reasons by hand, so a new reason needs adding there.

## Known holes / open
- Private CGS symbols: the `dlsym` check guards a missing symbol, not a changed signature.
- After the Space switch every exit switches back, but a crash during the wait leaves the user on the other Space.
- Whether the old spinning wait actually stopped frames was never measured: spinning the run loop in default mode still services main-queue work. What it did for certain was run other channel calls nested inside the close.
- The "close" description match is English-only. It is a fallback, and its reach on localized systems is unknown.
