import Cocoa
import Foundation

// MARK: - Private CGS Space API Declarations

private typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
private func _cgsMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSGetActiveSpace")
private func _cgsGetActiveSpace(_ cid: CGSConnectionID) -> UInt64

@_silgen_name("CGSCopySpacesForWindows")
private func _cgsCopySpacesForWindows(_ cid: CGSConnectionID, _ mask: Int32, _ windows: CFArray) -> CFArray

@_silgen_name("CGSManagedDisplaySetCurrentSpace")
private func _cgsManagedDisplaySetCurrentSpace(_ cid: CGSConnectionID, _ display: CFTypeRef, _ spaceID: UInt64)

/// The Space operations a Space-switch close needs
protocol SpaceControl {
    /// Whether the private calls the other members make exist at runtime
    var isAvailable: Bool { get }
    /// The Space that holds the window, or nil when there is none
    func space(ofWindow windowId: Int) -> UInt64?
    /// The Space the user is on now
    func activeSpace() -> UInt64
    /// The display that shows the window, or the main display
    func display(ofWindow windowId: Int) -> CGDirectDisplayID
    /// Makes `space` the current Space on `display`
    func activate(_ space: UInt64, on display: CGDirectDisplayID)
}

/// `SpaceControl` through the private CoreGraphics Services (CGS) calls
struct CGSSpaces: SpaceControl {
    var isAvailable: Bool {
        let requiredSymbols = [
            "CGSMainConnectionID",
            "CGSGetActiveSpace",
            "CGSCopySpacesForWindows",
            "CGSManagedDisplaySetCurrentSpace",
        ]
        return requiredSymbols.allSatisfy {
            dlsym(UnsafeMutableRawPointer(bitPattern: -2), $0) != nil
        }
    }

    func space(ofWindow windowId: Int) -> UInt64? {
        let windowsArray = [NSNumber(value: CGWindowID(windowId))] as CFArray
        let spaces = _cgsCopySpacesForWindows(_cgsMainConnectionID(), 7, windowsArray) as? [NSNumber]
        return spaces?.first.map { $0.uint64Value }
    }

    func activeSpace() -> UInt64 {
        return _cgsGetActiveSpace(_cgsMainConnectionID())
    }

    func display(ofWindow windowId: Int) -> CGDirectDisplayID {
        guard case .success(let windows) = WindowQuery().windowInfos() else {
            return CGMainDisplayID()
        }
        for window in windows where window.windowId == windowId {
            guard let bounds = window.bounds else { continue }
            let rect = CGRect(x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height)
            var displayCount: UInt32 = 0
            var displayIDs = [CGDirectDisplayID](repeating: 0, count: 8)
            if CGGetDisplaysWithRect(rect, 8, &displayIDs, &displayCount) == .success,
                displayCount > 0
            {
                return displayIDs[0]
            }
        }
        return CGMainDisplayID()
    }

    func activate(_ space: UInt64, on display: CGDirectDisplayID) {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(display),
            let uuidString = CFUUIDCreateString(nil, uuid.takeRetainedValue())
        else {
            return
        }
        _cgsManagedDisplaySetCurrentSpace(_cgsMainConnectionID(), uuidString, space)
    }
}

/// Closes windows that sit on another Space by switching to that Space, pressing the
/// close button there and switching back. Closes run one at a time.
final class SpaceSwitcher {
    private let spaces: SpaceControl
    private let gate = SerialGate()
    private let pollInterval: TimeInterval
    private let pollTimeout: TimeInterval

    /// `pollInterval` and `pollTimeout` pace the wait for the window to become
    /// reachable after the switch
    init(
        spaces: SpaceControl = CGSSpaces(), pollInterval: TimeInterval = 0.05,
        pollTimeout: TimeInterval = 1.0
    ) {
        self.spaces = spaces
        self.pollInterval = pollInterval
        self.pollTimeout = pollTimeout
    }

    /// Switches to the window's Space, polls `find` on the main queue until it returns
    /// the window, hands it to `press`, and switches back to the original Space before
    /// calling `completion`. The next close starts once this one has switched back.
    /// When `releasesBeforeCompletion` holds, the next close may start before
    /// `completion` is called; otherwise it starts after.
    func close<Element>(
        windowId: Int, releasesBeforeCompletion: Bool,
        find: @escaping () -> Element?,
        press: @escaping (Element) -> Result<Element, WindowError>,
        completion: @escaping (Result<Element, WindowError>) -> Void
    ) {
        gate.run { done in
            self.switchAndPress(windowId: windowId, find: find, press: press) { result in
                if releasesBeforeCompletion {
                    done()
                    completion(result)
                } else {
                    completion(result)
                    done()
                }
            }
        }
    }

    private func switchAndPress<Element>(
        windowId: Int, find: @escaping () -> Element?,
        press: @escaping (Element) -> Result<Element, WindowError>,
        completion: @escaping (Result<Element, WindowError>) -> Void
    ) {
        guard spaces.isAvailable else {
            completion(.failure(.spaceSwitchAPIUnavailable))
            return
        }
        guard let targetSpace = spaces.space(ofWindow: windowId) else {
            completion(.failure(.windowNotAccessible))
            return
        }

        let originalSpace = spaces.activeSpace()
        let display = spaces.display(ofWindow: windowId)
        let needsSwitch = originalSpace != targetSpace
        if needsSwitch {
            spaces.activate(targetSpace, on: display)
        }

        pollOnMain(every: pollInterval, for: pollTimeout, attempt: find) { element in
            let result = element.map(press) ?? .failure(.windowNotAccessible)
            if needsSwitch {
                self.spaces.activate(originalSpace, on: display)
            }
            completion(result)
        }
    }
}
