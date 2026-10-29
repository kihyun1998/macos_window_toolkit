import ApplicationServices
import CoreGraphics
import Foundation

/// Per-listing-call cache for Accessibility role lookups: an application's window
/// titles are read at most once per PID.
private final class AXRoleResolver {

    private struct AXWindowEntry {
        let element: AXUIElement
        let title: String
    }

    private var entriesByPid: [pid_t: [AXWindowEntry]] = [:]

    /// Returns the role and subrole for the first AX window of the process
    /// whose title matches `windowName` (any titled window when `windowName` is
    /// empty)
    func role(processId: Int, windowName: String) -> (role: String?, subrole: String?) {
        let pid = pid_t(processId)
        let entries: [AXWindowEntry]
        if let cached = entriesByPid[pid] {
            entries = cached
        } else {
            entries = Self.fetchEntries(pid: pid)
            entriesByPid[pid] = entries
        }

        for entry in entries where windowName.isEmpty || entry.title == windowName {
            return (entry.element.attribute(kAXRoleAttribute),
                    entry.element.attribute(kAXSubroleAttribute))
        }

        return (nil, nil)
    }

    /// The process's AX windows that have a title, in the order the app lists them
    private static func fetchEntries(pid: pid_t) -> [AXWindowEntry] {
        return (AXUIElement.windows(ofProcess: pid) ?? []).compactMap { windowElement in
            let title: String? = windowElement.attribute(kAXTitleAttribute)
            return title.map { AXWindowEntry(element: windowElement, title: $0) }
        }
    }
}

/// Lists windows from CoreGraphics, including those on other Spaces and minimized ones
struct WindowQuery {

    /// Every window the CoreGraphics window list holds, in its order
    func windowInfos() -> Result<[WindowInfo], WindowError> {
        guard
            let windowList = CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]]
        else {
            return .failure(.failedToRetrieveWindowList)
        }
        return .success(windowList.map(WindowInfo.init))
    }

    /// The window with this ID, or nil when the window list has none
    func windowInfo(_ windowId: Int) -> Result<WindowInfo?, WindowError> {
        return windowInfos().map { windows in windows.first { $0.windowId == windowId } }
    }

    /// The maps sent to Dart for the windows `filter` accepts, each with its
    /// Accessibility role and subrole when the process can read them
    func windows(where filter: (WindowInfo) -> Bool) -> Result<[[String: Any]], WindowError> {
        return windowInfos().map { windows in
            let roleResolver = AXRoleResolver()
            return windows.filter(filter).map { window in
                guard let processId = window.processId else {
                    return window.dictionary(role: nil, subrole: nil)
                }
                let roleInfo = roleResolver.role(processId: processId, windowName: window.name)
                return window.dictionary(role: roleInfo.role, subrole: roleInfo.subrole)
            }
        }
    }

    /// Every window, without the untitled ones when `excludeEmptyNames` holds
    func getAllWindows(excludeEmptyNames: Bool = false) -> Result<[[String: Any]], WindowError> {
        return windows { !excludeEmptyNames || !$0.name.isEmpty }
    }

    /// The windows whose title contains `name`, case-sensitively
    func getWindowsByName(_ name: String) -> Result<[[String: Any]], WindowError> {
        return windows { $0.name.contains(name) }
    }

    /// The windows whose owner name contains `ownerName`, case-sensitively
    func getWindowsByOwnerName(_ ownerName: String) -> Result<[[String: Any]], WindowError> {
        return windows { $0.ownerName.contains(ownerName) }
    }

    /// The window with this ID, as a list of at most one
    func getWindowById(_ windowId: Int) -> Result<[[String: Any]], WindowError> {
        return windows { $0.windowId == windowId }
    }

    /// The windows owned by the process with this ID
    func getWindowsByProcessId(_ processId: Int) -> Result<[[String: Any]], WindowError> {
        return windows { $0.processId == processId }
    }

    /// The windows that meet every condition given. A nil condition is not checked, and
    /// a window that lacks a field a condition reads does not meet it.
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
        return windows { window in
            if let windowId = windowId, window.windowId != windowId {
                return false
            }
            if let name = name,
                !PatternMatcher.matches(
                    window.name, pattern: name, exactMatch: nameExactMatch ?? false,
                    caseSensitive: nameCaseSensitive ?? true, wildcard: nameWildcard ?? false)
            {
                return false
            }
            if let ownerName = ownerName,
                !PatternMatcher.matches(
                    window.ownerName, pattern: ownerName,
                    exactMatch: ownerNameExactMatch ?? false,
                    caseSensitive: ownerNameCaseSensitive ?? true,
                    wildcard: ownerNameWildcard ?? false)
            {
                return false
            }
            if let processId = processId, window.processId != processId {
                return false
            }
            if let isOnScreen = isOnScreen, window.isOnScreen != isOnScreen {
                return false
            }
            if let layer = layer, window.layer != layer {
                return false
            }
            if x != nil || y != nil || width != nil || height != nil {
                guard let bounds = window.bounds else { return false }
                if let x = x, bounds.x != x { return false }
                if let y = y, bounds.y != y { return false }
                if let width = width, bounds.width != width { return false }
                if let height = height, bounds.height != height { return false }
            }
            return true
        }
    }

    /// Whether the window with this ID exists and, when `expectedName` is given, has
    /// exactly that title. Any failure reads as false.
    func isWindowAlive(_ windowId: Int, expectedName: String? = nil) -> Bool {
        guard case .success(let window?) = windowInfo(windowId) else {
            return false
        }
        if let expectedName = expectedName {
            return window.name == expectedName
        }
        return true
    }
}
