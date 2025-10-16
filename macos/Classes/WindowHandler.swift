import ApplicationServices  // Import for Accessibility API
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
    /// - excludeEmptyNames: If true, windows with empty/missing names will be filtered out
    func getAllWindows(excludeEmptyNames: Bool = false) -> Result<[[String: Any]], WindowError> {
        // Get window list with all available options (including windows from other spaces)
        let windowListInfo = CGWindowListCopyWindowInfo(
            [.excludeDesktopElements], kCGNullWindowID)

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
            let windowName: String
            if let name = windowInfo[kCGWindowName as String] as? String {
                windowName = name
            } else {
                windowName = ""
            }

            // Skip windows with empty names if excludeEmptyNames option is enabled
            if excludeEmptyNames && windowName.isEmpty {
                continue
            }

            window["name"] = windowName

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

            // Extract role and subrole using Accessibility API (requires permission)
            if let pid = windowInfo[kCGWindowOwnerPID as String] as? NSNumber {
                let roleInfo = getWindowRole(processId: pid.intValue, windowName: windowName)
                if let role = roleInfo.role {
                    window["role"] = role
                }
                if let subrole = roleInfo.subrole {
                    window["subrole"] = subrole
                }
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
            if let backingLocation = windowInfo[kCGWindowBackingLocationVideoMemory as String]
                as? NSNumber
            {
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

    /// Retrieves windows with advanced filtering options
    /// All parameters are optional - nil values are ignored in filtering
    /// Returns an array of windows that match all specified criteria (AND condition)
    func getWindowsAdvanced(
        windowId: Int? = nil,
        name: String? = nil,
        nameExactMatch: Bool? = nil,
        nameCaseSensitive: Bool? = nil,
        ownerName: String? = nil,
        ownerNameExactMatch: Bool? = nil,
        ownerNameCaseSensitive: Bool? = nil,
        processId: Int? = nil,
        isOnScreen: Bool? = nil,
        layer: Int? = nil,
        x: Double? = nil,
        y: Double? = nil,
        width: Double? = nil,
        height: Double? = nil
    ) -> Result<[[String: Any]], WindowError> {
        return getFilteredWindows { windowInfo in
            // Check windowId if specified
            if let windowId = windowId {
                let id = windowInfo[kCGWindowNumber as String] as? NSNumber
                if id?.intValue != windowId {
                    return false
                }
            }

            // Check name if specified
            if let name = name {
                let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
                let exactMatch = nameExactMatch ?? false
                let caseSensitive = nameCaseSensitive ?? true

                if !matchString(windowName, pattern: name, exactMatch: exactMatch, caseSensitive: caseSensitive) {
                    return false
                }
            }

            // Check ownerName if specified
            if let ownerName = ownerName {
                let windowOwnerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
                let exactMatch = ownerNameExactMatch ?? false
                let caseSensitive = ownerNameCaseSensitive ?? true

                if !matchString(windowOwnerName, pattern: ownerName, exactMatch: exactMatch, caseSensitive: caseSensitive) {
                    return false
                }
            }

            // Check processId if specified
            if let processId = processId {
                let pid = windowInfo[kCGWindowOwnerPID as String] as? NSNumber
                if pid?.intValue != processId {
                    return false
                }
            }

            // Check isOnScreen if specified
            if let isOnScreen = isOnScreen {
                let onScreen = windowInfo[kCGWindowIsOnscreen as String] as? NSNumber
                if onScreen?.boolValue != isOnScreen {
                    return false
                }
            }

            // Check layer if specified
            if let layer = layer {
                let windowLayer = windowInfo[kCGWindowLayer as String] as? NSNumber
                if windowLayer?.intValue != layer {
                    return false
                }
            }

            // Check bounds (x, y, width, height) if specified
            if x != nil || y != nil || width != nil || height != nil {
                if let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] {
                    if let x = x {
                        let windowX = boundsDict["X"] as? Double ?? 0
                        if windowX != x {
                            return false
                        }
                    }

                    if let y = y {
                        let windowY = boundsDict["Y"] as? Double ?? 0
                        if windowY != y {
                            return false
                        }
                    }

                    if let width = width {
                        let windowWidth = boundsDict["Width"] as? Double ?? 0
                        if windowWidth != width {
                            return false
                        }
                    }

                    if let height = height {
                        let windowHeight = boundsDict["Height"] as? Double ?? 0
                        if windowHeight != height {
                            return false
                        }
                    }
                } else {
                    // If bounds info is not available but we're filtering by bounds, exclude this window
                    return false
                }
            }

            // All specified conditions passed
            return true
        }
    }

    /// Internal helper method to filter windows based on a predicate
    private func getFilteredWindows(filter: ([String: Any]) -> Bool) -> Result<
        [[String: Any]], WindowError
    > {
        let windowListInfo = CGWindowListCopyWindowInfo(
            [.excludeDesktopElements], kCGNullWindowID)

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

                // Extract role and subrole using Accessibility API (requires permission)
                if let pid = windowInfo[kCGWindowOwnerPID as String] as? NSNumber {
                    let windowName = windowInfo[kCGWindowName as String] as? String ?? ""
                    let roleInfo = getWindowRole(processId: pid.intValue, windowName: windowName)
                    if let role = roleInfo.role {
                        window["role"] = role
                    }
                    if let subrole = roleInfo.subrole {
                        window["subrole"] = subrole
                    }
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
                if let backingLocation = windowInfo[kCGWindowBackingLocationVideoMemory as String]
                    as? NSNumber
                {
                    window["isInVideoMemory"] = backingLocation.boolValue
                }

                windows.append(window)
            }
        }

        return .success(windows)
    }

    /// Checks if a window with the specified ID is currently alive/exists
    /// Returns true if the window exists, false otherwise
    /// If expectedName is provided, also verifies that the window name matches
    func isWindowAlive(_ windowId: Int, expectedName: String? = nil) -> Bool {
        let result = getWindowById(windowId)
        switch result {
        case .success(let windows):
            guard !windows.isEmpty else {
                return false
            }

            // If expectedName is provided, verify the window name matches
            if let expectedName = expectedName,
               let window = windows.first,
               let actualName = window["name"] as? String {
                return actualName == expectedName
            }

            // No name verification needed or no name to verify
            return true
        case .failure(_):
            return false
        }
    }

    // MARK: - Private Helper Methods for Accessibility API

    /// Retrieves the role and subrole of a window using Accessibility API
    /// Returns a tuple with (role, subrole), both can be nil if unavailable
    /// Requires Accessibility permission to work properly
    private func getWindowRole(processId: Int, windowName: String) -> (role: String?, subrole: String?) {
        // Create AXUIElement for the application using process ID
        let appElement = AXUIElementCreateApplication(pid_t(processId))

        // Get all windows from the application
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
            let windowsArray = windowsRef as? [AXUIElement]
        else {
            return (nil, nil)
        }

        // Find the specific window by comparing window titles
        for windowElement in windowsArray {
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(
                windowElement, kAXTitleAttribute as CFString, &titleRef)

            if titleResult == .success,
                let title = titleRef as? String
            {
                // If window name is empty or matches, get role/subrole for this window
                if windowName.isEmpty || title == windowName {
                    var role: String?
                    var subrole: String?

                    // Get role
                    var roleRef: CFTypeRef?
                    let roleResult = AXUIElementCopyAttributeValue(
                        windowElement, kAXRoleAttribute as CFString, &roleRef)
                    if roleResult == .success, let roleValue = roleRef as? String {
                        role = roleValue
                    }

                    // Get subrole
                    var subroleRef: CFTypeRef?
                    let subroleResult = AXUIElementCopyAttributeValue(
                        windowElement, kAXSubroleAttribute as CFString, &subroleRef)
                    if subroleResult == .success, let subroleValue = subroleRef as? String {
                        subrole = subroleValue
                    }

                    return (role, subrole)
                }
            }
        }

        return (nil, nil)
    }

    /// Finds the AXUIElement for a window using process ID and window information
    /// This is the first step in Accessibility API - we need to get the app's UI element first
    private func findWindowElement(processId: Int, windowName: String) -> AXUIElement? {
        // Step 1: Create AXUIElement for the application using process ID
        let appElement = AXUIElementCreateApplication(pid_t(processId))

        // Step 2: Get all windows from the application
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
            let windowsArray = windowsRef as? [AXUIElement]
        else {
            return nil
        }

        // Step 3: Find the specific window by comparing window titles
        for windowElement in windowsArray {
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(
                windowElement, kAXTitleAttribute as CFString, &titleRef)

            if titleResult == .success,
                let title = titleRef as? String
            {

                // If window name is empty or matches, return this window element
                if windowName.isEmpty || title == windowName {
                    return windowElement
                }
            }
        }

        return nil
    }

    /// Alternative method: Find window element by trying different approaches
    /// Sometimes window titles don't match exactly, so we try multiple strategies
    private func findWindowElementFlexible(processId: Int, windowName: String) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid_t(processId))

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
            let windowsArray = windowsRef as? [AXUIElement]
        else {
            return nil
        }

        // Strategy 1: Exact match
        for windowElement in windowsArray {
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(
                windowElement, kAXTitleAttribute as CFString, &titleRef)

            if titleResult == .success,
                let title = titleRef as? String,
                title == windowName
            {
                return windowElement
            }
        }

        // Strategy 2: Contains match (for partial titles)
        for windowElement in windowsArray {
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(
                windowElement, kAXTitleAttribute as CFString, &titleRef)

            if titleResult == .success,
                let title = titleRef as? String,
                !windowName.isEmpty && title.contains(windowName)
            {
                return windowElement
            }
        }

        // Strategy 3: Return first window if window name is empty
        if windowName.isEmpty && !windowsArray.isEmpty {
            return windowsArray[0]
        }

        return nil
    }

    /// Finds the close button element for a given window element
    /// macOS windows have multiple ways to access the close button
    private func findCloseButton(for windowElement: AXUIElement) -> AXUIElement? {
        // Method 1: Direct close button attribute (most reliable)
        var closeButtonRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            windowElement, kAXCloseButtonAttribute as CFString, &closeButtonRef)

        if result == .success, let closeButton = closeButtonRef {
            return (closeButton as! AXUIElement)
        }

        // Method 2: Search through child elements
        return findCloseButtonInChildren(windowElement)
    }

    /// Searches for close button in window's child elements
    /// This is a fallback method when direct close button attribute is not available
    private func findCloseButtonInChildren(_ windowElement: AXUIElement) -> AXUIElement? {
        var childrenRef: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(
            windowElement, kAXChildrenAttribute as CFString, &childrenRef)

        guard childrenResult == .success,
            let children = childrenRef as? [AXUIElement]
        else {
            return nil
        }

        // Look for close button by role and subrole
        for child in children {
            if let closeButton = searchForCloseButton(in: child, depth: 0, maxDepth: 3) {
                return closeButton
            }
        }

        return nil
    }

    /// Recursively searches for close button in UI element hierarchy
    /// Uses role and subrole to identify the close button
    private func searchForCloseButton(in element: AXUIElement, depth: Int, maxDepth: Int)
        -> AXUIElement?
    {
        // Prevent infinite recursion
        guard depth <= maxDepth else { return nil }

        // Check if current element is a close button
        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(
            element, kAXRoleAttribute as CFString, &roleRef)

        if roleResult == .success, let role = roleRef as? String {
            // Check for button role
            if role == kAXButtonRole {
                // Further check subrole or description to identify close button
                var subroleRef: CFTypeRef?
                let subroleResult = AXUIElementCopyAttributeValue(
                    element, kAXSubroleAttribute as CFString, &subroleRef)

                if subroleResult == .success, let subrole = subroleRef as? String {
                    // Close button typically has "AXCloseButton" subrole
                    if subrole == kAXCloseButtonSubrole {
                        return element
                    }
                }

                // Alternative: Check by description or title
                var descRef: CFTypeRef?
                let descResult = AXUIElementCopyAttributeValue(
                    element, kAXDescriptionAttribute as CFString, &descRef)

                if descResult == .success, let description = descRef as? String {
                    // Look for close-related descriptions
                    if description.lowercased().contains("close") {
                        return element
                    }
                }
            }
        }

        // Search in children recursively
        var childrenRef: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(
            element, kAXChildrenAttribute as CFString, &childrenRef)

        if childrenResult == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let closeButton = searchForCloseButton(
                    in: child, depth: depth + 1, maxDepth: maxDepth)
                {
                    return closeButton
                }
            }
        }

        return nil
    }

    /// Performs a click action on the close button element
    /// This is the final step - actually clicking the close button
    private func clickCloseButton(_ closeButton: AXUIElement) -> Bool {
        // Perform the press action on the close button
        let result = AXUIElementPerformAction(closeButton, kAXPressAction as CFString)

        if result == .success {
            return true
        } else {
            return false
        }
    }

    /// Attempts to close a window using Accessibility API with multiple fallback strategies
    /// This combines all the helper methods above into a comprehensive close window function
    private func closeWindowWithAccessibilityAPI(processId: Int, windowName: String) -> Result<
        Bool, WindowError
    > {

        // Step 1: Find the window element
        var windowElement: AXUIElement?

        // Try the flexible approach first (more likely to succeed)
        windowElement = findWindowElementFlexible(processId: processId, windowName: windowName)

        // If that fails, try the exact approach
        if windowElement == nil {
            windowElement = findWindowElement(processId: processId, windowName: windowName)
        }

        guard let window = windowElement else {

            return .failure(.windowNotFound)
        }

        // Step 2: Find the close button
        guard let closeButton = findCloseButton(for: window) else {
            return .failure(.closeButtonNotFound)
        }

        // Step 3: Click the close button
        let clickSuccess = clickCloseButton(closeButton)

        if clickSuccess {
            return .success(true)
        } else {
            return .failure(.closeActionFailed)
        }
    }

    /// Closes a window by its window ID using Accessibility API
    /// This method uses modern Accessibility API instead of AppleScript for better reliability
    /// Returns a Result indicating success or failure
    func closeWindow(_ windowId: Int) -> Result<Bool, WindowError> {

        // Step 1: Check accessibility permissions
        let permissionHandler = PermissionHandler()
        guard permissionHandler.hasAccessibilityPermission() else {
            return .failure(.accessibilityPermissionDenied)
        }

        // Step 2: Get window information from our existing method
        let windowResult = getWindowById(windowId)

        switch windowResult {
        case .success(let windows):
            guard let window = windows.first else {
                return .failure(.windowNotFound)
            }

            // Extract process ID and window name
            guard let processId = window["processId"] as? Int else {
                return .failure(.insufficientWindowInfo)
            }

            let windowName = window["name"] as? String ?? ""

            // Step 3: Try Accessibility API approach
            let accessibilityResult = closeWindowWithAccessibilityAPI(
                processId: processId,
                windowName: windowName
            )

            switch accessibilityResult {
            case .success(let success):
                if success {
                    return .success(true)
                } else {
                    return .failure(.closeActionFailed)
                }

            case .failure(let error):

                // Step 4: Fallback to alternative methods if needed
                // For now, we'll just return the error, but we could add AppleScript fallback here
                return .failure(error)
            }

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Terminates an application by its process ID using system signals
    /// This method will terminate the entire application, not just a specific window
    func terminateApplicationByPID(_ processId: Int, force: Bool = false) -> Result<
        Bool, WindowError
    > {

        // First verify the process exists
        let existsResult = kill(Int32(processId), 0)
        if existsResult == -1 {
            return .failure(.processNotFound)
        }

        // Try NSRunningApplication approach first (more graceful)
        let runningApps = NSWorkspace.shared.runningApplications
        if let app = runningApps.first(where: { $0.processIdentifier == Int32(processId) }) {

            if force {
                let success = app.forceTerminate()
                return .success(success)
            } else {
                let success = app.terminate()
                return .success(success)
            }
        }

        // Fallback to signal-based termination
        let signal = force ? SIGKILL : SIGTERM
        let result = kill(Int32(processId), signal)

        if result == 0 {
            return .success(true)
        } else {
            return .failure(.terminationFailed)
        }
    }

    /// Helper function for string matching with exact/contains and case-sensitive/insensitive options
    private func matchString(_ text: String, pattern: String, exactMatch: Bool, caseSensitive: Bool) -> Bool {
        let compareText = caseSensitive ? text : text.lowercased()
        let comparePattern = caseSensitive ? pattern : pattern.lowercased()

        if exactMatch {
            return compareText == comparePattern
        } else {
            return compareText.contains(comparePattern)
        }
    }

    /// Gets all child process IDs for a given parent process ID
    func getChildProcesses(of parentPID: Int32) -> Result<[Int32], WindowError> {

        var childPIDs: [Int32] = []
        var size = 0

        // Get size needed for process list
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        let result = sysctl(&mib, 4, nil, &size, nil, 0)

        if result != 0 {
            return .failure(.failedToGetProcessList)
        }

        // Allocate buffer and get process list
        let count = size / MemoryLayout<kinfo_proc>.size
        let processes = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: count)
        defer { processes.deallocate() }

        let getProcessResult = sysctl(&mib, 4, processes, &size, nil, 0)
        if getProcessResult != 0 {
            return .failure(.failedToGetProcessList)
        }

        // Find child processes
        for i in 0..<count {
            let process = processes[i]
            if process.kp_eproc.e_ppid == parentPID {
                childPIDs.append(process.kp_proc.p_pid)
            }
        }

        return .success(childPIDs)
    }


    /// Terminates an application and all its child processes
    func terminateApplicationTree(_ processId: Int, force: Bool = false) -> Result<
        Bool, WindowError
    > {

        // First get all child processes
        let childResult = getChildProcesses(of: Int32(processId))
        var allTerminated = true

        switch childResult {
        case .success(let childPIDs):
            // Terminate children first (bottom-up approach)
            for childPID in childPIDs {
                let childResult = terminateApplicationByPID(Int(childPID), force: force)
                if case .failure = childResult {
                    allTerminated = false
                }
            }

        case .failure(_):
            // Continue with parent termination even if we can't get children
            break
        }

        // Finally terminate the parent process
        let parentResult = terminateApplicationByPID(processId, force: force)

        switch parentResult {
        case .success(let success):
            return .success(success && allTerminated)
        case .failure(let error):
            return .failure(error)
        }
    }
}

/// Enum representing window operation errors
enum WindowError: Error, LocalizedError {
    case failedToRetrieveWindowList
    case windowNotFound
    case insufficientWindowInfo
    case appleScriptExecutionFailed
    case accessibilityPermissionDenied
    case closeButtonNotFound
    case closeActionFailed
    case processNotFound
    case terminationFailed
    case failedToGetProcessList

    var errorDescription: String? {
        switch self {
        case .failedToRetrieveWindowList:
            return "Failed to retrieve window list"
        case .windowNotFound:
            return "Window not found"
        case .insufficientWindowInfo:
            return "Insufficient window information to close window"
        case .appleScriptExecutionFailed:
            return "Failed to execute AppleScript for window closure"
        case .accessibilityPermissionDenied:
            return "Accessibility permission is required to close windows"
        case .closeButtonNotFound:
            return "Could not find close button for the specified window"
        case .closeActionFailed:
            return "Failed to perform close action on window"
        case .processNotFound:
            return "Process not found"
        case .terminationFailed:
            return "Failed to terminate process"
        case .failedToGetProcessList:
            return "Failed to retrieve process list"
        }
    }
}
