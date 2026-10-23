# Memory measurement

## What it is
A repeatable way to measure the plugin's memory and latency under load: an in-app Memory Harness page and automated `integration_test` runs. Issue #1's comment holds the recorded baseline that later fixes compare against.

## Governing decisions
**None.** Issue #1 (closed) defined the three scenarios and the per-suspect verdicts.

## Design model
From the harness sources and issue #1:
- **Three scenarios.** Repeated `captureWindow`, continuous `getAllWindows` polling, and `PermissionWatcher` with listeners cancelled. RSS is sampled in-process (`ProcessInfo.currentRss`), followed by settle samples at +5s and +15s.
- **How to run.** `flutter test integration_test/memory_harness_test.dart -d macos` from `example/`, with the knobs `CAPTURE_ITERATIONS`, `CAPTURE_ONLY` and `HOLD_SECONDS` passed through `--dart-define` (issue #1 comment, 2026-06-12). The report prints between REPORT markers.
- **AX probe.** `ax_parity_probe_test.dart` is a "temporary probe for issue #3" (its header comment): latency over 20 calls plus a role/subrole histogram.
- **Verdicts on record.** No leak in capture, listing or the watcher. The capture growth is allocator retention plus Dart heap (issue #1 comment, 2026-06-12).
- **Environment.** The baseline was taken on macOS 14.5, a debug build, ARM64. Under a terminal, TCC grants go to the terminal app.

## Code
- `example/lib/page/memory_harness/memory_harness_page.dart — MemoryHarnessPage`, `_MemoryHarnessPageState._runScenario`, `_runCaptureScenario`, `_runPollingScenario`, `_watcherCancelListeners`, `_takeSettleSamples`, `_copyResults`
- `example/integration_test/memory_harness_test.dart — ScenarioReport`
- `example/integration_test/ax_parity_probe_test.dart`

## Reference behaviour
- The baseline table and verdicts are in issue #1's first comment (2026-06-12). Before/after figures for #3 and #4 are in CHANGELOG 1.9.0.

## Cross-cutting invariants
**None.**

## Blast radius
- [window-capture](window-capture.md), [window-listing](window-listing.md), [permission-watching](permission-watching.md): the harness calls their public API by name. Changing a signature breaks the harness, and changing behaviour invalidates the #1 baseline it compares against.

## Known holes / open
- Nothing runs the harness automatically. No CI exists (`.github/` is absent).
- The AX probe calls itself temporary, and nothing records whether it should stay.
