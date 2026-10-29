import Foundation

/// Utility class for checking macOS version and capability information
class VersionUtil {

    /// Checks if ScreenCaptureKit is available (macOS 12.3+)
    static func isScreenCaptureKitAvailable() -> Bool {
        if #available(macOS 12.3, *) {
            return true
        }
        return false
    }

    /// Gets the current macOS version as a string
    static func getMacOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// Gets detailed macOS version information
    static func getMacOSVersionInfo() -> [String: Any] {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return [
            "majorVersion": version.majorVersion,
            "minorVersion": version.minorVersion,
            "patchVersion": version.patchVersion,
            "versionString":
                "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)",
            "isScreenCaptureKitAvailable": isScreenCaptureKitAvailable(),
        ]
    }
}
