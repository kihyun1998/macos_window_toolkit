import Cocoa
import FlutterMacOS
import XCTest


@testable import macos_window_toolkit

/// Never passes a PID <= 0 to a terminate call, nor PID 1 to tree termination: with
/// the guard broken, those signal the caller's process group, every process the user
/// may signal, or every descendant of launchd. PID 1 alone is safe to pass, since a
/// non-root caller cannot signal launchd.
class ProcessTargetTests: XCTestCase {

  let handler = ProcessTerminator()
  let outOfRange = Int(Int32.max) + 1

  func testSignalTargetAcceptsOnlyPIDsAboveOneThatFitInPidT() {
    for refused in [Int.min, Int(Int32.min) - 1, Int(Int32.min), -2, -1, 0, 1, outOfRange, Int.max] {
      XCTAssertNil(ProcessTerminator.signalTarget(refused), "\(refused)")
    }
    XCTAssertEqual(ProcessTerminator.signalTarget(2), 2)
    XCTAssertEqual(ProcessTerminator.signalTarget(Int(Int32.max)), Int32.max)
  }

  func testTerminateByPIDRefusesPID1AndOutOfRange() throws {
    try XCTSkipIf(getuid() == 0, "a root caller may signal launchd")
    for pid in [1, outOfRange] {
      for force in [false, true] {
        XCTAssertEqual(
          handler.terminateApplicationByPID(pid, force: force), .failure(.invalidProcessId), "\(pid)")
      }
    }
  }

  func testTerminateTreeRefusesAnOutOfRangePID() {
    XCTAssertEqual(
      handler.terminateApplicationTree(outOfRange, force: false), .failure(.invalidProcessId))
  }

  func testTerminateByPIDDoesNotReportAProcessItMayNotSignalAsNotFound() throws {
    try XCTSkipIf(getuid() == 0, "a root caller may signal every process")
    let pid = try XCTUnwrap(rootOwnedPID())
    XCTAssertEqual(handler.terminateApplicationByPID(pid, force: false), .failure(.terminationFailed))
  }

  func testGetChildProcessesOfAnOutOfRangePIDIsEmpty() {
    let plugin = MacosWindowToolkitPlugin()
    let call = FlutterMethodCall(methodName: "getChildProcesses", arguments: ["processId": outOfRange])
    let replied = expectation(description: "reply")
    plugin.handle(call) { reply in
      XCTAssertEqual(reply as? [Int], [])
      replied.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  /// A live process above PID 1 owned by root and not a running application, which the
  /// caller may not signal and which reaches the signal path.
  private func rootOwnedPID() throws -> Int? {
    let ps = Process()
    ps.executableURL = URL(fileURLWithPath: "/bin/ps")
    ps.arguments = ["-U", "0", "-o", "pid="]
    let out = Pipe()
    ps.standardOutput = out
    try ps.run()
    ps.waitUntilExit()
    let text = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    let apps = Set(NSWorkspace.shared.runningApplications.map { Int($0.processIdentifier) })
    return text.split(separator: "\n").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
      .first { $0 > 1 && !apps.contains($0) }
  }
}

class SpaceSwitchWaitTests: XCTestCase {

  func testPollOnMainReturnsToItsCallerBeforeRetryingAndYieldsTheFirstValue() {
    var attempts = 0
    var returned = false
    var returnedBeforeRetry = false
    let finished = expectation(description: "finished")

    pollOnMain(every: 0.05, for: 1.0, attempt: { () -> Int? in
      attempts += 1
      // A retry that runs before pollOnMain has returned means it waited in place
      // (blocking or spinning the run loop) instead of scheduling the retry.
      if attempts == 2 { returnedBeforeRetry = returned }
      return attempts == 3 ? 42 : nil
    }) { value in
      XCTAssertEqual(value, 42)
      XCTAssertEqual(attempts, 3)
      XCTAssertTrue(returnedBeforeRetry, "the poll waited in place before retrying")
      finished.fulfill()
    }
    returned = true
    waitForExpectations(timeout: 2)
  }

  func testPollOnMainGivesUpAtTheDeadline() {
    var attempts = 0
    let start = Date()
    let finished = expectation(description: "finished")

    pollOnMain(every: 0.05, for: 0.3, attempt: { () -> Int? in
      attempts += 1
      return nil
    }) { value in
      XCTAssertNil(value)
      XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.3)
      XCTAssertGreaterThanOrEqual(attempts, 4)
      XCTAssertLessThanOrEqual(attempts, 8)
      finished.fulfill()
    }
    waitForExpectations(timeout: 2)
  }

  func testSerialGateStartsTheNextOperationOnlyAfterTheCurrentOneIsDone() {
    let gate = SerialGate()
    var log: [String] = []
    let bothDone = expectation(description: "both done")
    bothDone.expectedFulfillmentCount = 2

    gate.run { done in
      log.append("first started")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        log.append("first done")
        done()
        bothDone.fulfill()
      }
    }
    gate.run { done in
      log.append("second started")
      done()
      bothDone.fulfill()
    }

    waitForExpectations(timeout: 2)
    XCTAssertEqual(log, ["first started", "first done", "second started"])
  }
}

