import Cocoa
import Foundation

class CaptureUtil {

    /// Get window content bounds using AXUIElement API with windowId
    static func getWindowContentBounds(windowId: Int, windowBounds: CGRect) -> CGRect? {
        // First check if window is fullscreen
        if isFullscreenWindow(windowFrame: windowBounds) {
            return windowBounds  // No titlebar in fullscreen
        }

        // Use AXUIElement API to find the specific window by windowId
        return getContentBoundsFromAXUIElement(windowId: windowId, windowBounds: windowBounds)
    }

    /// Get content bounds using AXUIElement API for the specific windowId
    private static func getContentBoundsFromAXUIElement(windowId: Int, windowBounds: CGRect)
        -> CGRect?
    {
        // Get window info from CGWindowListCopyWindowInfo to find process ID
        let windowList = CGWindowListCopyWindowInfo([.optionIncludingWindow], CGWindowID(windowId))
        guard let windowArray = windowList as? [[String: AnyObject]],
            let windowInfo = windowArray.first,
            let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int32
        else {
            return getFallbackContentBounds(windowBounds: windowBounds)
        }

        // Create AXUIElement for the application
        let appElement = AXUIElementCreateApplication(ownerPID)

        // Get windows for this application
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
            let windowsArray = windowsRef as? NSArray
        else {
            return getFallbackContentBounds(windowBounds: windowBounds)
        }

        let windows = windowsArray as! [AXUIElement]

        // Find the specific window by matching bounds
        for windowElement in windows {
            if let contentBounds = getContentBoundsFromWindowElement(
                windowElement,
                targetBounds: windowBounds,
                windowId: windowId
            ) {
                return contentBounds
            }
        }

        return getFallbackContentBounds(windowBounds: windowBounds)
    }

    /// Get content bounds from a specific AXUIElement window
    private static func getContentBoundsFromWindowElement(
        _ windowElement: AXUIElement,
        targetBounds: CGRect,
        windowId: Int
    ) -> CGRect? {
        // Get window position
        var positionRef: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(
            windowElement, kAXPositionAttribute as CFString, &positionRef)

        // Get window size
        var sizeRef: CFTypeRef?
        let sizeResult = AXUIElementCopyAttributeValue(
            windowElement, kAXSizeAttribute as CFString, &sizeRef)

        guard positionResult == .success,
            sizeResult == .success,
            let positionValue = positionRef,
            let sizeValue = sizeRef
        else { return nil }

        // Convert CF types to CGPoint and CGSize
        var windowPosition = CGPoint.zero
        var windowSize = CGSize.zero

        let positionSuccess = AXValueGetValue(positionValue as! AXValue, .cgPoint, &windowPosition)
        let sizeSuccess = AXValueGetValue(sizeValue as! AXValue, .cgSize, &windowSize)

        guard positionSuccess && sizeSuccess else { return nil }

        let windowFrame = CGRect(origin: windowPosition, size: windowSize)

        // Check if this matches our target window bounds (exact match)
        guard windowFrame == targetBounds else { return nil }

        // Try to get content area using AXMain attribute
        var mainGroupRef: CFTypeRef?
        let mainGroupResult = AXUIElementCopyAttributeValue(
            windowElement, kAXMainAttribute as CFString, &mainGroupRef)

        if mainGroupResult == .success, let mainGroup = mainGroupRef {
            var mainPositionRef: CFTypeRef?
            var mainSizeRef: CFTypeRef?

            let mainPosResult = AXUIElementCopyAttributeValue(
                mainGroup as! AXUIElement, kAXPositionAttribute as CFString, &mainPositionRef)
            let mainSizeResult = AXUIElementCopyAttributeValue(
                mainGroup as! AXUIElement, kAXSizeAttribute as CFString, &mainSizeRef)

            if mainPosResult == .success && mainSizeResult == .success,
                let mainPosValue = mainPositionRef,
                let mainSizeValue = mainSizeRef
            {

                var mainPosition = CGPoint.zero
                var mainSize = CGSize.zero

                let mainPosSuccess = AXValueGetValue(
                    mainPosValue as! AXValue, .cgPoint, &mainPosition)
                let mainSizeSuccess = AXValueGetValue(mainSizeValue as! AXValue, .cgSize, &mainSize)

                if mainPosSuccess && mainSizeSuccess {
                    return CGRect(origin: mainPosition, size: mainSize)
                }
            }
        }

        // If AXMain doesn't work, try to find content view by examining children
        if let contentBounds = findContentAreaFromChildren(windowElement, windowFrame: windowFrame)
        {
            return contentBounds
        }

        // Fallback: use default titlebar height
        let defaultTitlebarHeight: CGFloat = 28.0
        return CGRect(
            x: windowFrame.origin.x,
            y: windowFrame.origin.y + defaultTitlebarHeight,
            width: windowFrame.size.width,
            height: windowFrame.size.height - defaultTitlebarHeight
        )
    }

