import Cocoa
import Foundation

/// Handler class responsible for window-related operations
class WindowHandler {
    
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
            
            // Extract window bounds as separate x, y, width, height
            if let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] {
                window["x"] = boundsDict["X"] as? Double ?? 0
                window["y"] = boundsDict["Y"] as? Double ?? 0
                window["width"] = boundsDict["Width"] as? Double ?? 0
                window["height"] = boundsDict["Height"] as? Double ?? 0
            } else {
                window["x"] = 0.0
                window["y"] = 0.0
                window["width"] = 0.0
                window["height"] = 0.0
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
            
            // Extract additional properties
            
            // Store type
            if let storeType = windowInfo[kCGWindowStoreType as String] as? NSNumber {
                window["storeType"] = storeType.intValue
            }
            
            // Sharing state
            if let sharingState = windowInfo[kCGWindowSharingState as String] as? NSNumber {
                window["sharingState"] = sharingState.intValue
            }
            
            // Alpha/transparency
            if let alpha = windowInfo[kCGWindowAlpha as String] as? NSNumber {
                window["alpha"] = alpha.doubleValue
            }
            
            // Memory usage
            if let memoryUsage = windowInfo[kCGWindowMemoryUsage as String] as? NSNumber {
                window["memoryUsage"] = memoryUsage.intValue
            }
            
            
            // Video memory backing location
            if let backingLocation = windowInfo[kCGWindowBackingLocationVideoMemory as String] as? NSNumber {
                window["isInVideoMemory"] = backingLocation.boolValue
            }
            
            windows.append(window)
        }
        
        return .success(windows)
    }
    
    /// Retrieves windows filtered by name (window title)
    /// Returns an array of windows that match the specified name
    func getWindowsByName(_ name: String) -> Result<[[String: Any]], WindowError> {
        return getFilteredWindows { windowInfo in
            let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
            return windowName.contains(name)
        }
    }
    
    /// Retrieves windows filtered by owner name (application name)
    /// Returns an array of windows owned by applications matching the specified name
    func getWindowsByOwnerName(_ ownerName: String) -> Result<[[String: Any]], WindowError> {
        return getFilteredWindows { windowInfo in
            let windowOwnerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
            return windowOwnerName.contains(ownerName)
        }
    }
    
    /// Retrieves a specific window by its window ID
    /// Returns an array containing the window (empty if not found)
    func getWindowById(_ windowId: Int) -> Result<[[String: Any]], WindowError> {
        return getFilteredWindows { windowInfo in
            let id = windowInfo[kCGWindowNumber as String] as? NSNumber
            return id?.intValue == windowId
        }
    }
    
    /// Retrieves windows filtered by process ID
    /// Returns an array of windows owned by the specified process
    func getWindowsByProcessId(_ processId: Int) -> Result<[[String: Any]], WindowError> {
        return getFilteredWindows { windowInfo in
            let pid = windowInfo[kCGWindowOwnerPID as String] as? NSNumber
            return pid?.intValue == processId
        }
    }
    
    /// Internal helper method to filter windows based on a predicate
    private func getFilteredWindows(filter: ([String: Any]) -> Bool) -> Result<[[String: Any]], WindowError> {
        let windowListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        
        guard let windowList = windowListInfo as? [[String: Any]] else {
            return .failure(.failedToRetrieveWindowList)
        }
        
        var windows: [[String: Any]] = []
        
        for windowInfo in windowList {
            if filter(windowInfo) {
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
                
                // Extract window bounds as separate x, y, width, height
                if let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] {
                    window["x"] = boundsDict["X"] as? Double ?? 0
                    window["y"] = boundsDict["Y"] as? Double ?? 0
                    window["width"] = boundsDict["Width"] as? Double ?? 0
                    window["height"] = boundsDict["Height"] as? Double ?? 0
                } else {
                    window["x"] = 0.0
                    window["y"] = 0.0
                    window["width"] = 0.0
                    window["height"] = 0.0
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
                
                // Extract additional properties
                
                // Store type
                if let storeType = windowInfo[kCGWindowStoreType as String] as? NSNumber {
                    window["storeType"] = storeType.intValue
                }
                
                // Sharing state
                if let sharingState = windowInfo[kCGWindowSharingState as String] as? NSNumber {
                    window["sharingState"] = sharingState.intValue
                }
                
                // Alpha/transparency
                if let alpha = windowInfo[kCGWindowAlpha as String] as? NSNumber {
                    window["alpha"] = alpha.doubleValue
                }
                
                // Memory usage
                if let memoryUsage = windowInfo[kCGWindowMemoryUsage as String] as? NSNumber {
                    window["memoryUsage"] = memoryUsage.intValue
                }
                
                
                // Video memory backing location
                if let backingLocation = windowInfo[kCGWindowBackingLocationVideoMemory as String] as? NSNumber {
                    window["isInVideoMemory"] = backingLocation.boolValue
                }
                
                windows.append(window)
            }
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