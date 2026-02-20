import Cocoa
import FlutterMacOS

public class MacosWindowToolkitPlugin: NSObject, FlutterPlugin {
  private let windowHandler = WindowHandler()
  private let permissionHandler = PermissionHandler()
  private let applicationHandler = ApplicationHandler()

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

  /// Retrieves windows with advanced filtering options
  /// All filter parameters are optional - nil values are ignored
  private func getWindowsAdvanced(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]

    let windowId = arguments["windowId"] as? Int
    let name = arguments["name"] as? String
    let nameExactMatch = arguments["nameExactMatch"] as? Bool
    let nameCaseSensitive = arguments["nameCaseSensitive"] as? Bool
    let nameWildcard = arguments["nameWildcard"] as? Bool
    let ownerName = arguments["ownerName"] as? String
    let ownerNameExactMatch = arguments["ownerNameExactMatch"] as? Bool
    let ownerNameCaseSensitive = arguments["ownerNameCaseSensitive"] as? Bool
    let ownerNameWildcard = arguments["ownerNameWildcard"] as? Bool
    let processId = arguments["processId"] as? Int
    let isOnScreen = arguments["isOnScreen"] as? Bool
    let layer = arguments["layer"] as? Int
    let x = arguments["x"] as? Double
    let y = arguments["y"] as? Double
    let width = arguments["width"] as? Double
    let height = arguments["height"] as? Double

    let windowResult = windowHandler.getWindowsAdvanced(
      windowId: windowId,
      name: name,
      nameExactMatch: nameExactMatch,
      nameCaseSensitive: nameCaseSensitive,
      nameWildcard: nameWildcard,
      ownerName: ownerName,
      ownerNameExactMatch: ownerNameExactMatch,
      ownerNameCaseSensitive: ownerNameCaseSensitive,
      ownerNameWildcard: ownerNameWildcard,
      processId: processId,
      isOnScreen: isOnScreen,
      layer: layer,
      x: x,
      y: y,
      width: width,
      height: height
    )
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
    let targetWidth = arguments["targetWidth"] as? Int
    let targetHeight = arguments["targetHeight"] as? Int
    let preserveAspectRatio = arguments["preserveAspectRatio"] as? Bool ?? false
    let cropContentWidth = arguments["cropContentWidth"] as? Int
    let cropContentHeight = arguments["cropContentHeight"] as? Int
    let cropX = arguments["cropX"] as? Int
    let cropY = arguments["cropY"] as? Int
    let cropWidth = arguments["cropWidth"] as? Int
    let cropHeight = arguments["cropHeight"] as? Int

