# User docs

## What it is
The documentation consumers read: `README.md` and the `documentations/` tree (guides plus one page per API area). Both ship in the pub.dev archive.

## Governing decisions
**None.**

## Design model
From reading the docs against the code:
- **Hand-written copies.** The docs restate the public API by hand: method tables, return types, error codes, searched directories. Nothing generates them or checks them against `lib/`.
- **Stale since 1.5.0.** Several pages still describe legacy capture, which CHANGELOG 1.5.0 removed: the README features line, `documentations/api_reference.md` ("Legacy Capture (CGWindowListCreateImage)"), `documentations/sandbox_configuration.md` and `documentations/api/error_handling.md` (legacy fallback advice). Found with `grep -n 'CGWindowListCreateImage\|legacy' README.md documentations/*.md documentations/api/*.md`.

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
- `documentations/api/process_management.md` lists `terminateApplicationTree()` as returning `Future<bool>`. The code returns `WindowOperationResult`.
- CHANGELOG 1.8.3's `windowNotAccessible` claim is false (see [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)).
- No page says which coordinate space screen frames and window bounds use (see [system-info](system-info.md)).
