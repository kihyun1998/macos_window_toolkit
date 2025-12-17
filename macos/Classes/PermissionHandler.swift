import ApplicationServices  // Import for Accessibility API
import Cocoa
import Foundation
import ScreenCaptureKit  // Import for ScreenCaptureKit API (macOS 12.3+)

/// Handler class responsible for permission-related operations
class PermissionHandler {

    /// Checks if the app has screen recording permission (cached value)
    /// Returns true if permission is granted, false otherwise
    /// Note: This uses a cached value from app launch. For runtime permission changes,
    /// use hasActualScreenRecordingPermission() or rely on capture attempt failures.
    func hasScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true  // Pre-Catalina doesn't require permission
    }

    /// Checks actual screen recording permission by attempting a real capture
    /// This is more accurate than CGPreflightScreenCaptureAccess() for detecting runtime permission changes
    /// Returns true if permission is actually granted and working
    @available(macOS 10.15, *)
    func hasActualScreenRecordingPermission() -> Bool {
        // On macOS 14.0+, prefer ScreenCaptureKit for permission check
        if #available(macOS 14.0, *) {
            // Use ScreenCaptureKit synchronously via semaphore
            let semaphore = DispatchSemaphore(value: 0)
            var hasPermission = false

            Task {
                do {
                    let content = try await SCShareableContent.current
                    hasPermission = !content.displays.isEmpty || !content.windows.isEmpty
                } catch {
                    hasPermission = false
                }
                semaphore.signal()
            }

            semaphore.wait()
            return hasPermission
        } else {
            // For macOS 10.15 - 13.x, use legacy method
            // CGWindowListCreateImage is deprecated in 14.0 but still works
            let testImage = CGWindowListCreateImage(
                CGRect(x: 0, y: 0, width: 1, height: 1),
                .optionOnScreenOnly,
                kCGNullWindowID,
                .nominalResolution
            )

            // If we can create an image with valid dimensions, permission is granted
            if let image = testImage, image.width > 0, image.height > 0 {
                return true
            }

            return false
        }
    }

    /// Async version that works with ScreenCaptureKit (macOS 12.3+)
    /// Most accurate way to check permission as it uses the modern API
    @available(macOS 12.3, *)
    func hasActualScreenRecordingPermissionAsync() async -> Bool {
        do {
            // Try to get shareable content - this will fail if permission is denied
            let content = try await SCShareableContent.current
            // If we can get content with displays or windows, permission is granted
            return !content.displays.isEmpty || !content.windows.isEmpty
        } catch {
            return false
        }
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
