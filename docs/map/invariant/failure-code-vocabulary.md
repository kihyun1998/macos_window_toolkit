# Failure-code vocabulary

## The fact
A native failure reaches Dart as a typed failure reason only when two tables agree, one per language:

1. **Swift** — every error type conforms to `PluginError` (`macos/Classes/PluginError.swift`) and declares, per case, its wire `code`, its `stateReason` (non-nil: returned as a `{"success": false, "reason": …, "code": …}` state map; nil: reported as a `FlutterError`), `message`, `details` and any native `NSError` code and domain. `PluginError.reply(to:code:allowState:)` is the only place a failure becomes a reply; the `FlutterError`'s details carry the same fields as a map.
2. **Dart** — `lib/src/method_channel/failure_codes.dart` holds one code→reason table (for failures arriving as a `PlatformException`), one reason→enum table per failure enum (`WindowOperationFailureReason`, `CaptureFailureReason`, `ScrollFailureReason`), and `systemErrorCodes`, the codes rethrown instead of returned (`INVALID_ARGUMENTS`, `SYSTEM_ERROR`, `OUT_OF_MEMORY`, `INTERNAL_ERROR`); of these only `INVALID_ARGUMENTS` is ever sent. Every channel mixin builds its failures through it. A code or reason missing from it becomes `unknown`.

`PlatformErrorCode` (`lib/src/models/platform_error_code.dart`) must list every code the Swift side can send, so `PlatformExceptionExtension.errorCode` resolves it.

## Why it is cross-cutting
The two tables are literals in two languages that never call each other; the method channel carries only strings. A case added to a Swift error enum with a reason the Dart table lacks, or a code `PlatformErrorCode` lacks, arrives as `unknown` or with a `null` `errorCode`. Since #10 each language has one table, so the agreement is two edits, not five (commit history of #10, 2026-10-24).

## Territories it holds in
- [channel-bridge](../territory/channel-bridge.md): `PluginError.reply`, `DispatcherError`, the dispatcher's per-call codes (`WINDOW_LIST_ERROR`, `GET_CHILD_PROCESSES_ERROR`, `GET_APPLICATIONS_ERROR`) and `failure_codes.dart`, `PlatformErrorCode`.
- [window-control](../territory/window-control.md): `WindowError`'s states and `WindowOperationFailureReason`, including `windowStillOpen` (`WINDOW_STILL_OPEN`, only with `closeWindow`'s `waitUntilClosed`, #25).
- [scroll-inspection](../territory/scroll-inspection.md): `WindowError.windowNotAccessible` and friends through `ScrollFailureReason`.
- [process-control](../territory/process-control.md): `WindowError.processNotFound` / `.invalidProcessId` / `.terminationFailed`; the process calls share the window reason table. Like `INVALID_WINDOW_ID` and `REQUIRES_MACOS_14`, `INVALID_PROCESS_ID` shares its state reason (`process_not_found`) with another code, so it needs its own `_reasonByCode` row (#17).
- [window-capture](../territory/window-capture.md): `CaptureError` and `CaptureFailureReason`; `isWindowFullScreen` rethrows a state map as `PlatformException` with the map's wire `code`.

## What a violation looks like
Codes that still reach Dart as `unknown`, read on 2026-10-24: `SPACE_SWITCH_API_UNAVAILABLE`, `CLOSE_ACTION_FAILED`, `TERMINATION_FAILED`, `INSUFFICIENT_WINDOW_INFO` (thrown, no Dart reason). Dart reasons no Swift path produces: `noScrollableContent`, `captureInProgress`, `windowNotCapturable` (documented as not produced; kept, since an exhaustive `switch` cannot drop them). The Dart code table still accepts dead codes (`PERMISSION_DENIED`, `CAPTURE_IN_PROGRESS`, `WINDOW_NOT_CAPTURABLE`, `NO_SCROLLABLE_CONTENT`), pinned by the channel tests.

## Discovery history
- Found reading the dispatcher and the three mixins on 2026-10-23, while checking CHANGELOG 1.8.3's `windowNotAccessible` claim against the code.
- #7 fixed `WINDOW_NOT_ACCESSIBLE` and `REQUIRES_MACOS_14` at the Dart tables only, leaving the route to #10 (maintainer, 2026-10-23). #10 made both states and moved the facts to one table per language (2026-10-24).
- `test/macos_window_toolkit_method_channel_test.dart` pins, in both reply shapes, every state the Swift side declares for each method that can raise it, and lists every native code against `PlatformErrorCode`. The native-code list is copied by hand from `macos/Classes/`, so a new Swift case is caught only when someone adds its row.

## Where it will recur
A new `PluginError` case, a new `*FailureReason` value, or a new per-call code is subject to this: add the Swift case, its reason to `failure_codes.dart`, its code to `PlatformErrorCode`, and a row to the channel test's native-code list.
