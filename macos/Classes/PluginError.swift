import FlutterMacOS
import Foundation

/// A failure the plugin reports to Dart, described once where it is raised.
protocol PluginError: Error {
    /// The wire code, such as `WINDOW_NOT_FOUND`
    var code: String { get }
    /// The wire reason when this failure is a state the caller handles, or nil
    /// when it is reported as a `FlutterError`
    var stateReason: String? { get }
    var message: String { get }
    var details: String? { get }
    /// The underlying `NSError` code and domain, when there is one
    var nativeErrorCode: Int? { get }
    var nativeErrorDomain: String? { get }
}

extension PluginError {
    var nativeErrorCode: Int? { nil }
    var nativeErrorDomain: String? { nil }

    /// The fields sent with this failure, under `code` or the call's own code
    func payload(code overridingCode: String? = nil) -> [String: Any] {
        return [
            "code": overridingCode ?? code,
            "message": message,
            "details": details ?? NSNull(),
            "errorCode": nativeErrorCode ?? NSNull(),
            "errorDomain": nativeErrorDomain ?? NSNull(),
        ]
    }

    /// Replies to Dart with this failure: as a state map when it is a state and
    /// `allowState` holds, otherwise as a `FlutterError` whose details carry the
    /// same fields. `code` replaces the wire code for calls that report every
    /// failure under one code of their own.
    func reply(to result: FlutterResult, code overridingCode: String? = nil, allowState: Bool = true) {
        var fields = payload(code: overridingCode)
        if allowState, let reason = stateReason {
            fields["success"] = false
            fields["reason"] = reason
            result(fields)
        } else {
            result(
                FlutterError(
                    code: overridingCode ?? code, message: message, details: fields))
        }
    }
}

/// A failure the dispatcher raises itself, outside any handler's error type.
struct DispatcherError: PluginError {
    let code: String
    let message: String
    let details: String?
    var stateReason: String? { nil }

    /// A required argument that is missing or has the wrong type
    static func missingArgument(_ message: String) -> DispatcherError {
        return DispatcherError(code: "INVALID_ARGUMENTS", message: message, details: nil)
    }
}
