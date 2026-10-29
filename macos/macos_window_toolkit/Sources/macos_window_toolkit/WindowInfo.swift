import CoreGraphics
import Foundation

/// One entry of the CoreGraphics window list. A field the entry lacks is nil, so a
/// filter can tell a missing value from a default one; `dictionary` fills the defaults.
struct WindowInfo {
    /// A window's position and size, each 0 when the entry's bounds lack it
    struct Bounds {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }

    let windowId: Int?
    /// The title, or empty when the entry has none
    let name: String
    /// The owning application's name, or empty when the entry has none
    let ownerName: String
    let bounds: Bounds?
    let layer: Int?
    let isOnScreen: Bool?
    let processId: Int?
    let storeType: Int?
    let sharingState: Int?
    let alpha: Double?
    let memoryUsage: Int?
    let isInVideoMemory: Bool?

    /// Reads a `CGWindowListCopyWindowInfo` entry
    init(_ entry: [String: Any]) {
        windowId = (entry[kCGWindowNumber as String] as? NSNumber)?.intValue
        name = entry[kCGWindowName as String] as? String ?? ""
        ownerName = entry[kCGWindowOwnerName as String] as? String ?? ""
        bounds = (entry[kCGWindowBounds as String] as? [String: Any]).map { bounds in
            Bounds(
                x: bounds["X"] as? Double ?? 0,
                y: bounds["Y"] as? Double ?? 0,
                width: bounds["Width"] as? Double ?? 0,
                height: bounds["Height"] as? Double ?? 0)
        }
        layer = (entry[kCGWindowLayer as String] as? NSNumber)?.intValue
        isOnScreen = (entry[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue
        processId = (entry[kCGWindowOwnerPID as String] as? NSNumber)?.intValue
        storeType = (entry[kCGWindowStoreType as String] as? NSNumber)?.intValue
        sharingState = (entry[kCGWindowSharingState as String] as? NSNumber)?.intValue
        alpha = (entry[kCGWindowAlpha as String] as? NSNumber)?.doubleValue
        memoryUsage = (entry[kCGWindowMemoryUsage as String] as? NSNumber)?.intValue
        isInVideoMemory =
            (entry[kCGWindowBackingLocationVideoMemory as String] as? NSNumber)?.boolValue
    }

    /// The map sent to Dart for this window, with its Accessibility role and subrole
    func dictionary(role: String?, subrole: String?) -> [String: Any] {
        var window: [String: Any] = [
            "name": name,
            "ownerName": ownerName,
            "x": bounds?.x ?? 0.0,
            "y": bounds?.y ?? 0.0,
            "width": bounds?.width ?? 0.0,
            "height": bounds?.height ?? 0.0,
            "layer": layer ?? 0,
            "isOnScreen": isOnScreen ?? false,
        ]
        window["windowId"] = windowId
        window["processId"] = processId
        window["role"] = role
        window["subrole"] = subrole
        window["storeType"] = storeType
        window["sharingState"] = sharingState
        window["alpha"] = alpha
        window["memoryUsage"] = memoryUsage
        window["isInVideoMemory"] = isInVideoMemory
        return window
    }
}
