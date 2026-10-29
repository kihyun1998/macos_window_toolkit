# AX window identity by title

## The fact
The code matches a CoreGraphics / ScreenCaptureKit window to its Accessibility element by **window title**: an exact match, a substring match, or "any window" when the title is empty. Nothing in the repo maps a `CGWindowID` to an `AXUIElement` directly. Each site implements its own matching rule.

## Why it is cross-cutting
Four sites, none calling another, read in `macos/macos_window_toolkit/Sources/macos_window_toolkit/WindowQuery.swift`, `AXWindowLookup.swift` and `CaptureHandler.swift`:
- `AXRoleResolver.role`: exact title, or the first *titled* AX window when the CG name is empty (untitled AX windows are never cached).
- `AXWindowLookup.exactMatch`: exact title, or the first titled AX window when the name is empty.
- `AXWindowLookup.flexibleMatch`: exact, then `contains`, then the first window of all when the name is empty. `AXWindowLookup.element` tries it first, for close, focus, scroll and the Space-switch retry.
- `CaptureHandler.isMinimized`, the capture's minimized check: any minimized AX window whose title equals the SC title, or any minimized window at all when the SC title is empty.

They agree on the assumption (title identifies the window) but not on the rule, so making one stricter leaves the others matching differently.

## Territories it holds in
- [window-listing](../territory/window-listing.md): `AXRoleResolver.role` decides which window's `role`/`subrole` is reported.
- [window-control](../territory/window-control.md): `AXWindowLookup.element` decides which window is closed or focused.
- [scroll-inspection](../territory/scroll-inspection.md): the same lookup decides which window's scroll bars are read.
- [window-capture](../territory/window-capture.md): the minimized check decides whether a capture is refused.

## What a violation looks like
It reproduces when one app has two windows with the same title, an empty title, or one title containing the other:
- the `role`/`subrole` of the wrong window is reported;
- `closeWindow`/`focusWindow` acts on a sibling window;
- `captureWindow` returns `windowMinimized` for a visible window because an untitled sibling is minimized.

## Discovery history
- Found reading the four sites on 2026-10-23. Whether a direct `CGWindowID` → AX lookup is available was not checked against Apple's documentation (a summarized source, see `docs/agents/thegraph.md`).

## Where it will recur
If a function turns a `windowId` into an `AXUIElement` (or the reverse), it is subject to this. Grep `kAXTitleAttribute` and `kAXWindowsAttribute` in `macos/macos_window_toolkit/Sources/macos_window_toolkit/`.
