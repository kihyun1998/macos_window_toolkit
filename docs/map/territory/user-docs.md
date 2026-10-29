# User docs

## What it is
The documentation consumers read: `README.md` and the `documentations/` tree (guides plus one page per API area). Both ship in the pub.dev archive.

## Governing decisions
**None.**

## Design model
From reading the docs against the code:
- **Hand-written copies.** The docs restate the public API by hand: method tables, return types, error codes, searched directories. Nothing generates them or checks them against `lib/`.
- **One capture path.** Since 1.5.0 ScreenCaptureKit is the only capture path. The pages describe only `captureWindow`, `getCapturableWindows` and `isWindowFullScreen`, and where they used to fall back to the removed legacy or auto-selection methods (or `getCaptureMethodInfo`) they now handle `CaptureFailureReason.unsupportedVersion` (#34, 2026-10-29). Check with `git grep -n -i -E 'legacy|captureWindowAuto|CapturableWindows(Auto|Legacy)|CGWindowListCreateImage|getCaptureMethodInfo' -- README.md documentations lib`: what remains is the error API's own history ("Legacy (String-based)").

- **Requirements have one home.** The minimum macOS, Flutter and Dart versions are stated in the README's `## Requirements`, which matches `pubspec.yaml`, the podspec and `Package.swift`. `getting_started.md`, `api_reference.md`, `troubleshooting.md` and `api/application_discovery.md` repeat the values and link to it; `contributing.md`'s prerequisites give what building the example needs instead (#27). A floor change edits the README and those four pages.
- **Isolates have one home.** `api_reference.md`'s `## Isolates` states the rule: call from the root isolate, since Flutter's platform channels throw a `StateError` off it until `BackgroundIsolateBinaryMessenger.ensureInitialized` has run (`flutter/lib/src/services/platform_channel.dart — _findBinaryMessenger`, Flutter 3.47.1). The API pages' `## Isolates` sections link to it. The plugin has not been run on a background isolate (#37). The docs no longer count methods by hand; `api_reference.md` links to the generated API docs instead.

## Code
- `README.md`
- `documentations/README.md`, `getting_started.md`, `advanced_usage.md`, `api_reference.md`, `examples.md`, `permission_monitoring.md`, `sandbox_configuration.md`, `troubleshooting.md`, `contributing.md`
- `documentations/api/application_discovery.md`, `error_handling.md`, `permission_management.md`, `process_management.md`, `system_info.md`, `window_capture.md`, `window_management.md`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [shipping](shipping.md): these files are published with every release, so a stale page ships with it.

## Known holes / open
- No page says which coordinate space screen frames and window bounds use (see [system-info](system-info.md)).
