# Scroll inspection

## What it is
Reports whether a window has vertical or horizontal scroll bars and where they sit (0.0–1.0), read through the Accessibility API.

## Governing decisions
**None.**

## Design model
From reading the source:
- **Lookup.** Same precheck and element lookup as [window-control](window-control.md): `AXIsProcessTrusted`, `getWindowById`, `findWindowElementFlexible` → `findWindowElement`. A missing element returns `windowNotAccessible`.
- **`getScrollInfoFromElement` tries three strategies in order** and stops at the first that finds a bar:
  1. an `AXScrollArea` among the window's direct children;
  2. scroll-bar attributes on the window itself;
  3. a recursive search for `AXScrollArea` to depth 5.
- **Scope.** Only the **first** scroll area found is read. Positions come from `kAXValueAttribute` on the bar.
- **Result.** Success is `{"success": true, "scrollInfo": {...}}`, parsed by `ScrollInfo.fromMap` into `ScrollSuccess`.

## Code
- `macos/Classes/WindowHandler.swift — WindowHandler.getScrollInfo`, `getScrollInfoFromElement`, `findScrollArea`, `findScrollAreaRecursively`, `extractScrollBarInfo`
- `macos/Classes/MacosWindowToolkitPlugin.swift — getScrollInfo`
- `lib/src/method_channel/window_operations_channel.dart — WindowOperationsChannel.getScrollInfo`, `_parseScrollResult`
- `lib/src/models/scroll_info.dart — ScrollInfo`, `ScrollOperationResult`, `ScrollFailureReason`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md)
- [window-dictionary-shape](../invariant/window-dictionary-shape.md)
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [window-control](window-control.md): they share the AX element lookup helpers. A change made for close or focus changes which window is inspected here.
- [permissions](permissions.md): the Accessibility precheck.

## Known holes / open
- `ScrollFailureReason.noScrollableContent` is never produced. A window with no scroll bars returns success with both flags `false`.
- A window with several scroll areas (split views) reports only the first one found.