/// Space operations that record what they were asked to do, for a window on Space 2
/// while the user is on Space 1
final class FakeSpaces: SpaceControl {
  var isAvailable = true
  var windowSpace: UInt64? = 2
  var active: UInt64 = 1
  var log: [String] = []

  func space(ofWindow windowId: Int) -> UInt64? { windowSpace }
  func activeSpace() -> UInt64 { active }
  func display(ofWindow windowId: Int) -> CGDirectDisplayID { 7 }
  func activate(_ space: UInt64, on display: CGDirectDisplayID) {
    log.append("activate \(space) on \(display)")
  }
}

class SpaceSwitchCloseTests: XCTestCase {

  /// Runs one close through a `SpaceSwitcher` and returns its result, with the window
  /// reachable from the given attempt on, or never when nil
  private func close(
    _ spaces: FakeSpaces, reachableFromAttempt: Int? = 1,
    press: @escaping (String) -> Result<String, WindowError> = { .success($0) }
  ) -> Result<String, WindowError>? {
    let switcher = SpaceSwitcher(spaces: spaces, pollInterval: 0.01, pollTimeout: 0.2)
    var attempts = 0
    var result: Result<String, WindowError>?
    let finished = expectation(description: "finished")
    switcher.close(
      windowId: 9, releasesBeforeCompletion: false,
      find: { () -> String? in
        attempts += 1
        guard let first = reachableFromAttempt, attempts >= first else { return nil }
        spaces.log.append("found")
        return "window"
      },
      press: { window in
        spaces.log.append("press")
        return press(window)
      },
      completion: { closeResult in
        spaces.log.append("completed")
        result = closeResult
        finished.fulfill()
      })
    waitForExpectations(timeout: 2)
    return result
  }

  func testSwitchesToTheWindowsSpacePressesAndSwitchesBackBeforeCompleting() {
    let spaces = FakeSpaces()
    let result = close(spaces, reachableFromAttempt: 3)
    XCTAssertEqual(result, .success("window"))
    XCTAssertEqual(
      spaces.log, ["activate 2 on 7", "found", "press", "activate 1 on 7", "completed"])
  }

  func testSwitchesBackWhenTheWindowNeverBecomesReachable() {
    let spaces = FakeSpaces()
    let result = close(spaces, reachableFromAttempt: nil)
    XCTAssertEqual(result, .failure(.windowNotAccessible))
    XCTAssertEqual(spaces.log, ["activate 2 on 7", "activate 1 on 7", "completed"])
  }

  func testSwitchesBackWhenThePressFails() {
    let spaces = FakeSpaces()
    let result = close(spaces, press: { _ in .failure(.closeButtonNotFound) })
    XCTAssertEqual(result, .failure(.closeButtonNotFound))
    XCTAssertEqual(
      spaces.log, ["activate 2 on 7", "found", "press", "activate 1 on 7", "completed"])
  }

