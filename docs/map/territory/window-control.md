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
    3. switches Space and polls `findWindowElement*` for up to 1.0s, running the run loop in 50ms slices;
    4. closes the window and switches back.
- **Focus.** Sets `kAXMainAttribute = true`, activates the app with `.activateIgnoringOtherApps`, then sends `kAXRaiseAction`. It succeeds if either AX call succeeds. Focus does **no** Space switch, and when no element is found it returns `windowNotFound` (close and scroll say `windowNotAccessible`).
- **Results.** Results return as `WindowOperationResult`. Which codes arrive typed is [failure-code-vocabulary](../invariant/failure-code-vocabulary.md).

## Code
- `macos/Classes/WindowHandler.swift — WindowHandler.closeWindow`, `closeWindowWithAccessibilityAPI`, `closeWindowViaSpaceSwitch`, `findCloseButton`, `findCloseButtonInChildren`, `searchForCloseButton`, `clickCloseButton`, `focusWindow`, `findWindowElement`, `findWindowElementFlexible`
- `macos/Classes/WindowHandler.swift — spaceForWindow`, `displayForWindow`, `displayUUIDString`, `activateSpace`, and the `_cgs*` `@_silgen_name` declarations at the top of the file
- `macos/Classes/MacosWindowToolkitPlugin.swift — closeWindow`, `focusWindow`
- `lib/src/method_channel/window_operations_channel.dart — WindowOperationsChannel.closeWindow`, `focusWindow`
- `lib/src/models/window_operation_result.dart — WindowOperationResult`, `OperationFailure`, `WindowOperationFailureReason`

## Reference behaviour
**None.** The private CGS calls have no published reference. `.activateIgnoringOtherApps` is believed deprecated since macOS 14, which needs confirming against Apple's docs (a summarized source).

## Cross-cutting invariants
- [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md)
- [window-dictionary-shape](../invariant/window-dictionary-shape.md)
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [scroll-inspection](scroll-inspection.md): it shares `findWindowElementFlexible`/`findWindowElement` and the permission precheck. Changing how an element is found changes which window's scroll bars are read.
- [permissions](permissions.md): the precheck is `PermissionHandler.hasAccessibilityPermission`. If that check changes meaning, close and focus fail or proceed differently.
- [window-listing](window-listing.md): `processId` and `name` come from `getWindowById`'s dictionary.
- [shipping](shipping.md): `WindowOperationFailureReason` is a public enum, so adding a value breaks consumers' exhaustive `switch`es and needs a release note and version decision.
- [user-docs](user-docs.md): CHANGELOG 1.8.3 and the API docs describe close results that the code does not produce (see the holes).

## Known holes / open
- `closeWindow` on an inaccessible window reaches Dart as `unknown`, not `windowNotAccessible`. The CHANGELOG promises otherwise, and the maintainer confirmed it is a gap (maintainer, 2026-10-23). Owned by [failure-code-vocabulary](../invariant/failure-code-vocabulary.md).
- The Space-switch path blocks the calling (platform) thread for up to 1s while it polls.
- Private CGS symbols: the `dlsym` check guards a missing symbol, not a changed signature.
- If close fails after the Space switch, the switch back still runs, but a crash or early return in between leaves the user on the other Space.
- The "close" description match is English-only. It is a fallback, and its reach on localized systems is unknown.
