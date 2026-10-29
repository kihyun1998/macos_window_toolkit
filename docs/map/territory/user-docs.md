# User docs

## What it is
The documentation consumers read: `README.md` and the `documentations/` tree (guides plus one page per API area). Both ship in the pub.dev archive.

## Governing decisions
**None.**

## Design model
From reading the docs against the code:
- **Hand-written copies.** The docs restate the public API by hand: method tables, return types, error codes, searched directories. Nothing generates them or checks them against `lib/`.
- **Stale since 1.5.0.** Several pages still describe legacy capture, which CHANGELOG 1.5.0 removed: the README features line, `documentations/api_reference.md` ("Legacy Capture (CGWindowListCreateImage)"), `documentations/sandbox_configuration.md`, `documentations/api/error_handling.md` (legacy fallback advice) and `documentations/api/window_capture.md`, whose quick-reference tables list `captureWindowAuto`, `captureWindowLegacy`, `getCapturableWindowsAuto` and `getCapturableWindowsLegacy`, none of which `lib/` has (2026-10-29). Found with `grep -n 'CGWindowListCreateImage\|legacy' README.md documentations/*.md documentations/api/*.md`.

- **Requirements have one home.** The minimum macOS, Flutter and Dart versions are stated in the README's `## Requirements`, which matches `pubspec.yaml`, the podspec and `Package.swift`. `getting_started.md`, `api_reference.md`, `troubleshooting.md` and `api/application_discovery.md` repeat the values and link to it; `contributing.md`'s prerequisites give what building the example needs instead (#27). A floor change edits the README and those four pages.

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
- The legacy capture claims above are false at HEAD.
- No page says which coordinate space screen frames and window bounds use (see [system-info](system-info.md)).