    if #available(macOS 12.3, *) {
      Task {
        do {
          let imageData = try await CaptureHandler.captureWindow(
            windowId: windowId, excludeTitlebar: excludeTitlebar,
            customTitlebarHeight: customTitlebarHeight,
            targetWidth: targetWidth, targetHeight: targetHeight,
            preserveAspectRatio: preserveAspectRatio,
            cropContentWidth: cropContentWidth, cropContentHeight: cropContentHeight,
            cropX: cropX, cropY: cropY, cropWidth: cropWidth, cropHeight: cropHeight)

          // Return success result
          result([
            "success": true,
            "imageData": FlutterStandardTypedData(bytes: imageData),
          ])
        } catch let error as CaptureHandler.CaptureError {
          let errorInfo = CaptureHandler.handleCaptureError(error)

          // Check if this is a state or a system error
          if let code = errorInfo["code"] as? String, isStateError(code) {
            // Return failure result for states
            result([
              "success": false,
              "reason": mapErrorCodeToReasonCode(code),
              "message": errorInfo["message"],
              "details": errorInfo["details"],
              "errorCode": errorInfo["errorCode"],
              "errorDomain": errorInfo["errorDomain"],
            ])
          } else {
            // Throw for system errors
            result(
              FlutterError(
                code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
                message: errorInfo["message"] as? String ?? "Unknown error",
                details: errorInfo))
          }
        } catch {
          result(
            FlutterError(
              code: "CAPTURE_FAILED",
              message: "Unexpected error occurred",
              details: error.localizedDescription))
        }
      }
    } else {
      // Unsupported version is a state, not a system error
      result([
        "success": false,
        "reason": "unsupported_version",
        "message": "macOS version does not support ScreenCaptureKit",
        "details":
          "Current version: \(ProcessInfo.processInfo.operatingSystemVersionString), Required: 12.3+",
      ])
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
              details: errorInfo))
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

    let expectedName = arguments["expectedName"] as? String
    let isAlive = windowHandler.isWindowAlive(windowId, expectedName: expectedName)
    result(isAlive)
  }

  /// Closes a window by its window ID using Accessibility API
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
      let errorInfo = WindowHandler.handleWindowError(error)

      // Check if this is a state or a system error
      if let code = errorInfo["code"] as? String, isStateError(code) {
        // Return failure result for states
        result([
          "success": false,
          "reason": mapErrorCodeToReasonCode(code),
          "message": errorInfo["message"],
          "details": errorInfo["details"],
        ])
      } else {
        // Throw for system errors
        result(
          FlutterError(
            code: errorInfo["code"] as? String ?? "CLOSE_WINDOW_ERROR",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
      }
    }
  }

  /// Focuses a window by its window ID using Accessibility API
  private func focusWindow(call: FlutterMethodCall, result: @escaping FlutterResult) {
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

    let focusResult = windowHandler.focusWindow(windowId)
    switch focusResult {
    case .success(let success):
      result(success)
    case .failure(let error):
      let errorInfo = WindowHandler.handleWindowError(error)

      // Check if this is a state or a system error
      if let code = errorInfo["code"] as? String, isStateError(code) {
        // Return failure result for states
        result([
          "success": false,
          "reason": mapErrorCodeToReasonCode(code),
          "message": errorInfo["message"],
          "details": errorInfo["details"],
        ])
      } else {
        // Throw for system errors
        result(
          FlutterError(
            code: errorInfo["code"] as? String ?? "FOCUS_WINDOW_ERROR",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
      }
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
      let errorInfo = WindowHandler.handleWindowError(error)

      // Check if this is a state or a system error
      if let code = errorInfo["code"] as? String, isStateError(code) {
        // Return failure result for states
        result([
          "success": false,
          "reason": mapErrorCodeToReasonCode(code),
          "message": errorInfo["message"],
          "details": errorInfo["details"],
        ])
      } else {
        // Throw for system errors
        result(
          FlutterError(
            code: errorInfo["code"] as? String ?? "TERMINATE_APP_ERROR",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
      }
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
      let errorInfo = WindowHandler.handleWindowError(error)

      // Check if this is a state or a system error
      if let code = errorInfo["code"] as? String, isStateError(code) {
        // Return failure result for states
        result([
          "success": false,
          "reason": mapErrorCodeToReasonCode(code),
          "message": errorInfo["message"],
          "details": errorInfo["details"],
        ])
      } else {
        // Throw for system errors
        result(
          FlutterError(
            code: errorInfo["code"] as? String ?? "TERMINATE_TREE_ERROR",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
      }
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

  /// Gets all installed applications on the system
  private func getAllInstalledApplications(result: @escaping FlutterResult) {
    let appsResult = applicationHandler.getAllInstalledApplications()
    switch appsResult {
    case .success(let applications):
      result(applications)
    case .failure(let error):
      result(
        FlutterError(
          code: "GET_APPLICATIONS_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Gets applications filtered by name
  private func getApplicationByName(call: FlutterMethodCall, result: @escaping FlutterResult) {
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

    let appsResult = applicationHandler.getApplicationByName(name)
    switch appsResult {
    case .success(let applications):
      result(applications)
    case .failure(let error):
      result(
        FlutterError(
          code: "GET_APPLICATIONS_ERROR",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Opens Mac App Store with search query
  private func openAppStoreSearch(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
      let searchTerm = arguments["searchTerm"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "searchTerm parameter is required",
          details: nil))
      return
    }

    let searchResult = applicationHandler.openAppStoreSearch(searchTerm)
    switch searchResult {
    case .success(let success):
      result(success)
    case .failure(let error):
      result(
        FlutterError(
          code: "OPEN_APP_STORE_ERROR",
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

  /// Determines if an error code represents a state (not a system error)
  private func isStateError(_ code: String) -> Bool {
    switch code {
    // Screenshot/Capture related state errors
    case "WINDOW_MINIMIZED",
      "INVALID_WINDOW_ID",
      "WINDOW_NOT_FOUND",
      "UNSUPPORTED_MACOS_VERSION",
      "PERMISSION_DENIED",
      "SCREEN_RECORDING_PERMISSION_DENIED",
      "CAPTURE_IN_PROGRESS",
      "WINDOW_NOT_CAPTURABLE",
      // Window operation related state errors
      "ACCESSIBILITY_PERMISSION_DENIED",
      "CLOSE_BUTTON_NOT_FOUND",
      "FOCUS_ACTION_FAILED",
      "PROCESS_NOT_FOUND":
      return true
    default:
      return false
    }
  }

  /// Maps error codes to reason codes for Dart
  private func mapErrorCodeToReasonCode(_ code: String) -> String {
    switch code {
    // Screenshot/Capture related errors
    case "WINDOW_MINIMIZED":
      return "window_minimized"
    case "INVALID_WINDOW_ID", "WINDOW_NOT_FOUND":
      return "window_not_found"
    case "UNSUPPORTED_MACOS_VERSION":
      return "unsupported_version"
    case "PERMISSION_DENIED", "SCREEN_RECORDING_PERMISSION_DENIED":
      return "permission_denied"
    case "CAPTURE_IN_PROGRESS":
      return "capture_in_progress"
    case "WINDOW_NOT_CAPTURABLE":
      return "window_not_capturable"
    // Window operation related errors
    case "ACCESSIBILITY_PERMISSION_DENIED":
      return "accessibility_permission_denied"
    case "CLOSE_BUTTON_NOT_FOUND":
      return "close_button_not_found"
    case "FOCUS_ACTION_FAILED":
      return "focus_action_failed"
    case "PROCESS_NOT_FOUND":
      return "process_not_found"
    default:
      return "unknown"
    }
  }

  /// Gets the screen scale factor (backingScaleFactor) of the main screen
  private func getScreenScaleFactor(result: @escaping FlutterResult) {
    let scaleFactor = NSScreen.main?.backingScaleFactor ?? 1.0
    result(scaleFactor)
  }

  /// Gets information about all connected screens
  private func getAllScreensInfo(result: @escaping FlutterResult) {
    let screens = NSScreen.screens.enumerated().map { (index, screen) -> [String: Any] in
      let isMain = (screen == NSScreen.main)
      return [
        "index": index,
        "isMain": isMain,
        "scaleFactor": screen.backingScaleFactor,
        "frame": [
          "x": screen.frame.origin.x,
          "y": screen.frame.origin.y,
          "width": screen.frame.width,
          "height": screen.frame.height,
        ],
        "visibleFrame": [
          "x": screen.visibleFrame.origin.x,
          "y": screen.visibleFrame.origin.y,
          "width": screen.visibleFrame.width,
          "height": screen.visibleFrame.height,
        ],
        "pixelWidth": Int(screen.frame.width * screen.backingScaleFactor),
        "pixelHeight": Int(screen.frame.height * screen.backingScaleFactor),
      ]
    }
    result(screens)
  }

  /// Checks if a window is fullscreen using SCShareableContent
  private func isWindowFullScreen(call: FlutterMethodCall, result: @escaping FlutterResult) {
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

    if #available(macOS 12.3, *) {
      Task {
        do {
          let isFullScreen = try await CaptureHandler.isWindowFullScreen(windowId: windowId)
          result(isFullScreen)
        } catch let error as CaptureHandler.CaptureError {
          let errorInfo = CaptureHandler.handleCaptureError(error)

          if let code = errorInfo["code"] as? String, isStateError(code) {
            result([
              "success": false,
              "reason": mapErrorCodeToReasonCode(code),
              "message": errorInfo["message"],
              "details": errorInfo["details"],
            ])
          } else {
            result(
              FlutterError(
                code: errorInfo["code"] as? String ?? "FULLSCREEN_CHECK_FAILED",
                message: errorInfo["message"] as? String ?? "Unknown error",
                details: errorInfo))
          }
        } catch {
          result(
            FlutterError(
              code: "FULLSCREEN_CHECK_FAILED",
              message: "Unexpected error occurred",
              details: error.localizedDescription))
        }
      }
    } else {
      result([
        "success": false,
        "reason": "unsupported_version",
        "message": "macOS version does not support ScreenCaptureKit",
        "details":
          "Current version: \(ProcessInfo.processInfo.operatingSystemVersionString), Required: 12.3+",
      ])
    }
  }

  /// Gets scroll information for a window by its window ID
  private func getScrollInfo(call: FlutterMethodCall, result: @escaping FlutterResult) {
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

    let scrollResult = windowHandler.getScrollInfo(windowId)
    switch scrollResult {
    case .success(let scrollInfo):
      result([
        "success": true,
        "scrollInfo": scrollInfo
      ])
    case .failure(let error):
      let errorInfo = WindowHandler.handleWindowError(error)

      // Check if this is a state or a system error
      if let code = errorInfo["code"] as? String, isStateError(code) {
        // Return failure result for states
        result([
          "success": false,
          "reason": mapErrorCodeToReasonCode(code),
          "message": errorInfo["message"],
          "details": errorInfo["details"],
        ])
      } else {
        // Throw for system errors
        result(
          FlutterError(
            code: errorInfo["code"] as? String ?? "GET_SCROLL_INFO_ERROR",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
      }
    }
  }
}
