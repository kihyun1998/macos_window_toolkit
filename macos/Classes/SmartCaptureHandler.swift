import Cocoa
import Foundation
import ScreenCaptureKit

/// Smart capture handler that automatically selects the best capture method based on macOS version
class SmartCaptureHandler {

    enum SmartCaptureError: Error {
        case noCompatibleCaptureMethod
        case captureMethodFailed(String)
        case invalidWindowId
        case windowMinimized
    }

    /// Automatically captures a window using the best available method
    /// - Uses ScreenCaptureKit on macOS 14.0+ for best quality
    /// - Falls back to CGWindowListCreateImage on older versions
    static func captureWindowAuto(
        windowId: Int, excludeTitlebar: Bool = false, customTitlebarHeight: CGFloat? = nil
    ) async throws -> Data {
        if shouldUseScreenCaptureKit() {
            if #available(macOS 12.3, *) {
                do {
                    // Try ScreenCaptureKit first
                    return try await CaptureHandler.captureWindow(
                        windowId: windowId, excludeTitlebar: excludeTitlebar,
                        customTitlebarHeight: customTitlebarHeight)
                } catch let error as CaptureHandler.CaptureError {
                    // Re-throw minimized window error without fallback
                    if case .windowMinimized = error {
                        throw SmartCaptureError.windowMinimized
                    }
                    // For other ScreenCaptureKit errors, fall back to legacy method
                    return try LegacyCaptureHandler.captureWindow(
                        windowId: windowId, excludeTitlebar: excludeTitlebar,
                        customTitlebarHeight: customTitlebarHeight)
                } catch {
                    // For unknown errors, fall back to legacy method
                    return try LegacyCaptureHandler.captureWindow(
                        windowId: windowId, excludeTitlebar: excludeTitlebar,
                        customTitlebarHeight: customTitlebarHeight)
                }
            } else {
                // This shouldn't happen as shouldUseScreenCaptureKit() checks version
                return try LegacyCaptureHandler.captureWindow(
                    windowId: windowId, excludeTitlebar: excludeTitlebar,
                    customTitlebarHeight: customTitlebarHeight)
            }
        } else {
            // Use legacy method for older macOS versions
            return try LegacyCaptureHandler.captureWindow(
                windowId: windowId, excludeTitlebar: excludeTitlebar,
                customTitlebarHeight: customTitlebarHeight)
        }
    }

    /// Automatically gets capturable windows using the best available method
    /// - Uses ScreenCaptureKit on macOS 12.3+ for better window information
    /// - Falls back to CGWindowListCreateImage on older versions
    static func getCapturableWindowsAuto() async throws -> [[String: Any]] {
        if shouldUseScreenCaptureKitForWindowList() {
            if #available(macOS 12.3, *) {
                do {
                    // Try ScreenCaptureKit first
                    return try await CaptureHandler.getCapturableWindows()
                } catch {
                    // If ScreenCaptureKit fails, fall back to legacy method
                    return LegacyCaptureHandler.getCapturableWindows()
                }
            } else {
                // This shouldn't happen as shouldUseScreenCaptureKitForWindowList() checks version
                return LegacyCaptureHandler.getCapturableWindows()
            }
        } else {
            // Use legacy method for older macOS versions
            return LegacyCaptureHandler.getCapturableWindows()
        }
    }

    /// Determines if ScreenCaptureKit should be used for window capture
    /// - Returns true only if macOS 14.0+ (for SCScreenshotManager)
    private static func shouldUseScreenCaptureKit() -> Bool {
        if #available(macOS 14.0, *) {
            return VersionUtil.isScreenCaptureKitAvailable()
        }
        return false
    }

    /// Determines if ScreenCaptureKit should be used for window listing
    /// - Returns true if macOS 12.3+ (for SCShareableContent)
    private static func shouldUseScreenCaptureKitForWindowList() -> Bool {
        if #available(macOS 12.3, *) {
            return VersionUtil.isScreenCaptureKitAvailable()
        }
        return false
    }

    /// Gets information about the capture method that would be used
    static func getCaptureMethodInfo() -> [String: Any] {
        let useScreenCaptureKitForCapture = shouldUseScreenCaptureKit()
        let useScreenCaptureKitForList = shouldUseScreenCaptureKitForWindowList()

        return [
            "captureMethod": useScreenCaptureKitForCapture
                ? "ScreenCaptureKit" : "CGWindowListCreateImage",
            "windowListMethod": useScreenCaptureKitForList
                ? "ScreenCaptureKit" : "CGWindowListCopyWindowInfo",
            "macOSVersion": VersionUtil.getMacOSVersion(),
            "isScreenCaptureKitAvailable": VersionUtil.isScreenCaptureKitAvailable(),
            "supportsModernCapture": useScreenCaptureKitForCapture,
            "supportsModernWindowList": useScreenCaptureKitForList,
        ]
    }

    /// Handles SmartCaptureError and converts to Flutter-compatible format
    static func handleSmartCaptureError(_ error: SmartCaptureError) -> [String: Any] {
        switch error {
        case .noCompatibleCaptureMethod:
            return [
                "code": "NO_COMPATIBLE_CAPTURE_METHOD",
                "message": "No compatible capture method available",
                "details": "Unable to use either ScreenCaptureKit or CGWindowListCreateImage",
            ]
        case .captureMethodFailed(let description):
            return [
                "code": "CAPTURE_METHOD_FAILED",
                "message": "Capture method failed",
                "details": description,
            ]
        case .invalidWindowId:
            return [
                "code": "INVALID_WINDOW_ID",
                "message": "Window with the specified ID was not found",
                "details": NSNull(),
            ]
        case .windowMinimized:
            return [
                "code": "WINDOW_MINIMIZED",
                "message": "Window is minimized and cannot be captured",
                "details":
                    "The window is currently minimized. Please restore the window to capture it.",
            ]
        }
    }
}
