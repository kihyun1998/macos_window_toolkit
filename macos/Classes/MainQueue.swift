import Foundation

/// Calls `attempt` now, then every `interval` on the main queue, until it returns a
/// value or `timeout` passes, then calls `completion` with the value, or nil at the
/// deadline. Each retry is scheduled, so the caller returns before the first one.
func pollOnMain<T>(
    every interval: TimeInterval, for timeout: TimeInterval,
    attempt: @escaping () -> T?, completion: @escaping (T?) -> Void
) {
    let deadline = Date(timeIntervalSinceNow: timeout)
    func step() {
        guard Date() < deadline else {
            completion(nil)
            return
        }
        if let value = attempt() {
            completion(value)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: step)
    }
    step()
}

/// Runs operations one at a time, in the order given; each calls `done` when it has
/// finished. Used from the main thread only.
final class SerialGate {
    private var pending: [(_ done: @escaping () -> Void) -> Void] = []
    private var running = false

    /// Queues `operation`, and starts it now when nothing else is running
    func run(_ operation: @escaping (_ done: @escaping () -> Void) -> Void) {
        pending.append(operation)
        startNext()
    }

    private func startNext() {
        guard !running, !pending.isEmpty else { return }
        running = true
        let operation = pending.removeFirst()
        operation { [weak self] in
            self?.running = false
            self?.startNext()
        }
    }
}