  func testDoesNotSwitchWhenTheWindowIsOnTheCurrentSpace() {
    let spaces = FakeSpaces()
    spaces.active = 2
    XCTAssertEqual(close(spaces), .success("window"))
    XCTAssertEqual(spaces.log, ["found", "press", "completed"])
  }

  func testFailsWithoutSwitchingWhenTheSpaceCallsAreMissing() {
    let spaces = FakeSpaces()
    spaces.isAvailable = false
    XCTAssertEqual(close(spaces), .failure(.spaceSwitchAPIUnavailable))
    XCTAssertEqual(spaces.log, ["completed"])
  }

  func testFailsWithoutSwitchingWhenTheWindowHasNoSpace() {
    let spaces = FakeSpaces()
    spaces.windowSpace = nil
    XCTAssertEqual(close(spaces), .failure(.windowNotAccessible))
    XCTAssertEqual(spaces.log, ["completed"])
  }

  /// Two closes queued back to back, the first completing through
  /// `releasesBeforeCompletion`. Each finds its window on its second attempt, so the
  /// first is still running when the second is queued.
  private func twoCloses(releasesBeforeCompletion: Bool, spaces: FakeSpaces) -> [String] {
    let switcher = SpaceSwitcher(spaces: spaces, pollInterval: 0.01, pollTimeout: 0.2)
    let bothDone = expectation(description: "both done")
    bothDone.expectedFulfillmentCount = 2
    for name in ["first", "second"] {
      var attempts = 0
      switcher.close(
        windowId: 9,
        releasesBeforeCompletion: name == "first" ? releasesBeforeCompletion : false,
        find: { () -> String? in
          attempts += 1
          guard attempts > 1 else { return nil }
          spaces.log.append("\(name) found")
          return name
        },
        press: { .success($0) },
        completion: { _ in
          spaces.log.append("\(name) completed")
          bothDone.fulfill()
        })
    }
    waitForExpectations(timeout: 2)
    return spaces.log
  }

  func testTheNextCloseWaitsWhileTheFirstIsRunning() {
    let spaces = FakeSpaces()
    let switcher = SpaceSwitcher(spaces: spaces, pollInterval: 0.01, pollTimeout: 0.2)
    let finished = expectation(description: "finished")
    var firstAttempts = 0
    switcher.close(
      windowId: 9, releasesBeforeCompletion: false,
      find: { () -> String? in
        firstAttempts += 1
        return firstAttempts > 1 ? "first" : nil
      },
      press: { .success($0) },
      completion: { _ in finished.fulfill() })
    var secondStarted = false
    switcher.close(
      windowId: 9, releasesBeforeCompletion: false,
      find: { () -> String? in
        secondStarted = true
        return "second"
      },
      press: { .success($0) }, completion: { _ in })
    XCTAssertFalse(secondStarted, "the second close started while the first was running")
    waitForExpectations(timeout: 2)
  }

  func testTheNextCloseStartsAfterTheFirstHasSwitchedBackAndCompleted() {
    XCTAssertEqual(
      twoCloses(releasesBeforeCompletion: false, spaces: FakeSpaces()),
      [
        "activate 2 on 7", "first found", "activate 1 on 7", "first completed",
        "activate 2 on 7", "second found", "activate 1 on 7", "second completed",
      ])
  }

  func testAReleasingCloseLetsTheNextStartBeforeItCompletes() {
    XCTAssertEqual(
      twoCloses(releasesBeforeCompletion: true, spaces: FakeSpaces()),
      [
        "activate 2 on 7", "first found", "activate 1 on 7", "activate 2 on 7",
        "first completed", "second found", "activate 1 on 7", "second completed",
      ])
  }

  func testTheNextCloseStartsAfterAFailedOne() {
    let spaces = FakeSpaces()
    spaces.isAvailable = false
    XCTAssertEqual(
      twoCloses(releasesBeforeCompletion: false, spaces: spaces),
      ["first completed", "second completed"])
  }
}