    /// Try to find content area by examining window children
    private static func findContentAreaFromChildren(
        _ windowElement: AXUIElement, windowFrame: CGRect
    ) -> CGRect? {
        var childrenRef: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(
            windowElement, kAXChildrenAttribute as CFString, &childrenRef)

        guard childrenResult == .success,
            let childrenArray = childrenRef as? NSArray
        else { return nil }

        let children = childrenArray as! [AXUIElement]

        // Look for the main content view (usually the largest child)
        var largestChild: (element: AXUIElement, frame: CGRect)?

        for child in children {
            var childPositionRef: CFTypeRef?
            var childSizeRef: CFTypeRef?

            let childPosResult = AXUIElementCopyAttributeValue(
                child, kAXPositionAttribute as CFString, &childPositionRef)
            let childSizeResult = AXUIElementCopyAttributeValue(
                child, kAXSizeAttribute as CFString, &childSizeRef)

            guard childPosResult == .success,
                childSizeResult == .success,
                let childPosValue = childPositionRef,
                let childSizeValue = childSizeRef
            else { continue }

            var childPosition = CGPoint.zero
            var childSize = CGSize.zero

            let childPosSuccess = AXValueGetValue(
                childPosValue as! AXValue, .cgPoint, &childPosition)
            let childSizeSuccess = AXValueGetValue(childSizeValue as! AXValue, .cgSize, &childSize)

            guard childPosSuccess && childSizeSuccess else { continue }

            let childFrame = CGRect(origin: childPosition, size: childSize)
            let childArea = childFrame.width * childFrame.height

            if largestChild == nil
                || childArea > (largestChild!.frame.width * largestChild!.frame.height)
            {
                largestChild = (child, childFrame)
            }
        }

        return largestChild?.frame
    }

    /// Check if a window is in fullscreen mode
    private static func isFullscreenWindow(windowFrame: CGRect) -> Bool {
        // Get screen dimensions
        guard let mainScreen = NSScreen.main else { return false }
        let screenFrame = mainScreen.frame

        // Check if window covers the entire screen (exact match)
        let coversWidth = windowFrame.width == screenFrame.width
        let coversHeight = windowFrame.height == screenFrame.height
        let isAtOrigin =
            windowFrame.origin.x == screenFrame.origin.x
            && windowFrame.origin.y == screenFrame.origin.y

        // Also check for multiple displays
        if !coversWidth || !coversHeight || !isAtOrigin {
            // Check against all available screens
            for screen in NSScreen.screens {
                let frame = screen.frame
                let coversScreenWidth = windowFrame.width == frame.width
                let coversScreenHeight = windowFrame.height == frame.height
                let isAtScreenOrigin =
                    windowFrame.origin.x == frame.origin.x && windowFrame.origin.y == frame.origin.y

                if coversScreenWidth && coversScreenHeight && isAtScreenOrigin {
                    return true
                }
            }
            return false
        }

        return true
    }

    /// Fallback method with standard titlebar height
    private static func getFallbackContentBounds(windowBounds: CGRect) -> CGRect {
        // Check for fullscreen first
        if isFullscreenWindow(windowFrame: windowBounds) {
            return windowBounds  // No titlebar in fullscreen
        }

        let standardTitlebarHeight: CGFloat = 28.0
        return CGRect(
            x: windowBounds.origin.x,
            y: windowBounds.origin.y + standardTitlebarHeight,
            width: windowBounds.size.width,
            height: windowBounds.size.height - standardTitlebarHeight
        )
    }
}
