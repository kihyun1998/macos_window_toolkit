import Cocoa
import Foundation

/// Terminates processes by PID, alone or with every descendant, and lists child PIDs
struct ProcessTerminator {
    /// Terminates an application by its process ID using system signals
    /// This method will terminate the entire application, not just a specific window.
    /// A PID that `signalTarget` refuses is reported as `invalidProcessId`, with nothing signalled
    func terminateApplicationByPID(_ processId: Int, force: Bool = false) -> Result<
        Bool, WindowError
    > {
        guard let pid = ProcessTerminator.signalTarget(processId) else {
            return .failure(.invalidProcessId)
        }

        // First verify the process exists
        guard processExists(pid) else {
            return .failure(.processNotFound)
        }

        // Try NSRunningApplication approach first (more graceful)
        let runningApps = NSWorkspace.shared.runningApplications
        if let app = runningApps.first(where: { $0.processIdentifier == pid }) {

            if force {
                let success = app.forceTerminate()
                return .success(success)
            } else {
                let success = app.terminate()
                return .success(success)
            }
        }

        // Fallback to signal-based termination
        let signal = force ? SIGKILL : SIGTERM
        let result = kill(pid, signal)

        if result == 0 {
            return .success(true)
        } else {
            return .failure(.terminationFailed)
        }
    }

    /// Gets all child process IDs for a given parent process ID
    func getChildProcesses(of parentPID: Int32) -> Result<[Int32], WindowError> {
        switch processTable() {
        case .success(let table):
            return .success(table.filter { $0.parent == parentPID }.map { $0.pid })
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Reads one snapshot of the process table, in the order the kernel lists it
    private func processTable() -> Result<[(pid: Int32, parent: Int32)], WindowError> {
        var size = 0

        // Get size needed for process list
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        let result = sysctl(&mib, 4, nil, &size, nil, 0)

        if result != 0 {
            return .failure(.failedToGetProcessList)
        }

        // Allocate buffer and get process list
        let count = size / MemoryLayout<kinfo_proc>.size
        let processes = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: count)
        defer { processes.deallocate() }

        let getProcessResult = sysctl(&mib, 4, processes, &size, nil, 0)
        if getProcessResult != 0 {
            return .failure(.failedToGetProcessList)
        }

        return .success(
            (0..<(size / MemoryLayout<kinfo_proc>.size)).map { i in
                (pid: processes[i].kp_proc.p_pid, parent: processes[i].kp_eproc.e_ppid)
            })
    }

    /// Returns every descendant of `root` in post-order (deepest first).
    /// PIDs in `skipped` are walked through but not returned.
    private func descendants(
        of root: Int32, parents: [Int32: Int32], skipped: Set<Int32>
    ) -> [Int32] {
        var children: [Int32: [Int32]] = [:]
        for (pid, parent) in parents where pid != parent {
            children[parent, default: []].append(pid)
        }

        var ordered: [Int32] = []
        var visited: Set<Int32> = [root]
        func visit(_ pid: Int32) {
            for child in children[pid] ?? [] where visited.insert(child).inserted {
                visit(child)
                if !skipped.contains(child) {
                    ordered.append(child)
                }
            }
        }
        visit(root)
        return ordered
    }

    /// Returns the calling process and its ancestors up to (excluding) `root`, or an
    /// empty set when the calling process does not descend from `root`
    private func pathFromCaller(to root: Int32, parents: [Int32: Int32]) -> Set<Int32> {
        var path: Set<Int32> = []
        var pid = getpid()
        while pid != root {
            guard path.insert(pid).inserted, let parent = parents[pid], parent != pid else {
                return []
            }
            pid = parent
        }
        return path
    }

    /// The PID a terminate call may signal: greater than 1 and within `pid_t`, or nil
    static func signalTarget(_ processId: Int) -> Int32? {
        guard let pid = Int32(exactly: processId), pid > 1 else { return nil }
        return pid
    }

    /// Whether a process with this PID exists, including one the caller may not signal
    private func processExists(_ pid: Int32) -> Bool {
        return kill(pid, 0) == 0 || errno == EPERM
    }

    /// Terminates `pid` and reports whether it is gone or was asked to quit
    private func terminateTreeMember(_ pid: Int32, force: Bool) -> Bool {
        guard processExists(pid) else { return true }
        switch terminateApplicationByPID(Int(pid), force: force) {
        case .success(let success):
            return success || !processExists(pid)
        case .failure:
            return !processExists(pid)
        }
    }

    /// Terminates an application and all its descendant processes, deepest first, and
    /// the application last. The calling process and the processes between it and the
    /// target are left running; when the target is the calling process itself, it is
    /// terminated last. Nothing is terminated when the process table cannot be read.
    func terminateApplicationTree(_ processId: Int, force: Bool = false) -> Result<
        Bool, WindowError
    > {
        guard let target = ProcessTerminator.signalTarget(processId) else {
            return .failure(.invalidProcessId)
        }
        guard processExists(target) else {
            return .failure(.processNotFound)
        }

        let parents: [Int32: Int32]
        switch processTable() {
        case .success(let table):
            parents = Dictionary(table.map { ($0.pid, $0.parent) }, uniquingKeysWith: { a, _ in a })
        case .failure(let error):
            return .failure(error)
        }

        let callerPath = pathFromCaller(to: target, parents: parents)
        var allTerminated = true
        for pid in descendants(of: target, parents: parents, skipped: callerPath) {
            if !terminateTreeMember(pid, force: force) {
                allTerminated = false
            }
        }

        if !callerPath.isEmpty {
            return .success(false)
        }
        return .success(terminateTreeMember(target, force: force) && allTerminated)
    }
}
