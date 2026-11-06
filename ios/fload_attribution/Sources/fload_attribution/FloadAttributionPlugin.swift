import Flutter
import Foundation
import os

/// The iOS half of the plugin: maps channel calls to the Fload iOS SDK,
/// vendored byte for byte in `Vendor/FloadAttribution` (see `VENDORED.txt`).
/// It uses only the SDK's public API.
public final class FloadAttributionPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.fload.attribution", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(FloadAttributionPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "configure":
            guard let key = arguments["key"] as? String else {
                return result(FlutterError(code: "bad_arguments", message: "configure needs a key", details: nil))
            }
            guard let options = Self.options(endpoint: arguments["endpoint"] as? String, logLevel: arguments["logLevel"] as? String) else {
                return result(FlutterError(code: "bad_arguments", message: "the endpoint is not a URL", details: nil))
            }
            Fload.configure(key: key, options: options)
            result(nil)
        case "setUserId":
            guard let userId = arguments["userId"] as? String else {
                return result(FlutterError(code: "bad_arguments", message: "setUserId needs a userId", details: nil))
            }
            Fload.setUserId(userId)
            result(nil)
        case "getInstallReference":
            result(Fload.installReference)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// The SDK's options from the channel's strings; nil when the endpoint is not a URL.
    static func options(endpoint: String?, logLevel: String?) -> FloadOptions? {
        var options = FloadOptions(logLevel: level(logLevel))
        if let endpoint, !endpoint.isEmpty {
            guard let url = URL(string: endpoint), url.scheme != nil else { return nil }
            options.endpoint = url
        }
        return options
    }

    static func level(_ name: String?) -> FloadLogLevel {
        switch name {
        case "none": return .none
        case "error": return .error
        case "info": return .info
        case "debug": return .debug
        default: return .warning
        }
    }
}
