# Territory map

<!-- grill-map build stamp: 8e5a943 -->
<!-- grill-map synced at: 9d629bb (2026-10-23) -->

This map answers two questions before a change:

- **If I touch this, what else moves?** Open the territory, then follow its `## Blast radius` and `## Cross-cutting invariants`.
- **What is this shape derived from?** Read `## Governing decisions`. In this repo every one says **None.**, because no decision records exist yet, so `## Design model` says where each rule was read from instead.

## How to read it

- `## Blast radius` is a checklist. Each edge names the assumption the two areas share, and an edge with nothing to do for your change is a correct outcome.
- A **None.** is itself the answer: nothing governs it, nothing was compared, or no invariant holds there.
- Conventions: headings are identical in every note. Code is named as `file — Symbol`, never by line number. Links are plain relative markdown. A fact another artifact owns is linked, not copied. Every claim carries its evidence (a symbol, a commit) or its source and date (`(maintainer, 2026-10-23)`).
- What it cannot answer: source files and issues are text inside notes, not nodes. Follow them by path.

## The system in one paragraph

`macos_window_toolkit` is a Flutter plugin whose Dart facade sends every call over one method channel to a Swift plugin. On the Swift side, CoreGraphics lists windows, the Accessibility API closes, focuses and inspects them, ScreenCaptureKit captures them, and `sysctl` and `NSWorkspace` handle processes and installed apps. The largest gap the reading found is the error path: a native failure becomes a typed Dart reason only if half a dozen hand-kept string maps all agree, and several do not.

## Territories

- [channel-bridge](territory/channel-bridge.md)
- [window-listing](territory/window-listing.md)
- [window-control](territory/window-control.md)
- [scroll-inspection](territory/scroll-inspection.md)
- [window-capture](territory/window-capture.md)
- [permissions](territory/permissions.md)
- [permission-watching](territory/permission-watching.md)
- [process-control](territory/process-control.md)
- [app-discovery](territory/app-discovery.md)
- [system-info](territory/system-info.md)
- [memory-measurement](territory/memory-measurement.md)
- [example-app](territory/example-app.md)
- [shipping](territory/shipping.md)
- [user-docs](territory/user-docs.md)

## Cross-cutting invariants

- [failure-code-vocabulary](invariant/failure-code-vocabulary.md)
- [ax-window-identity-by-title](invariant/ax-window-identity-by-title.md)

## Scope, and what an absent note means

The map covers `lib/`, `macos/`, `test/`, `example/`, the published docs and the release files, including CI and Dependabot configuration under `.github/` when it exists (owned by [shipping](territory/shipping.md)). The agent configuration (`CLAUDE.md`, `docs/agents/`) and this folder are out of scope: they describe how work is done, not what the system does. A territory appears when something in the repo commits to it: code, a spec, or an open issue with a design. An idea with nothing behind it gets no note. Absent decision records are why every `## Governing decisions` is **None.**; when an ADR lands in `docs/adr/`, the notes it governs link it.

A comment's why, trap and measured value go to the note that owns them (see the comment rule in `CLAUDE.md`).
