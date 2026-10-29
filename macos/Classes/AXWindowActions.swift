import ApplicationServices
import Cocoa
import Foundation

/// Closes, focuses and reads the scroll bars of windows through the Accessibility API
final class AXWindowActions {
    private let lookup: AXWindowLookup
    private let spaceSwitcher: SpaceSwitcher

    init(
        permissions: PermissionChecking = PermissionHandler(), query: WindowQuery = WindowQuery(),
        spaceSwitcher: SpaceSwitcher = SpaceSwitcher()
    ) {
        self.lookup = AXWindowLookup(permissions: permissions, query: query)
        self.spaceSwitcher = spaceSwitcher
    }

    // MARK: - Close

    /// Presses the window's close button and calls `completion` with the result: at once,
    /// or on the main queue after a Space switch when the window is on another Space.
    /// Without `waitUntilClosed` it succeeds once the close button is pressed. With it, it
    /// succeeds once the pressed window is destroyed, and fails with `windowStillOpen` when
    /// the window is still open after `waitUntilClosed` seconds.
    func closeWindow(
        _ windowId: Int, waitUntilClosed: TimeInterval? = nil,
        completion: @escaping (Result<Bool, WindowError>) -> Void
    ) {
        let finish: (Result<AXUIElement, WindowError>) -> Void = { pressed in
            switch pressed {
            case .failure(let error):
                completion(.failure(error))
            case .success(let window):
                guard let wait = waitUntilClosed else {
                    completion(.success(true))
                    return
                }
                AXUIElementSetMessagingTimeout(window, 0.1)
                pollOnMain(every: 0.05, for: wait, attempt: {
                    AXWindowActions.isDestroyed(window) ? true : nil
                }) { closed in
                    completion(closed == nil ? .failure(.windowStillOpen) : .success(true))
                }
            }
        }

        let processId: Int
        let windowName: String
        switch lookup.target(windowId) {
        case .failure(let error):
            finish(.failure(error))
            return
        case .success(let target):
            (processId, windowName) = target
        }

        guard let window = lookup.element(processId: processId, windowName: windowName) else {
            spaceSwitcher.close(
                windowId: windowId, releasesBeforeCompletion: waitUntilClosed != nil,
                find: { self.lookup.element(processId: processId, windowName: windowName) },
                press: pressClose, completion: finish)
            return
        }
        finish(pressClose(window))
    }

    /// Whether `element` no longer refers to a live window: it reads as an invalid element,
    /// or its process has exited. A window on another Space stays live, and so does a
    /// window whose app does not answer in time.
    static func isDestroyed(_ element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        let read = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        if read == .invalidUIElement { return true }
        var pid: pid_t = 0
        guard read != .success, AXUIElementGetPid(element, &pid) == .success, pid > 0 else {
            return false
        }
        return kill(pid, 0) == -1 && errno == ESRCH
    }

    /// Presses the window's close button, and returns the window once it is pressed
    private func pressClose(_ window: AXUIElement) -> Result<AXUIElement, WindowError> {
        guard let closeButton = findCloseButton(for: window) else {
            return .failure(.closeButtonNotFound)
        }
        guard AXUIElementPerformAction(closeButton, kAXPressAction as CFString) == .success else {
            return .failure(.closeActionFailed)
        }
        return .success(window)
    }

    /// The window's close button: its close button attribute, else a button among its
    /// descendants
    private func findCloseButton(for windowElement: AXUIElement) -> AXUIElement? {
        if let closeButton = windowElement.elementAttribute(kAXCloseButtonAttribute) {
            return closeButton
        }
        let children: [AXUIElement] = windowElement.attribute(kAXChildrenAttribute) ?? []
        for child in children {
            if let closeButton = searchForCloseButton(in: child, depth: 0, maxDepth: 3) {
                return closeButton
            }
        }
        return nil
    }

    /// The first button at or below `element`, down to `maxDepth`, whose subrole is
    /// `AXCloseButton` or whose description contains "close"
    private func searchForCloseButton(in element: AXUIElement, depth: Int, maxDepth: Int)
        -> AXUIElement?
    {
        guard depth <= maxDepth else { return nil }

        let role: String? = element.attribute(kAXRoleAttribute)
        if role == kAXButtonRole {
            let subrole: String? = element.attribute(kAXSubroleAttribute)
            if subrole == kAXCloseButtonSubrole {
                return element
            }
            let description: String? = element.attribute(kAXDescriptionAttribute)
            if description?.lowercased().contains("close") == true {
                return element
            }
        }

        let children: [AXUIElement] = element.attribute(kAXChildrenAttribute) ?? []
        for child in children {
            if let closeButton = searchForCloseButton(
                in: child, depth: depth + 1, maxDepth: maxDepth)
            {
                return closeButton
            }
        }
        return nil
    }

