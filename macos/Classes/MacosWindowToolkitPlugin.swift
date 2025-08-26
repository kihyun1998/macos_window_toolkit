import Cocoa
import FlutterMacOS

public class MacosWindowToolkitPlugin: NSObject, FlutterPlugin {
  private let windowHandler = WindowHandler()
  private let permissionHandler = PermissionHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "macos_window_toolkit", binaryMessenger: registrar.messenger)
    let instance = MacosWindowToolkitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    case "captureWindowLegacy":
      captureWindowLegacy(call: call, result: result)
    case "getCapturableWindowsLegacy":
      getCapturableWindowsLegacy(result: result)
    case "captureWindowAuto":
      captureWindowAuto(call: call, result: result)
    case "getCapturableWindowsAuto":
      getCapturableWindowsAuto(result: result)
    case "getCaptureMethodInfo":
      getCaptureMethodInfo(result: result)
    case "isWindowAlive":
      isWindowAlive(call: call, result: result)
    case "closeWindow":
      closeWindow(call: call, result: result)
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Retrieves information about all windows currently open on the system
  private func getAllWindows(result: @escaping FlutterResult) {
    getAllWindows(
      call: FlutterMethodCall(methodName: "getAllWindows", arguments: nil), result: result)
  }

  /// Retrieves information about all windows with optional parameters
  private func getAllWindows(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let excludeEmptyNames: Bool
    if let arguments = call.arguments as? [String: Any] {
      excludeEmptyNames = arguments["excludeEmptyNames"] as? Bool ?? false
    } else {
      excludeEmptyNames = false
    }

    let windowResult = windowHandler.getAllWindows(excludeEmptyNames: excludeEmptyNames)

    switch windowResult {
    case .success(let windows):
      result(windows)
    case .failure(let error):
      result(
        FlutterError(
          code: "WINDOW_LIST_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Checks if the app has screen recording permission
  private func hasScreenRecordingPermission(result: @escaping FlutterResult) {
    let hasPermission = permissionHandler.hasScreenRecordingPermission()
    result(hasPermission)
  }

  /// Requests screen recording permission
  private func requestScreenRecordingPermission(result: @escaping FlutterResult) {
    let granted = permissionHandler.requestScreenRecordingPermission()
    result(granted)
  }

  /// Opens screen recording settings in System Preferences
  private func openScreenRecordingSettings(result: @escaping FlutterResult) {
    let success = permissionHandler.openScreenRecordingSettings()
    result(success)
  }

  /// Checks if the app has accessibility permission
  private func hasAccessibilityPermission(result: @escaping FlutterResult) {
    let hasPermission = permissionHandler.hasAccessibilityPermission()
    result(hasPermission)
  }

  /// Requests accessibility permission
  private func requestAccessibilityPermission(result: @escaping FlutterResult) {
    let granted = permissionHandler.requestAccessibilityPermission()
    result(granted)
  }

  /// Opens accessibility settings in System Preferences
  private func openAccessibilitySettings(result: @escaping FlutterResult) {
    let success = permissionHandler.openAccessibilitySettings()
    result(success)
  }

  /// Retrieves windows filtered by name (window title)
  private func getWindowsByName(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let name = arguments["name"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Name parameter is required",
          details: nil))
      return
    }

    let windowResult = windowHandler.getWindowsByName(name)
    handleWindowResult(windowResult, result: result)
  }

  /// Retrieves windows filtered by owner name (application name)
  private func getWindowsByOwnerName(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let ownerName = arguments["ownerName"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "OwnerName parameter is required",
          details: nil))
      return
    }

    let windowResult = windowHandler.getWindowsByOwnerName(ownerName)
    handleWindowResult(windowResult, result: result)
  }

  /// Retrieves a specific window by its window ID
  private func getWindowById(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let windowId = arguments["windowId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "WindowId parameter is required",
          details: nil))
      return
    }

    let windowResult = windowHandler.getWindowById(windowId)
    handleWindowResult(windowResult, result: result)
  }

  /// Retrieves windows filtered by process ID
  private func getWindowsByProcessId(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let processId = arguments["processId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "ProcessId parameter is required",
          details: nil))
      return
    }

    let windowResult = windowHandler.getWindowsByProcessId(processId)
    handleWindowResult(windowResult, result: result)
  }

  /// Gets macOS version information
  private func getMacOSVersionInfo(result: @escaping FlutterResult) {
    let versionInfo = VersionUtil.getMacOSVersionInfo()
    result(versionInfo)
  }

  /// Captures a window using ScreenCaptureKit
  private func captureWindow(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let windowId = arguments["windowId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "WindowId parameter is required",
          details: nil))
      return
    }

    let excludeTitlebar = arguments["excludeTitlebar"] as? Bool ?? false
    let customTitlebarHeight = arguments["customTitlebarHeight"] as? CGFloat

    if #available(macOS 12.3, *) {
      Task {
        do {
          let imageData = try await CaptureHandler.captureWindow(
            windowId: windowId, excludeTitlebar: excludeTitlebar,
            customTitlebarHeight: customTitlebarHeight)
          result(FlutterStandardTypedData(bytes: imageData))
        } catch let error as CaptureHandler.CaptureError {
          let errorInfo = CaptureHandler.handleCaptureError(error)
          result(
            FlutterError(
              code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
              message: errorInfo["message"] as? String ?? "Unknown error",
              details: errorInfo["details"]))
        } catch {
          result(
            FlutterError(
              code: "CAPTURE_FAILED",
              message: "Unexpected error occurred",
              details: error.localizedDescription))
        }
      }
    } else {
      result(
        FlutterError(
          code: "UNSUPPORTED_MACOS_VERSION",
          message: "macOS version does not support ScreenCaptureKit",
          details:
            "Current version: \(ProcessInfo.processInfo.operatingSystemVersionString), Required: 12.3+"
        ))
    }
  }

  /// Gets list of capturable windows using ScreenCaptureKit
  private func getCapturableWindows(result: @escaping FlutterResult) {
    if #available(macOS 12.3, *) {
      Task {
        do {
          let windows = try await CaptureHandler.getCapturableWindows()
          result(windows)
        } catch let error as CaptureHandler.CaptureError {
          let errorInfo = CaptureHandler.handleCaptureError(error)
          result(
            FlutterError(
              code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
              message: errorInfo["message"] as? String ?? "Unknown error",
              details: errorInfo["details"]))
        } catch {
          result(
            FlutterError(
              code: "CAPTURE_FAILED",
              message: "Unexpected error occurred",
              details: error.localizedDescription))
        }
      }
    } else {
      result(
        FlutterError(
          code: "UNSUPPORTED_MACOS_VERSION",
          message: "macOS version does not support ScreenCaptureKit",
          details:
            "Current version: \(ProcessInfo.processInfo.operatingSystemVersionString), Required: 12.3+"
        ))
    }
  }

  /// Captures a window using CGWindowListCreateImage (legacy method)
  private func captureWindowLegacy(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let windowId = arguments["windowId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "WindowId parameter is required",
          details: nil))
      return
    }

    let excludeTitlebar = arguments["excludeTitlebar"] as? Bool ?? false
    let customTitlebarHeight = arguments["customTitlebarHeight"] as? CGFloat

    do {
      let imageData = try LegacyCaptureHandler.captureWindow(
        windowId: windowId, excludeTitlebar: excludeTitlebar,
        customTitlebarHeight: customTitlebarHeight)
      result(FlutterStandardTypedData(bytes: imageData))
    } catch let error as LegacyCaptureHandler.LegacyCaptureError {
      let errorInfo = LegacyCaptureHandler.handleLegacyCaptureError(error)
      result(
        FlutterError(
          code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
          message: errorInfo["message"] as? String ?? "Unknown error",
          details: errorInfo["details"]))
    } catch {
      result(
        FlutterError(
          code: "CAPTURE_FAILED",
          message: "Unexpected error occurred",
          details: error.localizedDescription))
    }
  }

  /// Gets list of capturable windows using CGWindowListCopyWindowInfo (legacy method)
  private func getCapturableWindowsLegacy(result: @escaping FlutterResult) {
    let windows = LegacyCaptureHandler.getCapturableWindows()
    result(windows)
  }

  /// Captures a window using the best available method (auto-selection)
  private func captureWindowAuto(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let windowId = arguments["windowId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "WindowId parameter is required",
          details: nil))
      return
    }

    let excludeTitlebar = arguments["excludeTitlebar"] as? Bool ?? false

    if #available(macOS 10.15, *) {
      Task {
        do {
          let imageData = try await SmartCaptureHandler.captureWindowAuto(
            windowId: windowId, excludeTitlebar: excludeTitlebar)
          result(FlutterStandardTypedData(bytes: imageData))
        } catch let error as SmartCaptureHandler.SmartCaptureError {
          let errorInfo = SmartCaptureHandler.handleSmartCaptureError(error)
          result(
            FlutterError(
              code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
              message: errorInfo["message"] as? String ?? "Unknown error",
              details: errorInfo["details"]))
        } catch {
          result(
            FlutterError(
              code: "CAPTURE_FAILED",
              message: "Unexpected error occurred",
              details: error.localizedDescription))
        }
      }
    } else {
      // For macOS < 10.15, use legacy capture directly (no async support)
      do {
        let imageData = try LegacyCaptureHandler.captureWindow(
          windowId: windowId, excludeTitlebar: excludeTitlebar)
        result(FlutterStandardTypedData(bytes: imageData))
      } catch let error as LegacyCaptureHandler.LegacyCaptureError {
        let errorInfo = LegacyCaptureHandler.handleLegacyCaptureError(error)
        result(
          FlutterError(
            code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
      } catch {
        result(
          FlutterError(
            code: "CAPTURE_FAILED",
            message: "Unexpected error occurred",
            details: error.localizedDescription))
      }
    }
  }

  /// Gets list of capturable windows using the best available method (auto-selection)
  private func getCapturableWindowsAuto(result: @escaping FlutterResult) {
    if #available(macOS 10.15, *) {
      Task {
        do {
          let windows = try await SmartCaptureHandler.getCapturableWindowsAuto()
          result(windows)
        } catch let error as SmartCaptureHandler.SmartCaptureError {
          let errorInfo = SmartCaptureHandler.handleSmartCaptureError(error)
          result(
            FlutterError(
              code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
              message: errorInfo["message"] as? String ?? "Unknown error",
              details: errorInfo["details"]))
        } catch {
          result(
            FlutterError(
              code: "CAPTURE_FAILED",
              message: "Unexpected error occurred",
              details: error.localizedDescription))
        }
      }
    } else {
      // For macOS < 10.15, use legacy method directly
      let windows = LegacyCaptureHandler.getCapturableWindows()
      result(windows)
    }
  }

  /// Gets information about the capture method that would be used
  private func getCaptureMethodInfo(result: @escaping FlutterResult) {
    let methodInfo = SmartCaptureHandler.getCaptureMethodInfo()
    result(methodInfo)
  }

  /// Checks if a window with the specified ID is currently alive/exists
  private func isWindowAlive(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let windowId = arguments["windowId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "WindowId parameter is required",
          details: nil))
      return
    }

    let isAlive = windowHandler.isWindowAlive(windowId)
    result(isAlive)
  }

  /// Closes a window by its window ID using AppleScript
  private func closeWindow(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let windowId = arguments["windowId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "WindowId parameter is required",
          details: nil))
      return
    }

    let closeResult = windowHandler.closeWindow(windowId)
    switch closeResult {
    case .success(let success):
      result(success)
    case .failure(let error):
      result(
        FlutterError(
          code: "CLOSE_WINDOW_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Terminates an application by its process ID
  private func terminateApplicationByPID(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let processId = args["processId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "processId is required",
          details: nil))
      return
    }

    let force = args["force"] as? Bool ?? false

    let terminateResult = windowHandler.terminateApplicationByPID(processId, force: force)
    switch terminateResult {
    case .success(let success):
      result(success)
    case .failure(let error):
      result(
        FlutterError(
          code: "TERMINATE_APP_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Terminates an application and all its child processes
  private func terminateApplicationTree(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let processId = args["processId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "processId is required",
          details: nil))
      return
    }

    let force = args["force"] as? Bool ?? false

    let terminateResult = windowHandler.terminateApplicationTree(processId, force: force)
    switch terminateResult {
    case .success(let success):
      result(success)
    case .failure(let error):
      result(
        FlutterError(
          code: "TERMINATE_TREE_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Gets all child process IDs for a given parent process ID
  private func getChildProcesses(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let processId = args["processId"] as? Int
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "processId is required",
          details: nil))
      return
    }

    let childResult = windowHandler.getChildProcesses(of: Int32(processId))
    switch childResult {
    case .success(let childPIDs):
      result(childPIDs.map { Int($0) })
    case .failure(let error):
      result(
        FlutterError(
          code: "GET_CHILD_PROCESSES_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Helper method to handle window operation results
  private func handleWindowResult(
    _ windowResult: Result<[[String: Any]], WindowError>, result: @escaping FlutterResult
  ) {
    switch windowResult {
    case .success(let windows):
      result(windows)
    case .failure(let error):
      result(
        FlutterError(
          code: "WINDOW_LIST_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }
}
