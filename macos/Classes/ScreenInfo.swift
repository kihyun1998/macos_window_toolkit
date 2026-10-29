import Cocoa

/// Describes the connected screens
enum ScreenInfo {
    /// The main screen's backing scale factor, or 1.0 when there is no main screen
    static func mainScaleFactor() -> CGFloat {
        return NSScreen.main?.backingScaleFactor ?? 1.0
    }

    /// Every connected screen, in `NSScreen.screens` order, with Cocoa frames
    static func allScreens() -> [[String: Any]] {
        return NSScreen.screens.enumerated().map { (index, screen) -> [String: Any] in
            let isMain = (screen == NSScreen.main)
            return [
                "index": index,
                "isMain": isMain,
                "scaleFactor": screen.backingScaleFactor,
                "frame": [
                    "x": screen.frame.origin.x,
                    "y": screen.frame.origin.y,
                    "width": screen.frame.width,
                    "height": screen.frame.height,
                ],
                "visibleFrame": [
                    "x": screen.visibleFrame.origin.x,
                    "y": screen.visibleFrame.origin.y,
                    "width": screen.visibleFrame.width,
                    "height": screen.visibleFrame.height,
                ],
                "pixelWidth": Int(screen.frame.width * screen.backingScaleFactor),
                "pixelHeight": Int(screen.frame.height * screen.backingScaleFactor),
            ]
        }
    }
}
