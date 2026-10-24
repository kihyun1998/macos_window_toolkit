# Process control

## What it is
Terminates an application by PID, gracefully or forcibly, terminates it together with every descendant process, and lists the direct child PIDs. The Swift code lives in `WindowHandler`. On the Dart side it sits in `ApplicationOperationsChannel`.

## Governing decisions
**None.** The caller rule below is the maintainer's call (2026-10-23), recorded here and in #8's PR, not in a decision record.

## Design model
From reading the source:
- **Signal target.** Every terminate call first passes the Dart `int` through `WindowHandler.signalTarget`, which accepts only a value that fits `pid_t` (`Int32(exactly:)`) and is greater than 1. Anything else is `invalidProcessId` and nothing is signalled (#17). PID 0 and negative values would address process groups (`-1`: every process the user may signal), PID 1 is launchd, and `Int32(_:)` traps on an out-of-range value. `invalidProcessId` travels as code `INVALID_PROCESS_ID` with state reason `process_not_found`, so Dart sees `processNotFound` with its own message. That reporting is the maintainer's call (2026-10-24, #17), chosen over reusing `processNotFound` and over a new Dart reason.
- **Existence check.** `terminateApplicationByPID` then checks `processExists` (`kill(pid, 0) == 0 || errno == EPERM`), shared with tree termination. A live process the caller may not signal therefore passes, fails at `kill` and is `terminationFailed` (→ `unknown` in Dart), not `processNotFound` (#17).
- **Graceful path first.** It prefers `NSRunningApplication.terminate()` / `forceTerminate()` and returns their `Bool` as success. A `false` arrives in Dart as `OperationFailure(unknown, "Operation returned false")`.
- **Signal fallback.** For PIDs that are not running applications, it falls back to `SIGTERM`/`SIGKILL`.
- **One process-table snapshot.** `processTable` reads every process with `sysctl(KERN_PROC_ALL)` (a size probe, then a fetch) as `(pid, parent)` pairs in kernel order. `getChildProcesses` filters it for the parent, so it still returns **direct children only**, in the same order as before. The dispatcher answers `[]` for a parent outside `pid_t` without reading the table (#17).
- **Tree termination.** `terminateApplicationTree` refuses a target `signalTarget` refuses (`invalidProcessId`) and one that does not exist (`processNotFound`), and terminates **nothing** when the process table cannot be read (`failedToGetProcessList`), since it then cannot tell whether the caller is in the tree. It walks the snapshot's children index for **every descendant** in post-order (`descendants`, with a visited set) and asks each to quit deepest first, then the target, each with the caller's `force` (#8). `terminateTreeMember` counts a process as done when it was gone before its turn or it was asked to quit; existence is `kill(pid, 0) == 0 || errno == EPERM`, so a process the caller may not signal stays a failure. Nothing waits for exit: success means every quit request went out. Checking existence at call start and counting a target that vanished mid-call as terminated is a derivation (2026-10-23), not the maintainer's call.
- **The caller is never killed by its own call.** `pathFromCaller` collects the calling process and its ancestors up to the target. When that path is non-empty (the target is an ancestor of the caller), those processes and the target are skipped and the result is `false` (→ `unknown`); when the target is the caller itself, it terminates last and no reply arrives (maintainer, 2026-10-23). A process spawned after the snapshot is not covered.

## Code
- `macos/Classes/WindowHandler.swift — WindowHandler.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`, `signalTarget`, `processTable`, `descendants`, `pathFromCaller`, `processExists`, `terminateTreeMember`
- `macos/Classes/MacosWindowToolkitPlugin.swift — terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`
- `lib/src/method_channel/application_operations_channel.dart — ApplicationOperationsChannel.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`

## Reference behaviour
- `example/integration_test/process_tree_test.dart` spawns a real three-level shell tree and checks every PID is gone, with `force` off and on (#8). The "already gone at its turn" branches are not reached by it: the run never produces that window. Its `a PID no terminate call may signal` group sends PID 1 and an out-of-range PID through Dart, and a root-owned PID to check `EPERM` (#17).
- `example/macos/RunnerTests/RunnerTests.swift — ProcessTargetTests` pins `signalTarget` for every refused class and the refusals in both terminate calls (#17). Run with `xcodebuild test -workspace example/macos/Runner.xcworkspace -scheme Runner -destination platform=macOS` after a `flutter build macos` of the example; a `flutter test integration_test/... -d macos` run in between leaves the generated build settings pointing at a deleted entry point, and the `flutter build macos` repairs them.
- **No test passes a PID <= 0 to a terminate call, nor PID 1 to tree termination.** With the guard broken, the first signals the caller's process group or every process the user may signal, and the second walks launchd's descendants (every process). The `<= 1` predicate is pinned on `signalTarget` alone; a terminate call is only given PID 1 (`kill` from a non-root caller cannot signal launchd) or an out-of-range value (#17).

## Cross-cutting invariants
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [channel-bridge](channel-bridge.md): `ApplicationOperationsChannel` carries its own copy of the reason maps. A reason added for windows does not reach the terminate calls.
- [user-docs](user-docs.md): `documentations/api/process_management.md` describes the tree behaviour by hand.

## Known holes / open
- `processTable` sizes the buffer, then fetches. A process table that grows in between makes `sysctl` fail: `getChildProcesses` then returns `failedToGetProcessList`, and `terminateApplicationTree` terminates nothing.
- The caller/ancestor guard is not exercised by any test.
- `TERMINATION_FAILED` reaches Dart as `unknown` (see the invariant).
