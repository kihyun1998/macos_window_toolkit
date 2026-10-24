# Process control

## What it is
Terminates an application by PID, gracefully or forcibly, terminates it together with every descendant process, and lists the direct child PIDs. The Swift code lives in `WindowHandler`. On the Dart side it sits in `ApplicationOperationsChannel`.

## Governing decisions
**None.** The caller rule below is the maintainer's call (2026-10-23), recorded here and in #8's PR, not in a decision record.

## Design model
From reading the source:
- **Existence check.** `terminateApplicationByPID` probes existence with `kill(pid, 0)`. A `-1` result means `processNotFound`.
- **Graceful path first.** It prefers `NSRunningApplication.terminate()` / `forceTerminate()` and returns their `Bool` as success. A `false` arrives in Dart as `OperationFailure(unknown, "Operation returned false")`.
- **Signal fallback.** For PIDs that are not running applications, it falls back to `SIGTERM`/`SIGKILL`.
- **One process-table snapshot.** `processTable` reads every process with `sysctl(KERN_PROC_ALL)` (a size probe, then a fetch) as `(pid, parent)` pairs in kernel order. `getChildProcesses` filters it for the parent, so it still returns **direct children only**, in the same order as before.
- **Tree termination.** `terminateApplicationTree` rejects a target of PID 0 or 1 or one that does not exist (`processNotFound`), and terminates **nothing** when the process table cannot be read (`failedToGetProcessList`), since it then cannot tell whether the caller is in the tree. It walks the snapshot's children index for **every descendant** in post-order (`descendants`, with a visited set) and asks each to quit deepest first, then the target, each with the caller's `force` (#8). `terminateTreeMember` counts a process as done when it was gone before its turn or it was asked to quit; existence is `kill(pid, 0) == 0 || errno == EPERM`, so a process the caller may not signal stays a failure. Nothing waits for exit: success means every quit request went out. Checking existence at call start and counting a target that vanished mid-call as terminated is a derivation (2026-10-23), not the maintainer's call.
- **The caller is never killed by its own call.** `pathFromCaller` collects the calling process and its ancestors up to the target. When that path is non-empty (the target is an ancestor of the caller), those processes and the target are skipped and the result is `false` (→ `unknown`); when the target is the caller itself, it terminates last and no reply arrives (maintainer, 2026-10-23). A process spawned after the snapshot is not covered.

## Code
- `macos/Classes/WindowHandler.swift — WindowHandler.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`, `processTable`, `descendants`, `pathFromCaller`, `processExists`, `terminateTreeMember`
- `macos/Classes/MacosWindowToolkitPlugin.swift — terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`
- `lib/src/method_channel/application_operations_channel.dart — ApplicationOperationsChannel.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`

## Reference behaviour
- `example/integration_test/process_tree_test.dart` spawns a real three-level shell tree and checks every PID is gone, with `force` off and on (#8). The "already gone at its turn" branches are not reached by it: the run never produces that window.

## Cross-cutting invariants
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [channel-bridge](channel-bridge.md): `ApplicationOperationsChannel` carries its own copy of the reason maps. A reason added for windows does not reach the terminate calls.
- [user-docs](user-docs.md): `documentations/api/process_management.md` describes the tree behaviour by hand.

## Known holes / open
- `terminateApplicationByPID`: `kill(pid, 0)` also returns `-1` with `EPERM` for a process owned by another user, so it is reported as `processNotFound`. Tracked: #17
- `processTable` sizes the buffer, then fetches. A process table that grows in between makes `sysctl` fail: `getChildProcesses` then returns `failedToGetProcessList`, and `terminateApplicationTree` terminates nothing.
- `terminateApplicationByPID` still sends `kill(pid, sig)` for any PID it is given, including 0 and -1, which signal a process group or every process the user may signal. `Int32(processId)` traps on a value outside `Int32`. Tracked: #17
- The caller/ancestor guard is not exercised by any test.
- `TERMINATION_FAILED` reaches Dart as `unknown` (see the invariant).
