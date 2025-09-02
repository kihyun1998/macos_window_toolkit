import Foundation
import Cocoa

/// Handler for application-related operations
class ApplicationHandler {
    
    /// Gets all installed applications on the system
    func getAllInstalledApplications() -> Result<[[String: Any]], ApplicationError> {
        let fileManager = FileManager.default
        var applications: [[String: Any]] = []
        
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications",
            "/System/Library/CoreServices"
        ]
        
        for path in searchPaths {
            guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: path),
                                                         includingPropertiesForKeys: [.isDirectoryKey],
                                                         options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants],
                                                         errorHandler: nil) else {
                continue
            }
            
            for case let url as URL in enumerator {
                if url.pathExtension == "app" {
                    var appInfo: [String: Any] = [:]
                    
                    let bundle = Bundle(url: url)
                    let name = bundle?.infoDictionary?["CFBundleDisplayName"] as? String ??
                              bundle?.infoDictionary?["CFBundleName"] as? String ??
                              url.deletingPathExtension().lastPathComponent
                    let bundleId = bundle?.bundleIdentifier ?? ""
                    let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    
                    appInfo["name"] = name
                    appInfo["bundleId"] = bundleId
                    appInfo["version"] = version
                    appInfo["path"] = url.path
                    
                    // Try to get icon path
                    var iconPath = ""
                    if let iconFile = bundle?.infoDictionary?["CFBundleIconFile"] as? String {
                        let iconURL = url.appendingPathComponent("Contents/Resources/\(iconFile)")
                        if fileManager.fileExists(atPath: iconURL.path) {
                            iconPath = iconURL.path
                        } else {
                            // Try with .icns extension
                            let iconWithExt = iconURL.appendingPathExtension("icns")
                            if fileManager.fileExists(atPath: iconWithExt.path) {
                                iconPath = iconWithExt.path
                            }
                        }
                    }
                    appInfo["iconPath"] = iconPath
                    
                    applications.append(appInfo)
                }
            }
        }
        
        return .success(applications)
    }
    
    /// Gets applications filtered by name
    func getApplicationByName(_ name: String) -> Result<[[String: Any]], ApplicationError> {
        let allAppsResult = getAllInstalledApplications()
        
        switch allAppsResult {
        case .success(let applications):
            let filteredApps = applications.filter { app in
                let appName = app["name"] as? String ?? ""
                return appName.localizedCaseInsensitiveContains(name)
            }
            return .success(filteredApps)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Opens Mac App Store with search query
    func openAppStoreSearch(_ searchTerm: String) -> Result<Bool, ApplicationError> {
        let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm
        let appStoreURLString = "macappstores://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?mt=12&ign-mscache=1&q=\(encodedSearchTerm)"
        
        guard let appStoreURL = URL(string: appStoreURLString) else {
            return .failure(.invalidURL)
        }
        
        let success = NSWorkspace.shared.open(appStoreURL)
        return .success(success)
    }
}

/// Enum representing application operation errors
enum ApplicationError: Error, LocalizedError {
    case failedToRetrieveApplicationList
    case applicationNotFound
    case insufficientApplicationInfo
    case failedToOpenAppStore
    case invalidURL
    case systemError(String)

    var errorDescription: String? {
        switch self {
        case .failedToRetrieveApplicationList:
            return "Failed to retrieve application list"
        case .applicationNotFound:
            return "Application not found"
        case .insufficientApplicationInfo:
            return "Insufficient application information"
        case .failedToOpenAppStore:
            return "Failed to open App Store"
        case .invalidURL:
            return "Invalid URL for App Store search"
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
}