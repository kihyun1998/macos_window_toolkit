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
      getAllWindows(result: result)
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Retrieves information about all windows currently open on the system
  private func getAllWindows(result: @escaping FlutterResult) {
    let windowResult = windowHandler.getAllWindows()

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

  /// Retrieves windows filtered by name (window title)
  private func getWindowsByName(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let name = arguments["name"] as? String else {
      result(FlutterError(
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
          let ownerName = arguments["ownerName"] as? String else {
      result(FlutterError(
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
          let windowId = arguments["windowId"] as? Int else {
      result(FlutterError(
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
          let processId = arguments["processId"] as? Int else {
      result(FlutterError(
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
          let windowId = arguments["windowId"] as? Int else {
      result(FlutterError(
        code: "INVALID_ARGUMENTS",
        message: "WindowId parameter is required",
        details: nil))
      return
    }

    if #available(macOS 12.3, *) {
      Task {
        do {
          let imageData = try await CaptureHandler.captureWindow(windowId: windowId)
          result(FlutterStandardTypedData(bytes: imageData))
        } catch let error as CaptureHandler.CaptureError {
          let errorInfo = CaptureHandler.handleCaptureError(error)
          result(FlutterError(
            code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
        } catch {
          result(FlutterError(
            code: "CAPTURE_FAILED",
            message: "Unexpected error occurred",
            details: error.localizedDescription))
        }
      }
    } else {
      result(FlutterError(
        code: "UNSUPPORTED_MACOS_VERSION",
        message: "macOS version does not support ScreenCaptureKit",
        details: "Current version: \(ProcessInfo.processInfo.operatingSystemVersionString), Required: 12.3+"))
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
          result(FlutterError(
            code: errorInfo["code"] as? String ?? "CAPTURE_FAILED",
            message: errorInfo["message"] as? String ?? "Unknown error",
            details: errorInfo["details"]))
        } catch {
          result(FlutterError(
            code: "CAPTURE_FAILED",
            message: "Unexpected error occurred",
            details: error.localizedDescription))
        }
      }
    } else {
      result(FlutterError(
        code: "UNSUPPORTED_MACOS_VERSION",
        message: "macOS version does not support ScreenCaptureKit",
        details: "Current version: \(ProcessInfo.processInfo.operatingSystemVersionString), Required: 12.3+"))
    }
  }

  /// Helper method to handle window operation results
  private func handleWindowResult(_ windowResult: Result<[[String: Any]], WindowError>, result: @escaping FlutterResult) {
    switch windowResult {
    case .success(let windows):
      result(windows)
    case .failure(let error):
      result(FlutterError(
        code: "WINDOW_LIST_ERROR",
        message: error.localizedDescription,
        details: nil))
    }
  }
}
