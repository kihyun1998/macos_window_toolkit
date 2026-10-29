# Window capture

## What it is
Captures one window to PNG bytes with ScreenCaptureKit, optionally cropping the titlebar, transparent borders or a custom region, and resizing. It also lists the windows ScreenCaptureKit can capture, and tells whether a window is fullscreen.

## Governing decisions
**None.** CHANGELOG 1.5.0 records that ScreenCaptureKit became the only capture method, with `LegacyCaptureHandler`/`SmartCaptureHandler` removed. That is a changelog entry, not a decision record.

## Design model
From reading the source:
- **Gates, in order.**
  1. The dispatcher requires macOS 12.3. Below it, `captureWindow` returns the state `unsupported_version` and `getCapturableWindows` throws `UNSUPPORTED_MACOS_VERSION`.
  2. `CaptureHandler.captureWindow`, `isWindowFullScreen` and `getCapturableWindows` require Screen Recording (`requireScreenRecording`, through the injected `PermissionChecking`), each with its own message.
  3. They then require **macOS 14.0** for `SCScreenshotManager` (`REQUIRES_MACOS_14`, which reaches Dart as `unsupportedVersion` since #7). `getCapturableWindows` needs only 12.3.
- **Lookup.** The window is found by `windowID` in `SCShareableContent.current` (`CaptureHandler.window(_:in:)`, shared by capture and the fullscreen check). A window missing there is `INVALID_WINDOW_ID` → `windowNotFound`.
- **Minimized check.** The window is refused if an AX window of the owning app is minimized and its title matches (`CaptureHandler.isMinimized`). It reads `kAXMinimizedAttribute` because `isOnScreen` is false both for a minimized window and for one on another Space, and only the first may be refused. See [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md).
- **Output size.** `SCStreamConfiguration` width/height are the window frame's **points** (`Int(frame.width)`). No scale factor is applied, `scalesToFit = false`, and the cursor is hidden.
- **Post-processing order**, all inside one `autoreleasepool`:
  1. Titlebar crop: 28pt default, or `customTitlebarHeight`; 0 for a fullscreen window.
  2. `cropTransparentBorders`, then resize back to the frame size when `resizeCroppedToWindowSize` (default `true`, commit 1d24197).
  3. Custom crop: the center crop (`cropContentWidth/Height`) wins over the rect crop (`cropX/Y/Width/Height`); both are clamped.
  4. Resize to `targetWidth`×`targetHeight`: exact, or aspect-preserving with black fill.
  5. PNG via `NSBitmapImageRep`.
- **Memory.** The pool exists because `Task` threads don't drain autorelease pools (#4, commit e08c3bb). CHANGELOG 1.9.0 reports a ~19MB lower transient peak over a 300-capture soak (commit 1888f54, 2026-06-12).
- **Fullscreen.** A window is fullscreen when its SC frame equals some `NSScreen.frame` exactly (`isFullscreenWindow`).
- **Error classification.** `CaptureHandler.classify`, used by `captureWindow` and `getCapturableWindows`: NSError codes -3801/-3803 count as a permission denial; so does an error from a ScreenCaptureKit, Cocoa or OSStatus domain whose description says "permission", "not permitted" or "denied". Everything else is `captureFailed`. `isWindowFullScreen` classifies nothing: a ScreenCaptureKit error reaches the dispatcher as `FULLSCREEN_CHECK_FAILED`.
- **Error values.** Every `CaptureError` case carries one `NativeFailure` (message, and the `NSError` code and domain when there is one).
- **Capturable windows.** `getCapturableWindows` drops windows with an empty title.
- **Input bounds.** `targetWidth/Height` and the crop values are not validated. Zero or negative values make `CGContext` return nil (→ `captureFailed`), and a huge value allocates that size.

## Code
- `macos/macos_window_toolkit/Sources/macos_window_toolkit/CaptureHandler.swift — CaptureHandler.captureWindow`, `getCapturableWindows`, `isWindowFullScreen`, `requireScreenRecording`, `window(_:in:)`, `isMinimized`, `classify`, `isFullscreenWindow`, `cropTransparentBorders`, `resizeImageToExactSize`, `resizeImagePreservingAspectRatio`, `convertCGImageToPNG`, `NativeFailure`, `CaptureError` (top-level, so the pre-12.3 dispatcher branches can use it)
- `macos/macos_window_toolkit/Sources/macos_window_toolkit/MacosWindowToolkitPlugin.swift — captureWindow`, `getCapturableWindows`, `isWindowFullScreen`
- `lib/src/method_channel/capture_operations_channel.dart — CaptureOperationsChannel`
- `lib/src/method_channel/window_operations_channel.dart — WindowOperationsChannel.isWindowFullScreen`
- `lib/src/models/capture_result.dart — CaptureResult`, `CaptureFailure`, `CaptureFailureReason`
- `lib/src/models/capturable_window_info.dart — CapturableWindowInfo.fromMap`

## Reference behaviour
- Issue #1's baseline comment measured repeated capture on macOS 14.5 with a 2240×1260 target: not a leak; RSS growth is allocator retention plus Dart heap; footprint is about 104MB (issue #1 comment, 2026-06-12). The numbers are on the issue, and [memory-measurement](memory-measurement.md) holds the harness.
- `docs/agents/thegraph.md` names Apple's ScreenCaptureKit docs as binding and summarized. No capture behaviour here was compared against them.

## Cross-cutting invariants
- [ax-window-identity-by-title](../invariant/ax-window-identity-by-title.md)
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [permissions](permissions.md): capture prechecks `PermissionHandler.hasScreenRecordingPermission`. A change to that check changes when capture refuses.
- [memory-measurement](memory-measurement.md): the capture soak and its #1 baseline measure this exact pipeline. A change to buffers or the pool invalidates the comparison.
- [system-info](system-info.md): `isFullscreenWindow` compares against `NSScreen` frames. A change to how screens are described there, or in which coordinate space, affects fullscreen detection.
- [window-listing](window-listing.md): IDs come from the CG listing, but lookup is in `SCShareableContent`. The two sets differ.
- [user-docs](user-docs.md): the README and `documentations/` still describe legacy capture methods.

## Known holes / open
- Output is in points, not pixels. Whether that is intended is not recorded.
- `isFullscreenWindow` compares an `SCWindow.frame` with `NSScreen.frame`. The two may use different coordinate origins (top-left global vs. bottom-left Cocoa), which would break detection on non-primary displays. This needs confirming against Apple's docs.
- `captureInProgress` and `windowNotCapturable` exist in Dart, but no Swift path raises `CAPTURE_IN_PROGRESS` or `WINDOW_NOT_CAPTURABLE`.