    // MARK: - Focus

    /// Makes the window its app's main window, activates the app and raises the window.
    /// It succeeds when either Accessibility call does.
    func focusWindow(_ windowId: Int) -> Result<Bool, WindowError> {
        let element: AXUIElement
        let processId: Int
        switch lookup.element(for: windowId, missing: .windowNotFound) {
        case .failure(let error):
            return .failure(error)
        case .success(let found):
            (element, processId) = found
        }

        let setMainResult = AXUIElementSetAttributeValue(
            element, kAXMainAttribute as CFString, kCFBooleanTrue)

        if let app = NSRunningApplication(processIdentifier: pid_t(processId)) {
            app.activate(options: [.activateIgnoringOtherApps])
        }

        let raiseResult = AXUIElementPerformAction(element, kAXRaiseAction as CFString)

        if setMainResult == .success || raiseResult == .success {
            return .success(true)
        }
        return .failure(.focusActionFailed)
    }

    // MARK: - Scroll

    /// Which scroll bars a window has, and where each sits from 0.0 to 1.0
    private struct ScrollInfo {
        var verticalPosition: Double?
        var horizontalPosition: Double?
        var hasVerticalScroll = false
        var hasHorizontalScroll = false

        var hasAny: Bool { hasVerticalScroll || hasHorizontalScroll }

        var dictionary: [String: Any] {
            var info: [String: Any] = [
                "hasVerticalScroll": hasVerticalScroll,
                "hasHorizontalScroll": hasHorizontalScroll,
            ]
            info["verticalPosition"] = verticalPosition
            info["horizontalPosition"] = horizontalPosition
            return info
        }
    }

    /// The window's scroll bars, read from the first scroll area that has one
    func getScrollInfo(_ windowId: Int) -> Result<[String: Any], WindowError> {
        return lookup.element(for: windowId, missing: .windowNotAccessible).map {
            scrollInfo(of: $0.element).dictionary
        }
    }

    /// Tries, in order, a scroll area among the window's children, the window itself and
    /// a scroll area deeper in the window, and stops at the first with a scroll bar
    private func scrollInfo(of element: AXUIElement) -> ScrollInfo {
        var info = ScrollInfo()

        if let scrollArea = findScrollArea(in: element) {
            readScrollBars(of: scrollArea, into: &info)
        }
        if !info.hasAny {
            readScrollBars(of: element, into: &info)
        }
        if !info.hasAny,
            let scrollArea = findScrollAreaRecursively(in: element, depth: 0, maxDepth: 5)
        {
            readScrollBars(of: scrollArea, into: &info)
        }
        return info
    }

    /// Whether the element's role is `AXScrollArea`
    private func isScrollArea(_ element: AXUIElement) -> Bool {
        let role: String? = element.attribute(kAXRoleAttribute)
        return role == "AXScrollArea"
    }

    /// The first `AXScrollArea` among the element's direct children
    private func findScrollArea(in element: AXUIElement) -> AXUIElement? {
        let children: [AXUIElement]? = element.attribute(kAXChildrenAttribute)
        return children?.first { isScrollArea($0) }
    }

    /// The first `AXScrollArea` below the element, depth first, above `maxDepth`
    private func findScrollAreaRecursively(in element: AXUIElement, depth: Int, maxDepth: Int)
        -> AXUIElement?
    {
        guard depth < maxDepth,
            let children: [AXUIElement] = element.attribute(kAXChildrenAttribute)
        else {
            return nil
        }

        for child in children {
            if isScrollArea(child) {
                return child
            }
            if let found = findScrollAreaRecursively(
                in: child, depth: depth + 1, maxDepth: maxDepth)
            {
                return found
            }
        }
        return nil
    }

    /// Reads the element's vertical and horizontal scroll bars into `info`
    private func readScrollBars(of element: AXUIElement, into info: inout ScrollInfo) {
        if let verticalScrollBar = element.attributeValue(kAXVerticalScrollBarAttribute) {
            info.hasVerticalScroll = true
            info.verticalPosition = position(of: verticalScrollBar) ?? info.verticalPosition
        }
        if let horizontalScrollBar = element.attributeValue(kAXHorizontalScrollBarAttribute) {
            info.hasHorizontalScroll = true
            info.horizontalPosition = position(of: horizontalScrollBar) ?? info.horizontalPosition
        }
    }

    /// The scroll bar's value, when the bar is an element whose value is a number
    private func position(of scrollBar: CFTypeRef) -> Double? {
        let value: NSNumber? = AXUIElement.element(from: scrollBar)?.attribute(kAXValueAttribute)
        return value?.doubleValue
    }
}
