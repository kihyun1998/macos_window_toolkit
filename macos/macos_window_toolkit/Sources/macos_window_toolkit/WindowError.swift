import Foundation

/// Window, Accessibility and process operation errors
enum WindowError: PluginError {
    case failedToRetrieveWindowList
    case windowNotFound
    case insufficientWindowInfo
    case accessibilityPermissionDenied
    case closeButtonNotFound
    case closeActionFailed
    case focusActionFailed
    case processNotFound
    case invalidProcessId
    case terminationFailed
    case failedToGetProcessList
    case windowNotAccessible
    case spaceSwitchAPIUnavailable
    case windowStillOpen
    case windowNotFocused

    var code: String {
        switch self {
        case .failedToRetrieveWindowList: return "FAILED_TO_RETRIEVE_WINDOW_LIST"
        case .windowNotFound: return "WINDOW_NOT_FOUND"
        case .insufficientWindowInfo: return "INSUFFICIENT_WINDOW_INFO"
        case .accessibilityPermissionDenied: return "ACCESSIBILITY_PERMISSION_DENIED"
        case .closeButtonNotFound: return "CLOSE_BUTTON_NOT_FOUND"
        case .closeActionFailed: return "CLOSE_ACTION_FAILED"
        case .focusActionFailed: return "FOCUS_ACTION_FAILED"
        case .processNotFound: return "PROCESS_NOT_FOUND"
        case .invalidProcessId: return "INVALID_PROCESS_ID"
        case .terminationFailed: return "TERMINATION_FAILED"
        case .failedToGetProcessList: return "FAILED_TO_GET_PROCESS_LIST"
        case .windowNotAccessible: return "WINDOW_NOT_ACCESSIBLE"
        case .spaceSwitchAPIUnavailable: return "SPACE_SWITCH_API_UNAVAILABLE"
        case .windowStillOpen: return "WINDOW_STILL_OPEN"
        case .windowNotFocused: return "WINDOW_NOT_FOCUSED"
        }
    }

    var stateReason: String? {
        switch self {
        case .windowNotFound: return "window_not_found"
        case .accessibilityPermissionDenied: return "accessibility_permission_denied"
        case .closeButtonNotFound: return "close_button_not_found"
        case .focusActionFailed: return "focus_action_failed"
        case .processNotFound, .invalidProcessId: return "process_not_found"
        case .windowNotAccessible: return "window_not_accessible"
        case .windowStillOpen: return "window_still_open"
        case .windowNotFocused: return "window_not_focused"
        case .failedToRetrieveWindowList, .insufficientWindowInfo, .closeActionFailed,
            .terminationFailed, .failedToGetProcessList, .spaceSwitchAPIUnavailable:
            return nil
        }
    }

    var message: String {
        switch self {
        case .failedToRetrieveWindowList: return "Failed to retrieve window list"
        case .windowNotFound: return "Window not found"
        case .insufficientWindowInfo: return "Insufficient window information"
        case .accessibilityPermissionDenied: return "Accessibility permission is required"
        case .closeButtonNotFound: return "Could not find close button for the specified window"
        case .closeActionFailed: return "Failed to perform close action on window"
        case .focusActionFailed: return "Failed to focus window"
        case .processNotFound: return "Process not found"
        case .invalidProcessId: return "Process ID must be greater than 1 and fit in a pid_t"
        case .terminationFailed: return "Failed to terminate process"
        case .failedToGetProcessList: return "Failed to retrieve process list"
        case .windowNotAccessible: return "Window is not accessible via Accessibility API"
        case .spaceSwitchAPIUnavailable: return "Private CGS Space APIs are not available"
        case .windowStillOpen: return "Window is still open"
        case .windowNotFocused: return "Window did not become focused"
        }
    }

    var details: String? {
        switch self {
        case .failedToRetrieveWindowList:
            return nil
        case .windowNotFound:
            return "The specified window could not be found. It may have been closed or the ID is invalid."
        case .insufficientWindowInfo:
            return "Unable to retrieve necessary information (process ID or window name) to perform the operation."
        case .accessibilityPermissionDenied:
            return "Please grant accessibility permission in System Settings > Privacy & Security > Accessibility"
        case .closeButtonNotFound:
            return "The window structure may not support programmatic closing via Accessibility API."
        case .closeActionFailed:
            return "The close button was found but clicking it failed."
        case .focusActionFailed:
            return "The raise action was found but executing it failed."
        case .processNotFound:
            return "The specified process ID does not exist or has already terminated."
        case .invalidProcessId:
            return "PID 0 and negative PIDs address process groups, PID 1 is launchd, and a value outside Int32 is no PID. Nothing was signalled."
        case .terminationFailed:
            return "The process could not be terminated. It may require elevated privileges."
        case .failedToGetProcessList:
            return "Unable to query system process information."
        case .windowNotAccessible:
            return "The window exists but cannot be accessed. It may be on a different Space, or the application does not support the Accessibility API."
        case .spaceSwitchAPIUnavailable:
            return "The window is on a different Space but the required private APIs are unavailable on this macOS version."
        case .windowStillOpen:
            return "The close button was pressed, but the window did not close within the requested time. The app may be asking whether to save changes."
        case .windowNotFocused:
            return "Focus was requested, but the window was not the focused window of the frontmost app within the requested time. macOS activates another app only when the calling app is frontmost."
        }
    }
}
