import Cocoa
import FlutterMacOS
import XCTest


@testable import macos_window_toolkit

/// Never passes a PID <= 0 to a terminate call, nor PID 1 to tree termination: with
/// the guard broken, those signal the caller's process group, every process the user
/// may signal, or every descendant of launchd. PID 1 alone is safe to pass, since a
/// non-root caller cannot signal launchd.
class ProcessTargetTests: XCTestCase {

  let handler = WindowHandler()
  let outOfRange = Int(Int32.max) + 1

  func testSignalTargetAcceptsOnlyPIDsAboveOneThatFitInPidT() {
    for refused in [Int.min, Int(Int32.min) - 1, Int(Int32.min), -2, -1, 0, 1, outOfRange, Int.max] {
      XCTAssertNil(WindowHandler.signalTarget(refused), "\(refused)")
    }
    XCTAssertEqual(WindowHandler.signalTarget(2), 2)
    XCTAssertEqual(WindowHandler.signalTarget(Int(Int32.max)), Int32.max)
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
