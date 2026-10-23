# Window dictionary shape

## The fact
Every window query returns the same dictionary: `windowId`, `name`, `ownerName`, `x`, `y`, `width`, `height`, `layer`, `isOnScreen`, `processId`, plus the optional `role`, `subrole`, `storeType`, `sharingState`, `alpha`, `memoryUsage`, `isInVideoMemory`. Two Swift functions build it, each with its own copy of the extraction code, and `MacosWindowInfo.fromMap` reads it by the same key strings.

## Why it is cross-cutting
`WindowHandler.getAllWindows` and `WindowHandler.getFilteredWindows` neither call each other nor share a helper: each walks `CGWindowListCopyWindowInfo` and fills the dictionary line by line (read in `macos/Classes/WindowHandler.swift`). The Dart model is a third site that names the keys again. A field added, renamed or defaulted differently in one builder shows up in `getAllWindows()` and not in `getWindowsByName()` (or the reverse), and `fromMap` silently defaults it.

## Territories it holds in
- [window-listing](../territory/window-listing.md): `WindowHandler.getAllWindows`, `WindowHandler.getFilteredWindows`, and `lib/src/models/macos_window_info.dart — MacosWindowInfo.fromMap`.
- [window-control](../territory/window-control.md): `closeWindow` and `focusWindow` read `processId` and `name` back out of `getWindowById`'s dictionary (built by `getFilteredWindows`).
- [scroll-inspection](../territory/scroll-inspection.md): `getScrollInfo` reads the same two keys from the same dictionary.

## What a violation looks like
A new property is present on windows from `getAllWindows()` but `null` on the same window from `getWindowById()`/`getWindowsAdvanced()`; or an action fails with `insufficientWindowInfo` because `processId` was dropped from the filtered builder only.

## Discovery history
- Found reading `WindowHandler.swift` on 2026-10-23: the two builders are line-for-line duplicates.
- Commit 9f24f0a (#3, 2026-06-12) had to install `AXRoleResolver` in both builders separately: its diff has two `roleResolver.role` call sites.

## Where it will recur
Any change that adds or alters a field taken from a `CGWindowListCopyWindowInfo` entry is subject to this: grep `kCGWindow` in `WindowHandler.swift` and change every builder, then `MacosWindowInfo.fromMap`.
