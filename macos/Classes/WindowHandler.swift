import Cocoa
import Foundation

/// Handler class responsible for window-related operations
class WindowHandler {
    
    /// Checks if the app has screen recording permission
    /// Returns true if permission is granted, false otherwise
    func hasScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true // Pre-Catalina doesn't require permission
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
        return true // Pre-Catalina doesn't require permission
    }
    
    /// Opens System Preferences to the Screen Recording section
    /// Returns true if the settings were opened successfully, false otherwise
    func openScreenRecordingSettings() -> Bool {
        // Try opening the specific Screen Recording settings page
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
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
    
    /// Retrieves information about all windows currently open on the system
    /// Returns an array of dictionaries containing window properties such as:
    /// - windowId: Unique identifier for the window
    /// - name: Window title/name
    /// - ownerName: Name of the application that owns the window
    /// - bounds: Window position and size as [x, y, width, height]
    /// - layer: Window layer level
    /// - isOnScreen: Whether the window is currently visible on screen
    /// - processId: Process ID of the application that owns the window
    func getAllWindows() -> Result<[[String: Any]], WindowError> {
        // Get window list with all available options
        let windowListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        
        guard let windowList = windowListInfo as? [[String: Any]] else {
            return .failure(.failedToRetrieveWindowList)
        }
        
        var windows: [[String: Any]] = []
        
        for windowInfo in windowList {
            var window: [String: Any] = [:]
            
            // Extract window ID
            if let windowId = windowInfo[kCGWindowNumber as String] as? NSNumber {
                window["windowId"] = windowId.intValue
            }
            
            // Extract window name/title
            if let name = windowInfo[kCGWindowName as String] as? String {
                window["name"] = name
            } else {
                window["name"] = ""
            }
            
            // Extract owner name (application name)
            if let ownerName = windowInfo[kCGWindowOwnerName as String] as? String {
                window["ownerName"] = ownerName
            } else {
                window["ownerName"] = ""
            }
            
            // Extract window bounds
            if let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] {
                let x = boundsDict["X"] as? Double ?? 0
                let y = boundsDict["Y"] as? Double ?? 0
                let width = boundsDict["Width"] as? Double ?? 0
                let height = boundsDict["Height"] as? Double ?? 0
                window["bounds"] = [x, y, width, height]
            } else {
                window["bounds"] = [0, 0, 0, 0]
            }
            
            // Extract window layer
            if let layer = windowInfo[kCGWindowLayer as String] as? NSNumber {
                window["layer"] = layer.intValue
            } else {
                window["layer"] = 0
            }
            
            // Extract on-screen status
            if let isOnScreen = windowInfo[kCGWindowIsOnscreen as String] as? NSNumber {
                window["isOnScreen"] = isOnScreen.boolValue
            } else {
                window["isOnScreen"] = false
            }
            
            // Extract process ID
            if let pid = windowInfo[kCGWindowOwnerPID as String] as? NSNumber {
                window["processId"] = pid.intValue
            }
            
            windows.append(window)
        }
        
        return .success(windows)
    }
}

/// Enum representing window operation errors
enum WindowError: Error, LocalizedError {
    case failedToRetrieveWindowList
    
    var errorDescription: String? {
        switch self {
        case .failedToRetrieveWindowList:
            return "Failed to retrieve window list"
        }
    }
}