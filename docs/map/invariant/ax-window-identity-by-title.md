# AX window identity by title

## The fact
The code matches a CoreGraphics / ScreenCaptureKit window to its Accessibility element by **window title**: an exact match, a substring match, or "any window" when the title is empty. Nothing in the repo maps a `CGWindowID` to an `AXUIElement` directly. Each site implements its own matching rule.

## Why it is cross-cutting
Four sites, none calling another, read in `macos/Classes/WindowHandler.swift` and `CaptureHandler.swift`:
- `AXRoleResolver.role`: exact title, or the first *titled* AX window when the CG name is empty (untitled AX windows are never cached).
- `WindowHandler.findWindowElement`: exact title, or the first titled AX window when the name is empty.
- `WindowHandler.findWindowElementFlexible`: exact, then `contains`, then `windowsArray[0]` when the name is empty. Close, focus and scroll try this first.
- `CaptureHandler.captureWindow`'s minimized check: any minimized AX window whose title equals the SC title, or any minimized window at all when the SC title is empty.

They agree on the assumption (title identifies the window) but not on the rule, so making one stricter leaves the others matching differently.

## Territories it holds in
- [window-listing](../territory/window-listing.md): `AXRoleResolver.role` decides which window's `role`/`subrole` is reported.
- [window-control](../territory/window-control.md): `findWindowElementFlexible` / `findWindowElement` decide which window is closed or focused.
- [scroll-inspection](../territory/scroll-inspection.md): the same pair decides which window's scroll bars are read.
- [window-capture](../territory/window-capture.md): the minimized check decides whether a capture is refused.

## What a violation looks like
It reproduces when one app has two windows with the same title, an empty title, or one title containing the other:
- the `role`/`subrole` of the wrong window is reported;
- `closeWindow`/`focusWindow` acts on a sibling window;
- `captureWindow` returns `windowMinimized` for a visible window because an untitled sibling is minimized.

## Discovery history
- Found reading the four sites on 2026-10-23. Whether a direct `CGWindowID` → AX lookup is available was not checked against Apple's documentation (a summarized source, see `docs/agents/thegraph.md`).

## Where it will recur
If a function turns a `windowId` into an `AXUIElement` (or the reverse), it is subject to this. Grep `kAXTitleAttribute` and `kAXWindowsAttribute` in `macos/Classes/`.
