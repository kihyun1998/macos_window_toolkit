import ApplicationServices
import Foundation

/// Finds the Accessibility element of a CoreGraphics window. The two are matched by
/// the window's title within its process.
struct AXWindowLookup {
    let permissions: PermissionChecking
    let query: WindowQuery

    /// The process ID and title of the window with this ID, once Accessibility
    /// permission is granted
    func target(_ windowId: Int) -> Result<(processId: Int, name: String), WindowError> {
        guard permissions.hasAccessibilityPermission() else {
            return .failure(.accessibilityPermissionDenied)
        }
        switch query.windowInfo(windowId) {
        case .failure(let error):
            return .failure(error)
        case .success(nil):
            return .failure(.windowNotFound)
        case .success(let window?):
            guard let processId = window.processId else {
                return .failure(.insufficientWindowInfo)
            }
            return .success((processId, window.name))
        }
    }

    /// The AX window of the window with this ID, or `missing` when the process has none
    /// that matches its title
    func element(for windowId: Int, missing: WindowError) -> Result<
        (element: AXUIElement, processId: Int), WindowError
    > {
        return target(windowId).flatMap { target in
            guard let found = element(processId: target.processId, windowName: target.name)
            else {
                return .failure(missing)
            }
            return .success((found, target.processId))
        }
    }

    /// The process's AX window for `windowName`: by `flexibleMatch`, else by `exactMatch`
    func element(processId: Int, windowName: String) -> AXUIElement? {
        return flexibleMatch(processId: processId, windowName: windowName)
            ?? exactMatch(processId: processId, windowName: windowName)
    }

    /// The first AX window whose title equals `windowName`, or the first titled one
    /// when `windowName` is empty
    private func exactMatch(processId: Int, windowName: String) -> AXUIElement? {
        guard let windows = AXUIElement.windows(ofProcess: pid_t(processId)) else {
            return nil
        }
        return windows.first { windowElement in
            guard let title: String = windowElement.attribute(kAXTitleAttribute) else {
                return false
            }
            return windowName.isEmpty || title == windowName
        }
    }

    /// The first AX window whose title equals `windowName`, else the first whose
    /// title contains it, else the first window of all when `windowName` is empty
    private func flexibleMatch(processId: Int, windowName: String) -> AXUIElement? {
        guard let windows = AXUIElement.windows(ofProcess: pid_t(processId)) else {
            return nil
        }
        func title(_ windowElement: AXUIElement) -> String? {
            return windowElement.attribute(kAXTitleAttribute)
        }
        if let exact = windows.first(where: { title($0) == windowName }) {
            return exact
        }
        if !windowName.isEmpty,
            let partial = windows.first(where: { title($0)?.contains(windowName) == true })
        {
            return partial
        }
        if windowName.isEmpty {
            return windows.first
        }
        return nil
    }
}
