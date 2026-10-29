# Channel bridge

## What it is
This is the one path every call takes from Dart to Swift and back. The public `MacosWindowToolkit` facade calls `MacosWindowToolkitPlatform.instance`. That defaults to `MethodChannelMacosWindowToolkit`, which mixes in five `*Channel` mixins over a single `MethodChannel('macos_window_toolkit')`. On the Swift side, `MacosWindowToolkitPlugin.handle` switches on the method name and calls the handler classes. This area also decides how a failure is returned: as a result value, a thrown exception, or a typed failure.

## Governing decisions
**None.** No decision records exist (`docs/adr/` is absent). The state-vs-system-error split is declared per error case in `PluginError.stateReason` (#10, 2026-10-24); see [failure-code-vocabulary](../invariant/failure-code-vocabulary.md).

## Design model
From reading the source:
- **One channel, string-literal method names.** The channel name appears twice: in `MacosWindowToolkitPlugin.register` and in `MethodChannelMacosWindowToolkit.methodChannel`. Each method name is a literal in the Swift `handle` switch and again in a Dart `invokeMethod`. A name missing from the switch answers `FlutterMethodNotImplemented`.
- **Arguments are a map of literal keys.** Dart mixins omit `null` optionals, and Swift reads them with `as? Int/Bool/Double/CGFloat`. A missing required key gives `FlutterError("INVALID_ARGUMENTS")`, which the Dart mixins rethrow. Swift reads `customTitlebarHeight` `as? CGFloat` while Dart sends a `double`.
- **Three result shapes.** Results come back as a plain value (lists, bools), a `{"success": …}` map for operations that return typed results, or a `FlutterError`. How a code is routed between them is [failure-code-vocabulary](../invariant/failure-code-vocabulary.md).
- **Threading.** Synchronous handlers run on the platform thread that delivers the call and reply before returning. A handler that replies after it returns (`captureWindow`, `getCapturableWindows` and `isWindowFullScreen` from an unstructured `Task`, `closeWindow` after a Space-switch wait) replies on the main thread: `handle` wraps every call's `result` in `MacosWindowToolkitPlugin.onMain`, which calls through on the main thread and hops there from any other (#13).
- **Why the main thread, and what was measured.** Flutter's platform-channel page says to invoke channels destined for Flutter on the platform's main thread and says nothing explicit about replies (docs.flutter.dev/platform-integration/platform-channels, read 2026-10-24). The engine at Flutter 3.47.1 (engine `5d53178`) accepts a reply from any thread: `FlutterEngine.mm`'s response block sends it under `@synchronized`, and `PlatformMessageResponseDart::Complete` copies it and posts it to the UI task runner. So off-main replies were not lost; the main-thread hop follows the documented rule rather than fixing an observed loss (derivation, #13). Measured with `example/integration_test/channel_replies_test.dart` on 2026-10-24: 20 concurrent captures of a 1470×841 window (≈277KB each) replied in ~1.1s with ~60 frames rendered, so encoding the replies on the main thread costs no visible frames.
- **Two call helpers.** `lib/src/method_channel/channel_calls.dart` holds every reply-parsing path (#11, 2026-10-24):
  - `invokeResult` serves the result-typed calls (`closeWindow`, `focusWindow`, both terminations through `invokeOperation`, `captureWindow`, `getScrollInfo`). A map goes to the caller's parser and a bool to its optional bool shortcut. The operations take a bool for compatibility with the reply shape from before the `{"success": …}` map of v1.4.3 (moved from the removed mixin comments). `null` and any other type become the caller's `unknown` failure with one message (`No response from <method>` / `Unexpected response from <method>`). A `PlatformException` is rethrown for `systemErrorCodes`, otherwise built by the caller's converter from `failure_codes.dart`.
  - `invokeList` serves every model list: `null` is `[]`, and each item goes through `stringKeyed` (nested maps deep-converted) into the model's `fromMap`.
  - Outside both: the bool calls (`?? false`), `getScreenScaleFactor` (`?? 1.0`), `getChildProcesses` (`List<int>`), `getMacOSVersionInfo` (one map, `stringKeyed`), and `isWindowFullScreen`, whose state map is thrown as a `PlatformException`, not returned.
- **Models are made in the channel layer.** The platform interface returns models for every call, so the facade only forwards. Its one addition is `ApplicationResult`: an empty `getAllInstalledApplications` is `notFound`, an empty `getApplicationByName` is success, and any thrown error, a parse error included, is `systemError`. It also forwards permission watching to `PermissionWatcher.instance`.
- **One parsing policy in every `fromMap`.** Each key is read with a typed nullable cast and a default. Numbers go through `num`. A nested map is copied with `Map<String, dynamic>.from`, so `fromMap` also accepts a map that never went through `stringKeyed`. Equality hashes with `Object.hash`. A key of the wrong type still throws.
- **Swappable platform.** `MacosWindowToolkitPlatform` extends `PlatformInterface` with a private token, and composes the five `*Interface` mixins `with`, not `implements`. So a subclass inherits each method's `UnimplementedError` default, and a method added later does not break it. Tests replace `instance` with a fake that overrides only what it uses (`test/permission_watcher_test.dart — _FakePlatform`).

## Code
- `macos/macos_window_toolkit/Sources/macos_window_toolkit/MacosWindowToolkitPlugin.swift — MacosWindowToolkitPlugin.register`, `handle`, `required`, `replyWindows`, `reply`, `replyUnexpected`, `onMain`
- `macos/macos_window_toolkit/Sources/macos_window_toolkit/PluginError.swift — PluginError`, `PluginError.reply`, `DispatcherError`
- `lib/src/method_channel/channel_calls.dart — invokeResult`, `invokeOperation`, `invokeList`, `stringKeyed`
- `lib/src/method_channel/failure_codes.dart` (failure tables, `systemErrorCodes`)
- `lib/macos_window_toolkit.dart` (library exports)
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit`
- `lib/src/platform_interface/macos_window_toolkit_platform_interface.dart — MacosWindowToolkitPlatform`, plus the five `*_interface.dart` files beside it
- `lib/src/method_channel/macos_window_toolkit_method_channel.dart — MethodChannelMacosWindowToolkit`
- `lib/src/models/platform_error_code.dart — PlatformErrorCode`, `PlatformExceptionExtension`

## Reference behaviour
- `example/integration_test/channel_replies_test.dart` fires 20 each of `captureWindow`, `getCapturableWindows` and `isWindowFullScreen` at once and checks that every call replies and the UI keeps rendering (#13). It first checks that the test window renders while idle: macOS gives no frames to a window it considers hidden, and two runs on 2026-10-24 rendered 0 frames for that reason alone.
- `docs/agents/thegraph.md` names Flutter's plugin docs and `plugin_platform_interface` as the binding source for this area.

## Cross-cutting invariants
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [window-listing](window-listing.md), [window-control](window-control.md), [scroll-inspection](scroll-inspection.md), [window-capture](window-capture.md), [permissions](permissions.md), [process-control](process-control.md), [app-discovery](app-discovery.md), [system-info](system-info.md): method names and argument keys are literals duplicated between the Swift switch and each Dart mixin. Renaming one side breaks the call silently, as `MissingPluginException` or a dropped optional.
- [permission-watching](permission-watching.md): it calls `MacosWindowToolkitPlatform.instance` directly rather than through the facade, so a change to the platform singleton reaches it.
- [example-app](example-app.md): it is the only in-repo consumer of the public surface (path dependency `../`).
- [user-docs](user-docs.md): `documentations/api_reference.md` restates the public method list by hand.

## Known holes / open
- `test/macos_window_toolkit_method_channel_test.dart` covers the failure mappings of every result-typed call and `isWindowFullScreen`, both reply shapes, plus every native code against `PlatformErrorCode` (#7, #10). `test/macos_window_toolkit_test.dart` checks every facade method's name, argument keys and parsed result, and each result-typed call's null, unexpected, system-code and other-code paths (#11). The method names and keys in it are copied by hand from the Swift `handle` switch, so a rename on the Swift side alone still passes.
- Removing `stringKeyed`'s nested conversion fails no test: the two models with nested maps (`CapturableWindowInfo`, `MacosScreenInfo`) copy their nested maps themselves (mutation run during #11, 2026-10-24).
