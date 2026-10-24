# System info

## What it is
This area reports the macOS version and whether ScreenCaptureKit is available, plus the main screen's scale factor and every connected screen's frame, visible frame, scale and pixel size.

## Governing decisions
**None.**

## Design model
From reading the source:
- **Version.** `VersionUtil.getMacOSVersionInfo` reads `ProcessInfo.operatingSystemVersion`. `isScreenCaptureKitAvailable` means macOS 12.3 or later, which is not the same as "capture works": capture needs 14.0 (see [window-capture](window-capture.md)).
- **Screens.**
  - `getAllScreensInfo` reports `NSScreen.screens` in Cocoa coordinates. Their origin is bottom-left, unlike the CG window `x`/`y` that [window-listing](window-listing.md) reports (reading; the coordinate convention needs confirming against Apple's docs).
  - `pixelWidth`/`pixelHeight` are frame × `backingScaleFactor`.
- **Map conversion.** `getAllScreensInfo` goes through `invokeList` and `getMacOSVersionInfo` through `stringKeyed` (both in `lib/src/method_channel/channel_calls.dart`). `MacosScreenInfo.fromMap` also copies its nested `frame` and `visibleFrame` itself; see [channel-bridge](channel-bridge.md).

## Code
- `macos/Classes/VersionUtil.swift — VersionUtil.getMacOSVersionInfo`, `isScreenCaptureKitAvailable`, `getMacOSVersion`, `isMacOSVersionSupported`
- `macos/Classes/MacosWindowToolkitPlugin.swift — getMacOSVersionInfo`, `getScreenScaleFactor`, `getAllScreensInfo`
- `lib/src/method_channel/system_info_channel.dart — SystemInfoChannel`
- `lib/src/models/macos_version_info.dart — MacosVersionInfo`
- `lib/src/models/macos_screen_info.dart — MacosScreenInfo`, `ScreenRect`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [window-capture](window-capture.md): `isFullscreenWindow` compares window frames with `NSScreen` frames, the same screen description reported here. It also uses `VersionUtil.isScreenCaptureKitAvailable` and `getMacOSVersion` for its gate and its error details.
- [example-app](example-app.md): `example/lib/widgets/version_info_card.dart` and the window detail sheet display these values.

## Known holes / open
- `VersionUtil.isMacOSVersionSupported` has no caller.
- A consumer that positions windows using `getAllScreensInfo` frames with CG window coordinates mixes two origins. Nothing in the API says which space each uses.
