# Failure-code vocabulary

## The fact
A native failure reaches Dart as a typed failure reason only when every hop below names it. Any hop that misses it turns the failure into `unknown`.

1. Swift raises a `WindowError` / `CaptureHandler.CaptureError`, and `WindowHandler.handleWindowError` / `CaptureHandler.handleCaptureError` turn it into an upper-snake `code`.
2. `MacosWindowToolkitPlugin.isStateError` decides whether that code returns as a `{"success": false, "reason": …}` map (state) or as a `FlutterError` (everything else).
3. For a state, `MacosWindowToolkitPlugin.mapErrorCodeToReasonCode` gives the lower-snake `reason`, and the Dart mixin's `_mapReasonCodeToFailureReason` (or `_mapReasonCodeToScrollFailureReason`) gives the enum.
4. For a `FlutterError`, the mixin's `_isSystemError` rethrows only `INVALID_ARGUMENTS`, `SYSTEM_ERROR`, `OUT_OF_MEMORY` and `INTERNAL_ERROR`. Every other code goes through the mixin's `_mapErrorCodeToFailureReason` (the "legacy" map), and a code missing there becomes `unknown`.

## Why it is cross-cutting
No hop reads the others. The reason strings and code strings are literals repeated in Swift and in each Dart mixin, and each mixin keeps its own private copy of the maps and of `_isSystemError`. Read in `macos/Classes/MacosWindowToolkitPlugin.swift`, `lib/src/method_channel/window_operations_channel.dart`, `application_operations_channel.dart` and `capture_operations_channel.dart`. Adding a reason in one place and not the others gives a failure the caller cannot switch on.

## Territories it holds in
- [channel-bridge](../territory/channel-bridge.md): `MacosWindowToolkitPlugin.isStateError` and `mapErrorCodeToReasonCode`, `PlatformErrorCode` (`lib/src/models/platform_error_code.dart`).
- [window-control](../territory/window-control.md): `WindowOperationsChannel._mapReasonCodeToFailureReason` / `_mapErrorCodeToFailureReason`, `WindowOperationFailureReason`.
- [scroll-inspection](../territory/scroll-inspection.md): `WindowOperationsChannel._mapReasonCodeToScrollFailureReason` / `_mapErrorCodeToScrollFailureReason`, `ScrollFailureReason`.
- [process-control](../territory/process-control.md): `ApplicationOperationsChannel`'s own copies of the same maps.
- [window-capture](../territory/window-capture.md): `CaptureOperationsChannel`'s maps, `CaptureFailureReason`, `CaptureHandler.handleCaptureError`.

## What a violation looks like
Codes that currently reach Dart as `unknown`, read on 2026-10-23:
- `WINDOW_NOT_ACCESSIBLE` from `closeWindow` is not in `isStateError`, and `WindowOperationFailureReason` has no matching value. CHANGELOG 1.8.3 says `closeWindow()` returns `windowNotAccessible`, which the code does not do. (`getScrollInfo` raises the same code, but `_mapErrorCodeToScrollFailureReason` does map it to `windowNotAccessible`. `focusWindow` returns `windowNotFound` in the same situation.) The maintainer confirmed this is a gap, not intent (maintainer, 2026-10-23). Tracked: #7
- `REQUIRES_MACOS_14` from `captureWindow` on macOS 12.3–13 is not a state, and `CaptureOperationsChannel._mapErrorCodeToFailureReason` lacks it, so it becomes `unknown` rather than `unsupportedVersion`. Tracked: #7
- `SPACE_SWITCH_API_UNAVAILABLE`, `CLOSE_ACTION_FAILED`, `TERMINATION_FAILED` and `INSUFFICIENT_WINDOW_INFO` also become `unknown`.
- `ScrollFailureReason.noScrollableContent` (reason `no_scrollable_content`) is mapped in Dart but no Swift path produces it.
- `isWindowFullScreen` does not use the typed path at all: `WindowOperationsChannel.isWindowFullScreen` rethrows a state map as `PlatformException(code: reason.toUpperCase())`. That yields codes such as `PERMISSION_DENIED` that `PlatformErrorCode` does not list.

## Discovery history
- Found reading the dispatcher and the three mixins on 2026-10-23, while checking CHANGELOG 1.8.3's `windowNotAccessible` claim against the code.

## Where it will recur
If a change adds a `WindowError` / `CaptureError` case or a `*FailureReason` value, it is subject to this. Grep the code string and its lower-snake reason across `macos/Classes/` and `lib/src/` and update every hop above. Moving a code into `isStateError` changes its route for **every** handler that raises it. For example, `getScrollInfo` maps `WINDOW_NOT_ACCESSIBLE` correctly today only through the `FlutterError` route. A new public `*FailureReason` value breaks consumers' exhaustive `switch`es (see [shipping](../territory/shipping.md)).
