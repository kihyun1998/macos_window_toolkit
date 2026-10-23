# Process control

## What it is
Terminates an application by PID, gracefully or forcibly, terminates it together with its child processes, and lists the child PIDs. The Swift code lives in `WindowHandler`. On the Dart side it sits in `ApplicationOperationsChannel`.

## Governing decisions
**None.**

## Design model
From reading the source:
- **Existence check.** `terminateApplicationByPID` probes existence with `kill(pid, 0)`. A `-1` result means `processNotFound`.
- **Graceful path first.** It prefers `NSRunningApplication.terminate()` / `forceTerminate()` and returns their `Bool` as success. A `false` arrives in Dart as `OperationFailure(unknown, "Operation returned false")`.
- **Signal fallback.** For PIDs that are not running applications, it falls back to `SIGTERM`/`SIGKILL`.
- **Child list.** `getChildProcesses` reads every process with `sysctl(KERN_PROC_ALL)` (a size probe, then a fetch) and keeps the ones whose `e_ppid` equals the parent. That is **one level only**.
- **Tree termination.** `terminateApplicationTree` terminates those direct children first, then the parent. The overall result is `success && allTerminated`. A failure to list children is ignored.

## Code
- `macos/Classes/WindowHandler.swift — WindowHandler.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`
- `macos/Classes/MacosWindowToolkitPlugin.swift — terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`
- `lib/src/method_channel/application_operations_channel.dart — ApplicationOperationsChannel.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`
- `lib/src/macos_window_toolkit.dart — MacosWindowToolkit.terminateApplicationByPID`, `terminateApplicationTree`, `getChildProcesses`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [failure-code-vocabulary](../invariant/failure-code-vocabulary.md)

## Blast radius
- [channel-bridge](channel-bridge.md): `ApplicationOperationsChannel` carries its own copy of the reason maps. A reason added for windows does not reach the terminate calls.
- [user-docs](user-docs.md): `documentations/api/process_management.md` describes the tree behaviour by hand.

## Known holes / open
- `terminateApplicationTree` leaves grandchildren running. The maintainer said single-level is **not** intended (maintainer, 2026-10-23).
- `kill(pid, 0)` also returns `-1` with `EPERM` for a process owned by another user, so it is reported as `processNotFound`.
- `getChildProcesses` sizes the buffer, then fetches. A process table that grows in between makes `sysctl` fail, which gives `failedToGetProcessList`.
- `TERMINATION_FAILED` reaches Dart as `unknown` (see the invariant).
