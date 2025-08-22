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

    /// Checks if a specific macOS version is supported
    /// - Parameter minimumVersion: Minimum version in format "major.minor.patch"
    /// - Returns: True if current version meets or exceeds the minimum
    static func isMacOSVersionSupported(minimumVersion: String) -> Bool {
        let currentVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionComponents = minimumVersion.split(separator: ".").compactMap { Int($0) }

        guard versionComponents.count >= 2 else { return false }

        let requiredMajor = versionComponents[0]
        let requiredMinor = versionComponents[1]
        let requiredPatch = versionComponents.count > 2 ? versionComponents[2] : 0

        if currentVersion.majorVersion > requiredMajor {
            return true
        } else if currentVersion.majorVersion == requiredMajor {
            if currentVersion.minorVersion > requiredMinor {
                return true
            } else if currentVersion.minorVersion == requiredMinor {
                return currentVersion.patchVersion >= requiredPatch
            }
        }

        return false
    }
}
