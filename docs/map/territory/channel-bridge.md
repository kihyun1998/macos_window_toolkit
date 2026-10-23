# Channel bridge

## What it is
This is the one path every call takes from Dart to Swift and back. The public `MacosWindowToolkit` facade calls `MacosWindowToolkitPlatform.instance`. That defaults to `MethodChannelMacosWindowToolkit`, which mixes in five `*Channel` mixins over a single `MethodChannel('macos_window_toolkit')`. On the Swift side, `MacosWindowToolkitPlugin.handle` switches on the method name and calls the handler classes. This area also decides how a failure is returned: as a result value, a thrown exception, or a typed failure.

## Governing decisions
**None.** No decision records exist (`docs/adr/` is absent). The state-vs-system-error split is described only in comments ("v1.4.3+ state errors" in the Dart mixins) and CHANGELOG entries.

## Design model
From reading the source:
- **One channel, string-literal method names.** The channel name appears twice: in `MacosWindowToolkitPlugin.register` and in `MethodChannelMacosWindowToolkit.methodChannel`. Each method name is a literal in the Swift `handle` switch and again in a Dart `invokeMethod`. A name missing from the switch answers `FlutterMethodNotImplemented`.
- **Arguments are a map of literal keys.** Dart mixins omit `null` optionals, and Swift reads them with `as? Int/Bool/Double/CGFloat`. A missing required key gives `FlutterError("INVALID_ARGUMENTS")`, which the Dart mixins rethrow. Swift reads `customTitlebarHeight` `as? CGFloat` while Dart sends a `double`.
- **Three result shapes.** Results come back as a plain value (lists, bools), a `{"success": …}` map for operations that return typed results, or a `FlutterError`. How a code is routed between them is [failure-code-vocabulary](../invariant/failure-code-vocabulary.md).
- **Threading.** Synchronous handlers run on the platform thread that delivers the call. `captureWindow`, `getCapturableWindows` and `isWindowFullScreen` start an unstructured `Task` and call `result` from inside it.
- **Facade adds models, nothing else.** `lib/src/macos_window_toolkit.dart — MacosWindowToolkit` turns maps into models (`MacosWindowInfo.fromMap`, `MacosApplicationInfo.fromMap`, …). It wraps application listing into `ApplicationResult` and forwards permission watching to `PermissionWatcher.instance`.
- **Swappable platform.** `MacosWindowToolkitPlatform` extends `PlatformInterface` with a private token. Tests replace `instance` with a fake (`test/permission_watcher_test.dart — _FakePlatform`).

## Code
- `macos/Classes/MacosWindowToolkitPlugin.swift — MacosWindowToolkitPlugin.register`, `handle`, `isStateError`, `mapErrorCodeToReasonCode`, `handleWindowResult`
- `lib/macos_window_toolkit.dart` (library exports)
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit`
- `lib/src/platform_interface/macos_window_toolkit_platform_interface.dart — MacosWindowToolkitPlatform`, plus the five `*_interface.dart` files beside it
- `lib/src/method_channel/macos_window_toolkit_method_channel.dart — MethodChannelMacosWindowToolkit`
- `lib/src/models/platform_error_code.dart — PlatformErrorCode`, `PlatformExceptionExtension`

## Reference behaviour
**None.** This area was never compared against a reference. `docs/agents/thegraph.md` names Flutter's plugin docs and `plugin_platform_interface` as the binding source for it.

## Cross-cutting invariants
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [window-listing](window-listing.md), [window-control](window-control.md), [scroll-inspection](scroll-inspection.md), [window-capture](window-capture.md), [permissions](permissions.md), [process-control](process-control.md), [app-discovery](app-discovery.md), [system-info](system-info.md): method names and argument keys are literals duplicated between the Swift switch and each Dart mixin. Renaming one side breaks the call silently, as `MissingPluginException` or a dropped optional.
- [permission-watching](permission-watching.md): it calls `MacosWindowToolkitPlatform.instance` directly rather than through the facade, so a change to the platform singleton reaches it.
- [example-app](example-app.md): it is the only in-repo consumer of the public surface (path dependency `../`).
- [user-docs](user-docs.md): `documentations/api_reference.md` restates the public method list by hand.

## Known holes / open
- `test/macos_window_toolkit_method_channel_test.dart` covers only the failure mappings of `closeWindow`, `getScrollInfo` and `captureWindow` (#7). No test checks a method name, an argument key or a success result shape, and `test/macos_window_toolkit_test.dart` is `void main() {}`.
- `result` is called from inside a Swift `Task` (capture, capturable windows, fullscreen). Nothing here confirms that Flutter's macOS embedder accepts a reply from that thread. This is not checked against Flutter's docs (a summarized source).
- The Dart reason maps and `_isSystemError` are copied three times, once per mixin (see the invariant).
