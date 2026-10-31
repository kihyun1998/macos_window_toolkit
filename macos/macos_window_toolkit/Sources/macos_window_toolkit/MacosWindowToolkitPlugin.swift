import Cocoa
import FlutterMacOS

/// The plugin's method channel: dispatches each call to the type that does its job
/// and replies on the main thread
public class MacosWindowToolkitPlugin: NSObject, FlutterPlugin {
  private let permissionHandler = PermissionHandler()
  private let windowQuery = WindowQuery()
  private lazy var windowActions = AXWindowActions(
    permissions: permissionHandler, query: windowQuery)
  private let processTerminator = ProcessTerminator()
  private let applicationHandler = ApplicationHandler()

  /// Registers the plugin on the `macos_window_toolkit` channel
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "macos_window_toolkit", binaryMessenger: registrar.messenger)
    let instance = MacosWindowToolkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  /// Runs the call named by `call.method`, or replies `FlutterMethodNotImplemented`
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let result = onMain(result)
    switch call.method {
    case "getAllWindows":
      getAllWindows(call: call, result: result)
    case "getWindowsByName":
      getWindowsByName(call: call, result: result)
    case "getWindowsByOwnerName":
      getWindowsByOwnerName(call: call, result: result)
    case "getWindowById":
      getWindowById(call: call, result: result)
    case "getWindowsByProcessId":
      getWindowsByProcessId(call: call, result: result)
    case "getWindowsAdvanced":
      getWindowsAdvanced(call: call, result: result)
    case "hasScreenRecordingPermission":
      hasScreenRecordingPermission(result: result)
    case "requestScreenRecordingPermission":
      requestScreenRecordingPermission(result: result)
    case "openScreenRecordingSettings":
      openScreenRecordingSettings(result: result)
    case "getMacOSVersionInfo":
      getMacOSVersionInfo(result: result)
    case "captureWindow":
      captureWindow(call: call, result: result)
    case "getCapturableWindows":
      getCapturableWindows(result: result)
    case "isWindowAlive":
      isWindowAlive(call: call, result: result)
    case "closeWindow":
      closeWindow(call: call, result: result)
    case "focusWindow":
      focusWindow(call: call, result: result)
    case "terminateApplicationByPID":
      terminateApplicationByPID(call: call, result: result)
    case "terminateApplicationTree":
      terminateApplicationTree(call: call, result: result)
    case "getChildProcesses":
      getChildProcesses(call: call, result: result)
    case "hasAccessibilityPermission":
      hasAccessibilityPermission(result: result)
    case "requestAccessibilityPermission":
      requestAccessibilityPermission(result: result)
    case "openAccessibilitySettings":
      openAccessibilitySettings(result: result)
    case "getAllInstalledApplications":
      getAllInstalledApplications(result: result)
    case "getApplicationByName":
      getApplicationByName(call: call, result: result)
    case "openAppStoreSearch":
      openAppStoreSearch(call: call, result: result)
    case "getScreenScaleFactor":
      getScreenScaleFactor(result: result)
    case "getAllScreensInfo":
      getAllScreensInfo(result: result)
    case "getScrollInfo":
      getScrollInfo(call: call, result: result)
    case "isWindowFullScreen":
      isWindowFullScreen(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// The call's arguments, or an empty map when it has none
  private func arguments(_ call: FlutterMethodCall) -> [String: Any] {
    return call.arguments as? [String: Any] ?? [:]
  }

  /// Reads a required argument, replying `INVALID_ARGUMENTS` with `message` when
  /// it is missing or has another type
  private func required<T>(
    _ key: String, of call: FlutterMethodCall, _ result: FlutterResult, _ message: String
  ) -> T? {
    guard let value = arguments(call)[key] as? T else {
      DispatcherError.missingArgument(message).reply(to: result)
      return nil
    }
    return value
  }

  /// Replies with a window list, or with every failure as `WINDOW_LIST_ERROR`
  private func replyWindows(
    _ windowResult: Result<[[String: Any]], WindowError>, _ result: FlutterResult
  ) {
    switch windowResult {
    case .success(let windows):
      result(windows)
    case .failure(let error):
      error.reply(to: result, code: "WINDOW_LIST_ERROR", allowState: false)
    }
  }

  /// Replies with an operation's value, or with its failure
  private func reply<Value>(_ operationResult: Result<Value, WindowError>, _ result: FlutterResult) {
    switch operationResult {
    case .success(let value):
      result(value)
    case .failure(let error):
      error.reply(to: result)
    }
  }

  /// `result`, delivered on the main thread whichever thread calls it. `handle` wraps
  /// every call's result in it, so a handler that replies after it returns (from a `Task`
  /// or a scheduled wait) replies on the main thread too.
  private func onMain(_ result: @escaping FlutterResult) -> FlutterResult {
    return { value in
      if Thread.isMainThread {
        result(value)
      } else {
        DispatchQueue.main.async { result(value) }
      }
    }
  }

  /// Replies with an error that is not one of the plugin's own, under `code`
  private func replyUnexpected(_ error: Error, code: String, _ result: FlutterResult) {
    DispatcherError(
      code: code, message: "Unexpected error occurred", details: error.localizedDescription
    ).reply(to: result)
  }

  /// Retrieves information about all windows with optional parameters
  private func getAllWindows(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let excludeEmptyNames = arguments(call)["excludeEmptyNames"] as? Bool ?? false
    replyWindows(windowQuery.getAllWindows(excludeEmptyNames: excludeEmptyNames), result)
  }

  /// Checks if the app has screen recording permission
  private func hasScreenRecordingPermission(result: @escaping FlutterResult) {
    result(permissionHandler.hasScreenRecordingPermission())
  }

  /// Requests screen recording permission
  private func requestScreenRecordingPermission(result: @escaping FlutterResult) {
    result(permissionHandler.requestScreenRecordingPermission())
  }

  /// Opens screen recording settings in System Preferences
  private func openScreenRecordingSettings(result: @escaping FlutterResult) {
    result(permissionHandler.openScreenRecordingSettings())
  }

  /// Checks if the app has accessibility permission
  private func hasAccessibilityPermission(result: @escaping FlutterResult) {
    result(permissionHandler.hasAccessibilityPermission())
  }

  /// Requests accessibility permission
  private func requestAccessibilityPermission(result: @escaping FlutterResult) {
    result(permissionHandler.requestAccessibilityPermission())
  }

  /// Opens accessibility settings in System Preferences
  private func openAccessibilitySettings(result: @escaping FlutterResult) {
    result(permissionHandler.openAccessibilitySettings())
  }

  /// Retrieves windows filtered by name (window title)
  private func getWindowsByName(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let name: String = required("name", of: call, result, "Name parameter is required")
    else { return }
    replyWindows(windowQuery.getWindowsByName(name), result)
  }

  /// Retrieves windows filtered by owner name (application name)
  private func getWindowsByOwnerName(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let ownerName: String = required(
        "ownerName", of: call, result, "OwnerName parameter is required")
    else { return }
    replyWindows(windowQuery.getWindowsByOwnerName(ownerName), result)
  }

  /// Retrieves a specific window by its window ID
  private func getWindowById(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let windowId: Int = required("windowId", of: call, result, "WindowId parameter is required")
    else { return }
    replyWindows(windowQuery.getWindowById(windowId), result)
  }

  /// Retrieves windows filtered by process ID
  private func getWindowsByProcessId(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let processId: Int = required(
        "processId", of: call, result, "ProcessId parameter is required")
    else { return }
    replyWindows(windowQuery.getWindowsByProcessId(processId), result)
  }

  /// Retrieves windows with advanced filtering options
  /// All filter parameters are optional - nil values are ignored
  private func getWindowsAdvanced(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = arguments(call)
    replyWindows(
      windowQuery.getWindowsAdvanced(
        windowId: arguments["windowId"] as? Int,
        name: arguments["name"] as? String,
        nameExactMatch: arguments["nameExactMatch"] as? Bool,
        nameCaseSensitive: arguments["nameCaseSensitive"] as? Bool,
        nameWildcard: arguments["nameWildcard"] as? Bool,
        ownerName: arguments["ownerName"] as? String,
        ownerNameExactMatch: arguments["ownerNameExactMatch"] as? Bool,
        ownerNameCaseSensitive: arguments["ownerNameCaseSensitive"] as? Bool,
        ownerNameWildcard: arguments["ownerNameWildcard"] as? Bool,
        processId: arguments["processId"] as? Int,
        isOnScreen: arguments["isOnScreen"] as? Bool,
        layer: arguments["layer"] as? Int,
        x: arguments["x"] as? Double,
        y: arguments["y"] as? Double,
        width: arguments["width"] as? Double,
        height: arguments["height"] as? Double
      ), result)
  }

  /// Gets macOS version information
  private func getMacOSVersionInfo(result: @escaping FlutterResult) {
    result(VersionUtil.getMacOSVersionInfo())
  }

  /// The error for a ScreenCaptureKit call on macOS before 12.3
  private var screenCaptureKitUnavailable: CaptureError {
    return .unsupportedMacOSVersion(
      NativeFailure(message: "macOS version does not support ScreenCaptureKit"))
  }

  /// Captures a window using ScreenCaptureKit
  private func captureWindow(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let windowId: Int = required("windowId", of: call, result, "WindowId parameter is required")
    else { return }
    let arguments = arguments(call)

    let excludeTitlebar = arguments["excludeTitlebar"] as? Bool ?? false
    let customTitlebarHeight = arguments["customTitlebarHeight"] as? CGFloat
    let targetWidth = arguments["targetWidth"] as? Int
    let targetHeight = arguments["targetHeight"] as? Int
    let preserveAspectRatio = arguments["preserveAspectRatio"] as? Bool ?? false
    let cropContentWidth = arguments["cropContentWidth"] as? Int
    let cropContentHeight = arguments["cropContentHeight"] as? Int
    let cropX = arguments["cropX"] as? Int
    let cropY = arguments["cropY"] as? Int
    let cropWidth = arguments["cropWidth"] as? Int
    let cropHeight = arguments["cropHeight"] as? Int
    let resizeCroppedToWindowSize = arguments["resizeCroppedToWindowSize"] as? Bool ?? true

    guard #available(macOS 12.3, *) else {
      screenCaptureKitUnavailable.reply(to: result)
      return
    }
    Task {
      do {
        let imageData = try await CaptureHandler.captureWindow(
          windowId: windowId, excludeTitlebar: excludeTitlebar,
          customTitlebarHeight: customTitlebarHeight,
          targetWidth: targetWidth, targetHeight: targetHeight,
          preserveAspectRatio: preserveAspectRatio,
          cropContentWidth: cropContentWidth, cropContentHeight: cropContentHeight,
          cropX: cropX, cropY: cropY, cropWidth: cropWidth, cropHeight: cropHeight,
          resizeCroppedToWindowSize: resizeCroppedToWindowSize, permissions: permissionHandler)
        result([
          "success": true,
          "imageData": FlutterStandardTypedData(bytes: imageData),
        ])
      } catch let error as CaptureError {
        error.reply(to: result)
      } catch {
        replyUnexpected(error, code: "CAPTURE_FAILED", result)
      }
    }
  }

  /// Gets list of capturable windows using ScreenCaptureKit
  private func getCapturableWindows(result: @escaping FlutterResult) {
    guard #available(macOS 12.3, *) else {
      screenCaptureKitUnavailable.reply(to: result, allowState: false)
      return
    }
    Task {
      do {
        result(try await CaptureHandler.getCapturableWindows(permissions: permissionHandler))
      } catch let error as CaptureError {
        error.reply(to: result, allowState: false)
      } catch {
        replyUnexpected(error, code: "CAPTURE_FAILED", result)
      }
    }
  }

  /// Checks if a window with the specified ID is currently alive/exists
  private func isWindowAlive(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let windowId: Int = required("windowId", of: call, result, "WindowId parameter is required")
    else { return }
    let expectedName = arguments(call)["expectedName"] as? String
    result(windowQuery.isWindowAlive(windowId, expectedName: expectedName))
  }

  /// Closes a window by its window ID using Accessibility API
  private func closeWindow(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let windowId: Int = required("windowId", of: call, result, "WindowId parameter is required")
    else { return }
    let waitUntilClosed = (arguments(call)["waitUntilClosedMs"] as? Int).map { TimeInterval($0) / 1000 }
    windowActions.closeWindow(windowId, waitUntilClosed: waitUntilClosed) { [weak self] closeResult in
      self?.reply(closeResult, result)
    }
  }

  /// Focuses a window by its window ID using Accessibility API
  private func focusWindow(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let windowId: Int = required("windowId", of: call, result, "WindowId parameter is required")
    else { return }
    let waitUntilFocused = (arguments(call)["waitUntilFocusedMs"] as? Int).map { TimeInterval($0) / 1000 }
    windowActions.focusWindow(windowId, waitUntilFocused: waitUntilFocused) { [weak self] focusResult in
      self?.reply(focusResult, result)
    }
  }

  /// Terminates an application by its process ID
  private func terminateApplicationByPID(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let processId: Int = required("processId", of: call, result, "processId is required")
    else { return }
    let force = arguments(call)["force"] as? Bool ?? false
    reply(processTerminator.terminateApplicationByPID(processId, force: force), result)
  }

  /// Terminates an application and all its descendant processes
  private func terminateApplicationTree(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let processId: Int = required("processId", of: call, result, "processId is required")
    else { return }
    let force = arguments(call)["force"] as? Bool ?? false
    reply(processTerminator.terminateApplicationTree(processId, force: force), result)
  }

  /// Gets all child process IDs for a given parent process ID
  private func getChildProcesses(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let processId: Int = required("processId", of: call, result, "processId is required")
    else { return }
    // A PID outside pid_t has no children
    guard let parent = Int32(exactly: processId) else {
      result([Int]())
      return
    }
    switch processTerminator.getChildProcesses(of: parent) {
    case .success(let childPIDs):
      result(childPIDs.map { Int($0) })
    case .failure(let error):
      error.reply(to: result, code: "GET_CHILD_PROCESSES_ERROR", allowState: false)
    }
  }

  /// Gets all installed applications on the system
  private func getAllInstalledApplications(result: @escaping FlutterResult) {
    switch applicationHandler.getAllInstalledApplications() {
    case .success(let applications):
      result(applications)
    case .failure(let error):
      error.reply(to: result, code: "GET_APPLICATIONS_ERROR", allowState: false)
    }
  }

  /// Gets applications filtered by name
  private func getApplicationByName(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let name: String = required("name", of: call, result, "Name parameter is required")
    else { return }
    switch applicationHandler.getApplicationByName(name) {
    case .success(let applications):
      result(applications)
    case .failure(let error):
      error.reply(to: result, code: "GET_APPLICATIONS_ERROR", allowState: false)
    }
  }

  /// Opens Mac App Store with search query
  private func openAppStoreSearch(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let searchTerm: String = required(
        "searchTerm", of: call, result, "searchTerm parameter is required")
    else { return }
    switch applicationHandler.openAppStoreSearch(searchTerm) {
    case .success(let success):
      result(success)
    case .failure(let error):
      error.reply(to: result, allowState: false)
    }
  }

  /// Gets the screen scale factor (backingScaleFactor) of the main screen
  private func getScreenScaleFactor(result: @escaping FlutterResult) {
    result(ScreenInfo.mainScaleFactor())
  }

  /// Gets information about all connected screens
  private func getAllScreensInfo(result: @escaping FlutterResult) {
    result(ScreenInfo.allScreens())
  }

  /// Checks if a window is fullscreen using SCShareableContent
  private func isWindowFullScreen(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let windowId: Int = required("windowId", of: call, result, "WindowId parameter is required")
    else { return }
    guard #available(macOS 12.3, *) else {
      screenCaptureKitUnavailable.reply(to: result)
      return
    }
    Task {
      do {
        result(
          try await CaptureHandler.isWindowFullScreen(
            windowId: windowId, permissions: permissionHandler))
      } catch let error as CaptureError {
        error.reply(to: result)
      } catch {
        replyUnexpected(error, code: "FULLSCREEN_CHECK_FAILED", result)
      }
    }
  }

  /// Gets scroll information for a window by its window ID
  private func getScrollInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let windowId: Int = required("windowId", of: call, result, "WindowId parameter is required")
    else { return }
    switch windowActions.getScrollInfo(windowId) {
    case .success(let scrollInfo):
      result(["success": true, "scrollInfo": scrollInfo])
    case .failure(let error):
      error.reply(to: result)
    }
  }
}
