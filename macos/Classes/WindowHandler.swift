import ApplicationServices  // Import for Accessibility API
import Cocoa
import Foundation

// MARK: - Private CGS Space API Declarations

private typealias CGSConnectionID = UInt32
private typealias CGSSpaceID = UInt64

@_silgen_name("CGSMainConnectionID")
private func _cgsMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSGetActiveSpace")
private func _cgsGetActiveSpace(_ cid: CGSConnectionID) -> CGSSpaceID

@_silgen_name("CGSCopySpacesForWindows")
private func _cgsCopySpacesForWindows(_ cid: CGSConnectionID, _ mask: Int32, _ windows: CFArray) -> CFArray

@_silgen_name("CGSManagedDisplaySetCurrentSpace")
private func _cgsManagedDisplaySetCurrentSpace(_ cid: CGSConnectionID, _ display: CFTypeRef, _ spaceID: CGSSpaceID)

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
        nameWildcard: Bool? = nil,
        ownerName: String? = nil,
        ownerNameExactMatch: Bool? = nil,
        ownerNameCaseSensitive: Bool? = nil,
        ownerNameWildcard: Bool? = nil,
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
                let wildcard = nameWildcard ?? false
                let exactMatch = nameExactMatch ?? false
                let caseSensitive = nameCaseSensitive ?? true

                if !matchString(windowName, pattern: name, exactMatch: exactMatch, caseSensitive: caseSensitive, wildcard: wildcard) {
                    return false
                }
            }

            // Check ownerName if specified
            if let ownerName = ownerName {
                let windowOwnerName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
                let wildcard = ownerNameWildcard ?? false
                let exactMatch = ownerNameExactMatch ?? false
                let caseSensitive = ownerNameCaseSensitive ?? true

                if !matchString(windowOwnerName, pattern: ownerName, exactMatch: exactMatch, caseSensitive: caseSensitive, wildcard: wildcard) {
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
            return .failure(.windowNotAccessible)
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

            case .failure(.windowNotAccessible):
                // Step 4: Window exists but is on a different Space — switch to it and retry
                return closeWindowViaSpaceSwitch(
                    processId: processId, windowId: windowId, windowName: windowName)

            case .failure(let error):
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

    /// Helper function for string matching with exact/contains, case-sensitive/insensitive, and wildcard options
    /// Supports * (any characters) and ? (single character) wildcards when wildcard is true
    private func matchString(_ text: String, pattern: String, exactMatch: Bool, caseSensitive: Bool, wildcard: Bool = false) -> Bool {
        let compareText = caseSensitive ? text : text.lowercased()
        let comparePattern = caseSensitive ? pattern : pattern.lowercased()

        // Wildcard matching takes priority
        if wildcard {
            return matchWildcard(compareText, pattern: comparePattern)
        }

        if exactMatch {
            return compareText == comparePattern
        } else {
            return compareText.contains(comparePattern)
        }
    }

    /// Wildcard matching implementation
    /// Supports * (0 or more characters) and ? (exactly 1 character)
    private func matchWildcard(_ text: String, pattern: String) -> Bool {
        // Split pattern by * to get parts
        let parts = pattern.components(separatedBy: "*")

        // Handle edge case: pattern is just "*"
        if parts.count == 2 && parts[0].isEmpty && parts[1].isEmpty {
            return true
        }

        var currentIndex = text.startIndex

        for (index, part) in parts.enumerated() {
            let isFirst = index == 0
            let isLast = index == parts.count - 1

            // Skip empty parts (except when they're meaningful)
            if part.isEmpty {
                // Empty part at start means pattern starts with *
                if isFirst && !pattern.hasPrefix("*") {
                    return false
                }
                // Empty part at end means pattern ends with *
                if isLast && !pattern.hasSuffix("*") {
                    return false
                }
                continue
            }

            // Match this part considering ? wildcards
            if let matchedRange = findPartMatch(in: text, from: currentIndex, part: part, isFirst: isFirst && !pattern.hasPrefix("*"), isLast: isLast && !pattern.hasSuffix("*")) {
                currentIndex = matchedRange.upperBound
            } else {
                return false
            }
        }

        // If pattern doesn't end with *, we must be at the end of text
        if !pattern.hasSuffix("*") && currentIndex != text.endIndex {
            return false
        }

        return true
    }

    /// Helper function to find a part match with ? wildcard support
    private func findPartMatch(in text: String, from startIndex: String.Index, part: String, isFirst: Bool, isLast: Bool) -> Range<String.Index>? {
        // If part contains ?, we need character-by-character matching
        if part.contains("?") {
            return findPartMatchWithQuestionMark(in: text, from: startIndex, part: part, isFirst: isFirst, isLast: isLast)
        }

        // No ? in part, use simple string search
        let searchRange = startIndex..<text.endIndex

        if isFirst {
            // Must match at the start
            if text[searchRange].hasPrefix(part) {
                return startIndex..<text.index(startIndex, offsetBy: part.count)
            }
            return nil
        } else if isLast {
            // Must match at the end
            if text[searchRange].hasSuffix(part) {
                let endIndex = text.endIndex
                let startOfMatch = text.index(endIndex, offsetBy: -part.count)
                if startOfMatch >= startIndex {
                    return startOfMatch..<endIndex
                }
            }
            return nil
        } else {
            // Can match anywhere in remaining text
            if let range = text.range(of: part, range: searchRange) {
                return range
            }
            return nil
        }
    }

    /// Find match with ? wildcard support
    private func findPartMatchWithQuestionMark(in text: String, from startIndex: String.Index, part: String, isFirst: Bool, isLast: Bool) -> Range<String.Index>? {
        let remainingText = String(text[startIndex...])

        // For each possible starting position
        let maxOffset = isLast ? (remainingText.count - part.count) : remainingText.count

        for offset in 0...max(0, maxOffset) {
            if offset + part.count > remainingText.count {
                break
            }

            let testStartIndex = remainingText.index(remainingText.startIndex, offsetBy: offset)
            let testEndIndex = remainingText.index(testStartIndex, offsetBy: part.count)
            let testSubstring = String(remainingText[testStartIndex..<testEndIndex])

            // Check if this substring matches the pattern with ?
            var matches = true
            for (patternChar, testChar) in zip(part, testSubstring) {
                if patternChar != "?" && patternChar != testChar {
                    matches = false
                    break
                }
            }

            if matches {
                // For isFirst, must start at offset 0
                if isFirst && offset != 0 {
                    continue
                }

                // For isLast, must end at the end of remaining text
                if isLast && testEndIndex != remainingText.endIndex {
                    continue
                }

                let actualStartIndex = text.index(startIndex, offsetBy: offset)
                let actualEndIndex = text.index(actualStartIndex, offsetBy: part.count)
                return actualStartIndex..<actualEndIndex
            }

            // If isFirst, we can only check offset 0
            if isFirst {
                break
            }
        }

        return nil
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

    /// Focuses (brings to front) a window by its window ID using Accessibility API
    /// This method activates the application and raises the window to the front
    /// Returns a Result indicating success or failure
    func focusWindow(_ windowId: Int) -> Result<Bool, WindowError> {

        // Step 1: Check accessibility permissions
        let permissionHandler = PermissionHandler()
        guard permissionHandler.hasAccessibilityPermission() else {
            return .failure(.accessibilityPermissionDenied)
        }

        // Step 2: Get window information
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

            // Step 3: Find window element
            var windowElement: AXUIElement?

            // Try flexible approach first (more likely to succeed)
            windowElement = findWindowElementFlexible(processId: processId, windowName: windowName)

            // If that fails, try exact approach
            if windowElement == nil {
                windowElement = findWindowElement(processId: processId, windowName: windowName)
            }

            guard let element = windowElement else {
                return .failure(.windowNotFound)
            }

            // Step 4: Set this window as the main window (kAXMainAttribute)
            // This is more reliable than just kAXRaiseAction
            let mainValue: CFTypeRef = kCFBooleanTrue
            let setMainResult = AXUIElementSetAttributeValue(
                element,
                kAXMainAttribute as CFString,
                mainValue
            )

            // Step 5: Activate the application (brings app to front)
            if let app = NSRunningApplication(processIdentifier: pid_t(processId)) {
                let activateOptions: NSApplication.ActivationOptions = [.activateIgnoringOtherApps]
                app.activate(options: activateOptions)
            }

            // Step 6: Also perform raise action as additional guarantee
            let raiseResult = AXUIElementPerformAction(element, kAXRaiseAction as CFString)

            // Success if either setMain or raise succeeded
            if setMainResult == .success || raiseResult == .success {
                return .success(true)
            } else {
                return .failure(.focusActionFailed)
            }

        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Scroll Information

    /// Retrieves scroll information for a window by its window ID
    /// Uses Accessibility API to find scroll bars and their positions
    /// Returns a Result with scroll info or error
    func getScrollInfo(_ windowId: Int) -> Result<[String: Any], WindowError> {
        // Step 1: Check accessibility permissions
        let permissionHandler = PermissionHandler()
        guard permissionHandler.hasAccessibilityPermission() else {
            return .failure(.accessibilityPermissionDenied)
        }

        // Step 2: Get window information
        let windowResult = getWindowById(windowId)

        switch windowResult {
        case .success(let windows):
            guard let window = windows.first else {
                return .failure(.windowNotFound)
            }

            guard let processId = window["processId"] as? Int else {
                return .failure(.insufficientWindowInfo)
            }

            let windowName = window["name"] as? String ?? ""

            // Step 3: Find window element
            var windowElement: AXUIElement?
            windowElement = findWindowElementFlexible(processId: processId, windowName: windowName)

            if windowElement == nil {
                windowElement = findWindowElement(processId: processId, windowName: windowName)
            }

            guard let element = windowElement else {
                return .failure(.windowNotAccessible)
            }

            // Step 4: Get scroll information from the window
            let scrollInfo = getScrollInfoFromElement(element)
            return .success(scrollInfo)

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Extracts scroll information from an AXUIElement (window or scroll area)
    private func getScrollInfoFromElement(_ element: AXUIElement) -> [String: Any] {
        var result: [String: Any] = [
            "hasVerticalScroll": false,
            "hasHorizontalScroll": false
        ]

        // Strategy 1: Try to find AXScrollArea directly in the window's children
        if let scrollArea = findScrollArea(in: element) {
            extractScrollBarInfo(from: scrollArea, into: &result)
        }

        // Strategy 2: Try direct scroll bar attributes on the element itself
        if !(result["hasVerticalScroll"] as! Bool) && !(result["hasHorizontalScroll"] as! Bool) {
            extractScrollBarInfo(from: element, into: &result)
        }

        // Strategy 3: Recursively search for scroll areas in children
        if !(result["hasVerticalScroll"] as! Bool) && !(result["hasHorizontalScroll"] as! Bool) {
            if let scrollArea = findScrollAreaRecursively(in: element, depth: 0, maxDepth: 5) {
                extractScrollBarInfo(from: scrollArea, into: &result)
            }
        }

        return result
    }

    /// Finds the first AXScrollArea in an element's direct children
    private func findScrollArea(in element: AXUIElement) -> AXUIElement? {
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element, kAXChildrenAttribute as CFString, &childrenRef)

        guard result == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            var roleRef: CFTypeRef?
            let roleResult = AXUIElementCopyAttributeValue(
                child, kAXRoleAttribute as CFString, &roleRef)

            if roleResult == .success,
               let role = roleRef as? String,
               role == "AXScrollArea" {
                return child
            }
        }

        return nil
    }

    /// Recursively finds AXScrollArea in the element hierarchy
    private func findScrollAreaRecursively(in element: AXUIElement, depth: Int, maxDepth: Int) -> AXUIElement? {
        guard depth < maxDepth else { return nil }

        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element, kAXChildrenAttribute as CFString, &childrenRef)

        guard result == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            var roleRef: CFTypeRef?
            let roleResult = AXUIElementCopyAttributeValue(
                child, kAXRoleAttribute as CFString, &roleRef)

            if roleResult == .success,
               let role = roleRef as? String,
               role == "AXScrollArea" {
                return child
            }

            // Recursively search in child
            if let found = findScrollAreaRecursively(in: child, depth: depth + 1, maxDepth: maxDepth) {
                return found
            }
        }

        return nil
    }

    /// Extracts scroll bar information from an element (scroll area or window)
    private func extractScrollBarInfo(from element: AXUIElement, into result: inout [String: Any]) {
        // Get vertical scroll bar
        var verticalScrollBarRef: CFTypeRef?
        let verticalResult = AXUIElementCopyAttributeValue(
            element, kAXVerticalScrollBarAttribute as CFString, &verticalScrollBarRef)

        if verticalResult == .success,
           let verticalScrollBar = verticalScrollBarRef {
            result["hasVerticalScroll"] = true

            // Get scroll bar value (0.0 to 1.0)
            var valueRef: CFTypeRef?
            let valueResult = AXUIElementCopyAttributeValue(
                verticalScrollBar as! AXUIElement, kAXValueAttribute as CFString, &valueRef)

            if valueResult == .success,
               let value = valueRef as? NSNumber {
                result["verticalPosition"] = value.doubleValue
            }
        }

        // Get horizontal scroll bar
        var horizontalScrollBarRef: CFTypeRef?
        let horizontalResult = AXUIElementCopyAttributeValue(
            element, kAXHorizontalScrollBarAttribute as CFString, &horizontalScrollBarRef)

        if horizontalResult == .success,
           let horizontalScrollBar = horizontalScrollBarRef {
            result["hasHorizontalScroll"] = true

            // Get scroll bar value (0.0 to 1.0)
            var valueRef: CFTypeRef?
            let valueResult = AXUIElementCopyAttributeValue(
                horizontalScrollBar as! AXUIElement, kAXValueAttribute as CFString, &valueRef)

            if valueResult == .success,
               let value = valueRef as? NSNumber {
                result["horizontalPosition"] = value.doubleValue
            }
        }
    }

    // MARK: - Space Management

    /// Returns the Space ID for a given window ID using private CGS APIs
    private func spaceForWindow(_ windowId: Int) -> CGSSpaceID? {
        let cid = _cgsMainConnectionID()
        let windowID = CGWindowID(windowId)
        let windowsArray = [NSNumber(value: windowID)] as CFArray
        let spaces = _cgsCopySpacesForWindows(cid, 7, windowsArray) as? [NSNumber]
        return spaces?.first.map { CGSSpaceID($0.uint64Value) }
    }

    /// Returns the display ID that contains the given window using its bounds
    private func displayForWindow(_ windowId: Int) -> CGDirectDisplayID {
        let windowListInfo = CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)
        guard let windowList = windowListInfo as? [[String: Any]] else {
            return CGMainDisplayID()
        }

        for windowInfo in windowList {
            guard let id = windowInfo[kCGWindowNumber as String] as? NSNumber,
                  id.intValue == windowId,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any] else {
                continue
            }

            let x = boundsDict["X"] as? Double ?? 0
            let y = boundsDict["Y"] as? Double ?? 0
            let width = boundsDict["Width"] as? Double ?? 0
            let height = boundsDict["Height"] as? Double ?? 0
            let rect = CGRect(x: x, y: y, width: width, height: height)

            var displayCount: UInt32 = 0
            var displayIDs = [CGDirectDisplayID](repeating: 0, count: 8)
            if CGGetDisplaysWithRect(rect, 8, &displayIDs, &displayCount) == .success,
               displayCount > 0 {
                return displayIDs[0]
            }
        }

        return CGMainDisplayID()
    }

    /// Returns the UUID string for a given display ID
    private func displayUUIDString(for displayID: CGDirectDisplayID) -> String? {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID) else { return nil }
        return CFUUIDCreateString(nil, uuid.takeRetainedValue()) as String?
    }

    /// Switches the active Space on the specified display using private CGS APIs
    private func activateSpace(_ spaceID: CGSSpaceID, on displayID: CGDirectDisplayID) {
        guard let uuidString = displayUUIDString(for: displayID) else { return }
        let cid = _cgsMainConnectionID()
        _cgsManagedDisplaySetCurrentSpace(cid, uuidString as CFString, spaceID)
    }

    /// Closes a window on a different Space by temporarily switching to it
    private func closeWindowViaSpaceSwitch(
        processId: Int, windowId: Int, windowName: String
    ) -> Result<Bool, WindowError> {
        // 0. Verify required private CGS symbols exist at runtime
        let requiredSymbols = [
            "CGSMainConnectionID",
            "CGSGetActiveSpace",
            "CGSCopySpacesForWindows",
            "CGSManagedDisplaySetCurrentSpace",
        ]
        guard requiredSymbols.allSatisfy({ dlsym(RTLD_DEFAULT, $0) != nil }) else {
            return .failure(.spaceSwitchAPIUnavailable)
        }

        // 1. Get the target window's Space
        guard let targetSpace = spaceForWindow(windowId) else {
            return .failure(.windowNotAccessible)
        }

        // 2. Save the currently active Space and find the window's display
        let cid = _cgsMainConnectionID()
        let originalSpace = _cgsGetActiveSpace(cid)
        let displayID = displayForWindow(windowId)

        // 3. Switch to the window's Space if it's different
        let needsSwitch = originalSpace != targetSpace
        if needsSwitch {
            activateSpace(targetSpace, on: displayID)
        }

        // 4. Poll until AX API can see the window, then close
        // Space switch is async, so we retry until the window element becomes accessible
        var windowElement: AXUIElement?
        let deadline = Date(timeIntervalSinceNow: 1.0)
        while Date() < deadline {
            windowElement = findWindowElementFlexible(processId: processId, windowName: windowName)
                ?? findWindowElement(processId: processId, windowName: windowName)
            if windowElement != nil { break }
            CFRunLoopRunInMode(.defaultMode, 0.05, true)
        }

        guard let element = windowElement else {
            if needsSwitch { activateSpace(originalSpace, on: displayID) }
            return .failure(.windowNotAccessible)
        }

        guard let closeButton = findCloseButton(for: element) else {
            if needsSwitch { activateSpace(originalSpace, on: displayID) }
            return .failure(.closeButtonNotFound)
        }

        let result: Result<Bool, WindowError> = clickCloseButton(closeButton)
            ? .success(true)
            : .failure(.closeActionFailed)

        // 5. Switch back to the original Space on the same display
        if needsSwitch {
            activateSpace(originalSpace, on: displayID)
        }

        return result
    }

    /// Helper method to pass WindowError errors to Flutter
    static func handleWindowError(_ error: WindowError) -> [String: Any] {
        switch error {
        case .failedToRetrieveWindowList:
            return [
                "code": "FAILED_TO_RETRIEVE_WINDOW_LIST",
                "message": "Failed to retrieve window list",
                "details": NSNull(),
            ]
        case .windowNotFound:
            return [
                "code": "WINDOW_NOT_FOUND",
                "message": "Window not found",
                "details": "The specified window could not be found. It may have been closed or the ID is invalid.",
            ]
        case .insufficientWindowInfo:
            return [
                "code": "INSUFFICIENT_WINDOW_INFO",
                "message": "Insufficient window information",
                "details": "Unable to retrieve necessary information (process ID or window name) to perform the operation.",
            ]
        case .appleScriptExecutionFailed:
            return [
                "code": "APPLESCRIPT_EXECUTION_FAILED",
                "message": "Failed to execute AppleScript for window closure",
                "details": NSNull(),
            ]
        case .accessibilityPermissionDenied:
            return [
                "code": "ACCESSIBILITY_PERMISSION_DENIED",
                "message": "Accessibility permission is required",
                "details": "Please grant accessibility permission in System Settings > Privacy & Security > Accessibility",
            ]
        case .closeButtonNotFound:
            return [
                "code": "CLOSE_BUTTON_NOT_FOUND",
                "message": "Could not find close button for the specified window",
                "details": "The window structure may not support programmatic closing via Accessibility API.",
            ]
        case .closeActionFailed:
            return [
                "code": "CLOSE_ACTION_FAILED",
                "message": "Failed to perform close action on window",
                "details": "The close button was found but clicking it failed.",
            ]
        case .focusActionFailed:
            return [
                "code": "FOCUS_ACTION_FAILED",
                "message": "Failed to focus window",
                "details": "The raise action was found but executing it failed.",
            ]
        case .processNotFound:
            return [
                "code": "PROCESS_NOT_FOUND",
                "message": "Process not found",
                "details": "The specified process ID does not exist or has already terminated.",
            ]
        case .terminationFailed:
            return [
                "code": "TERMINATION_FAILED",
                "message": "Failed to terminate process",
                "details": "The process could not be terminated. It may require elevated privileges.",
            ]
        case .failedToGetProcessList:
            return [
                "code": "FAILED_TO_GET_PROCESS_LIST",
                "message": "Failed to retrieve process list",
                "details": "Unable to query system process information.",
            ]
        case .windowNotAccessible:
            return [
                "code": "WINDOW_NOT_ACCESSIBLE",
                "message": "Window is not accessible via Accessibility API",
                "details": "The window exists but cannot be accessed. It may be on a different Space, or the application does not support the Accessibility API.",
            ]
        case .spaceSwitchAPIUnavailable:
            return [
                "code": "SPACE_SWITCH_API_UNAVAILABLE",
                "message": "Private CGS Space APIs are not available",
                "details": "The window is on a different Space but the required private APIs are unavailable on this macOS version.",
            ]
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
    case focusActionFailed
    case processNotFound
    case terminationFailed
    case failedToGetProcessList
    case windowNotAccessible
    case spaceSwitchAPIUnavailable

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
        case .focusActionFailed:
            return "Failed to focus window - raise action did not succeed"
        case .processNotFound:
            return "Process not found"
        case .terminationFailed:
            return "Failed to terminate process"
        case .failedToGetProcessList:
            return "Failed to retrieve process list"
        case .windowNotAccessible:
            return "Window is not accessible via Accessibility API"
        case .spaceSwitchAPIUnavailable:
            return "Private CGS Space APIs are not available on this macOS version"
        }
    }
}
