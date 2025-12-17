import ApplicationServices  // Import for Accessibility API
import Cocoa
import Foundation

/// Handler class responsible for permission-related operations
class PermissionHandler {

    /// Checks if the app has screen recording permission (cached value)
    /// Returns true if permission is granted, false otherwise
    /// Note: This uses a cached value from app launch.
    func hasScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true  // Pre-Catalina doesn't require permission
    }

    /// Requests screen recording permission
    /// Returns true if permission is granted, false otherwise
    /// Note: This will show a system dialog if permission hasn't been requested before
    func requestScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            // CGRequestScreenCaptureAccess must be called on the main queue
            if Thread.isMainThread {
                return CGRequestScreenCaptureAccess()
            } else {
                var result = false
                DispatchQueue.main.sync {
                    result = CGRequestScreenCaptureAccess()
                }
                return result
            }
        }
        return true  // Pre-Catalina doesn't require permission
    }

    /// Opens System Preferences to the Screen Recording section
    /// Returns true if the settings were opened successfully, false otherwise
    func openScreenRecordingSettings() -> Bool {
        // Try opening the specific Screen Recording settings page
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        {
            if NSWorkspace.shared.open(url) {
                return true
            }
        }

        // Fallback: open general Privacy & Security settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            if NSWorkspace.shared.open(url) {
                return true
            }
        }

        // Last resort: open System Preferences
        if let url = URL(string: "x-apple.systempreferences:") {
            return NSWorkspace.shared.open(url)
        }

        return false
    }

    // MARK: - Accessibility Permissions

    /// Checks if the app has accessibility permission
    /// Returns false if permission is not granted
    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Requests accessibility permission (with prompt)
    /// Shows system dialog if permission is not granted and returns current permission status
    func requestAccessibilityPermission() -> Bool {
        // Use kAXTrustedCheckOptionPrompt option to show permission request dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)

        return hasPermission
    }

    /// Opens the Accessibility settings page
    /// Allows user to manually grant permission
    func openAccessibilitySettings() -> Bool {
        // System Preferences URL (works for all macOS versions)
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        {
            if NSWorkspace.shared.open(url) {
                return true
            }
        }

        // Fallback: General Privacy & Security settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            if NSWorkspace.shared.open(url) {
                return true
            }
        }

        // Last resort: System Preferences main page
        if let url = URL(string: "x-apple.systempreferences:") {
            return NSWorkspace.shared.open(url)
        }

        return false
    }
}
