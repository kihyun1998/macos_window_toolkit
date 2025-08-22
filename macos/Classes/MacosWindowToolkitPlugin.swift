import Cocoa
import FlutterMacOS

public class MacosWindowToolkitPlugin: NSObject, FlutterPlugin {
  private let windowHandler = WindowHandler()

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
    case "hasScreenRecordingPermission":
      hasScreenRecordingPermission(result: result)
    case "requestScreenRecordingPermission":
      requestScreenRecordingPermission(result: result)
    case "openScreenRecordingSettings":
      openScreenRecordingSettings(result: result)
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
    let hasPermission = windowHandler.hasScreenRecordingPermission()
    result(hasPermission)
  }

  /// Requests screen recording permission
  private func requestScreenRecordingPermission(result: @escaping FlutterResult) {
    let granted = windowHandler.requestScreenRecordingPermission()
    result(granted)
  }

  /// Opens screen recording settings in System Preferences
  private func openScreenRecordingSettings(result: @escaping FlutterResult) {
    let success = windowHandler.openScreenRecordingSettings()
    result(success)
  }
}
