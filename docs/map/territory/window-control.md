# Window control

## What it is
Closes or focuses a window by `windowId` through the Accessibility API. Closing also covers a window that sits on another Space, by switching to that Space with private CoreGraphics Services (CGS) calls, closing it, and switching back.

## Governing decisions
**None.** The Space-switch behaviour came in with commit fef6b4d and is described only in CHANGELOG 1.8.3.

## Design model
From reading the source:
- **Precondition.** Both calls check Accessibility first, through `AXWindowLookup.target` and the `PermissionChecking` it was given, and fail with `accessibilityPermissionDenied`.
- **Finding the window.** `AXWindowLookup.target` reads the window's `processId` and `name` from the CG window list (`WindowQuery.windowInfo`, without resolving AX roles), then `AXWindowLookup.element` finds its AX element with `flexibleMatch`, falling back to `exactMatch`. That match is by title: [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md).
- **Close.**
  - Finds the close button through `findCloseButton`: `kAXCloseButtonAttribute` when it reads as an AX element, else a child search to depth 3 for an `AXCloseButton` subrole or a description containing "close". It then presses it (`kAXPressAction`).
  - When no AX element is found, it hands the close to `SpaceSwitcher.close`, which reaches CGS through `SpaceControl` (`CGSSpaces` in production):
    1. checks the four CGS symbols with `dlsym(UnsafeMutableRawPointer(bitPattern: -2), …)` (the `RTLD_DEFAULT` replacement, commit c59ae7b);
    2. reads the window's Space (`CGSCopySpacesForWindows`, mask 7) and the display from the window bounds;
    3. switches Space and polls `AXWindowLookup.element` every 50ms for up to 1.0s with `pollOnMain`, which schedules each retry on the main queue: `handle` has already returned, so nothing blocks or spins the main thread, and nothing runs nested inside the close (#13);
    4. closes the window, switches back on every exit after the switch (closed, close action failed, close button missing, timeout), then completes.
  - Space-switch closes run one at a time through the `SerialGate` inside `SpaceSwitcher`: the next one starts after the previous has switched back (#13). A close whose window is reachable on the current Space does not wait for the gate.
  - `closeWindow` takes a completion: it completes at once on the current-Space path and after the wait otherwise; the dispatcher replies through `onMain`.
  - **Pressed is not closed.** Without `waitUntilClosed` the result is `success` as soon as the close button is pressed. With it, `closeWindow` polls the pressed window's `AXUIElement` with `pollOnMain` and succeeds once `AXWindowActions.isDestroyed` reads it as `.invalidUIElement` or finds its process gone, or fails with `windowStillOpen` when the duration runs out (#25). The element gets a 0.1 s AX messaging timeout first, so an app that hangs after the press cannot hold the main thread for the default AX timeout on each poll. A hung app reads as still open. On the Space-switch path it releases the `SpaceSwitcher` gate before it waits, so the gate holds only the switch, and a long wait does not hold up the next Space-switch close. The wait runs after the original Space is restored, and the other Space is not kept on screen meanwhile.
  - **Why the AX element, measured 2026-10-25 (macOS 26.6.2).** These measurements came from a temporary plugin probe, since removed, and the CoreGraphics window list:
    - A saved TextEdit document's window read `.invalidUIElement` 11–35 ms after the press. This held on the current Space, and on another Space after switching straight back and querying from the original one.
    - An open window on another Space stayed valid for more than 3 s when queried from the original Space, so "on another Space" does not read as closed.
    - A document with unsaved changes (a save sheet showing) stayed valid for more than 4 s.
    - The CoreGraphics window list kept a closed TextEdit window, off screen and still assigned to its Space, for more than 45 s. So the window list cannot tell closed from open.
    - When the window's process exits (a Tk window whose close quits the app), the element does not read as `.invalidUIElement`. So `isDestroyed` also checks the element's pid with `kill(pid, 0)` and `ESRCH` (`close_wait_test.dart`, mutation run on 2026-10-25).
- **Focus.** Sets `kAXMainAttribute = true`, activates the app with `.activateIgnoringOtherApps`, then sends `kAXRaiseAction`. It succeeds if either AX call succeeds. Focus does **no** Space switch, and when no element is found it returns `windowNotFound` (close and scroll say `windowNotAccessible`).
- **Results.** Results return as `WindowOperationResult`. An inaccessible window is `windowNotAccessible` (#7). Which codes arrive typed is [failure-code-vocabulary](../invariant/failure-code-vocabulary.md).

## Code
- `macos/Classes/AXWindowActions.swift — AXWindowActions.closeWindow`, `isDestroyed`, `pressClose`, `findCloseButton`, `searchForCloseButton`, `focusWindow`
- `macos/Classes/AXWindowLookup.swift — AXWindowLookup.target`, `element(for:missing:)` (focus, scroll), `element(processId:windowName:)` (close and its Space-switch retry), `flexibleMatch`, `exactMatch`
- `macos/Classes/AXAttributes.swift — AXUIElement.attribute`, `elementAttribute`, `windows(ofProcess:)`
- `macos/Classes/SpaceSwitcher.swift — SpaceSwitcher.close`, `SpaceControl`, `CGSSpaces`, and the `_cgs*` `@_silgen_name` declarations at the top of the file
- `macos/Classes/MainQueue.swift — pollOnMain`, `SerialGate`
- `macos/Classes/MacosWindowToolkitPlugin.swift — closeWindow`, `focusWindow`
- `lib/src/method_channel/window_operations_channel.dart — WindowOperationsChannel.closeWindow`, `focusWindow`
- `lib/src/models/window_operation_result.dart — WindowOperationResult`, `OperationFailure`, `WindowOperationFailureReason`

## Reference behaviour
- `example/integration_test/close_wait_test.dart` opens its own Tk windows with the system `/usr/bin/python3` and pins `waitUntilClosed` (#25):
  - a window that closes 1.5 s after the press, with its app still running: success no earlier than 1.5 s (the `.invalidUIElement` path);
  - an app that exits 1.5 s after the press: success no earlier than 1.5 s (the exited-process path);
  - a window that ignores the press: `windowStillOpen` after the duration;
  - no `waitUntilClosed`: success before the window closes.
  Each path was seen red under a mutation of its own branch. A fixture app that stops running its event loop reads as hung, not closed. It runs in the `flutter test -d macos` host because the XCTest host is not trusted for Accessibility (`AXIsProcessTrusted()` false, 2026-10-25).
- `example/macos/RunnerTests/RunnerTests.swift — SpaceSwitchWaitTests` pins `pollOnMain` (returns to its caller before retrying, gives up at the deadline) and `SerialGate` ordering (#13).
- `RunnerTests.swift — SpaceSwitchCloseTests` drives `SpaceSwitcher` with a fake `SpaceControl` (#12): it switches back on every exit after the switch (pressed, press failed, never reachable), does not switch for a window on the current Space, fails without switching when the CGS calls or the window's Space are missing, and holds the next close until the first has switched back, or until before its completion when it releases first. Each of the four was seen red under a mutation (no `done`, no switch-back, never releasing first, no gate; 2026-10-29). Whether `AXWindowActions.closeWindow` asks to release first exactly when it waits (`waitUntilClosed`) is not tested, and the real CGS calls are checked by hand in the example app's window detail sheet.
- The private CGS calls have no published reference. `.activateIgnoringOtherApps` is believed deprecated since macOS 14, which needs confirming against Apple's docs (a summarized source).

## Cross-cutting invariants
- [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md)
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [scroll-inspection](scroll-inspection.md): it shares `AXWindowLookup` and the permission precheck. Changing how an element is found changes which window's scroll bars are read.
- [permissions](permissions.md): the precheck is `PermissionHandler.hasAccessibilityPermission`. If that check changes meaning, close and focus fail or proceed differently.
- [window-listing](window-listing.md): `processId` and `name` come from the `WindowInfo` that `WindowQuery.windowInfo` returns.
- [shipping](shipping.md): `WindowOperationFailureReason` is a public enum, so adding a value breaks consumers' exhaustive `switch`es and needs a release note and version decision.
- [user-docs](user-docs.md): `documentations/api/error_handling.md` and the README's close example list close failure reasons by hand, so a new reason needs adding there.

## Known holes / open
- `waitUntilClosed` on the Space-switch path (wait after the restore, gate released first) is covered by the measurement above, not by an automated test: the tests cannot place a window on another Space.
- Private CGS symbols: the `dlsym` check guards a missing symbol, not a changed signature.
- After the Space switch every exit switches back, but a crash during the wait leaves the user on the other Space.
- Whether the old spinning wait actually stopped frames was never measured: spinning the run loop in default mode still services main-queue work. What it did for certain was run other channel calls nested inside the close.
- The "close" description match is English-only. It is a fallback, and its reach on localized systems is unknown.
