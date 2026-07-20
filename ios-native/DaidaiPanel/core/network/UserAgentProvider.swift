import Foundation
import UIKit

struct UserAgentProvider {
    static let shared = UserAgentProvider()

    private let appVersion: String
    private let deviceModel: String
    private let deviceName: String
    private let osVersion: String

    private init() {
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        deviceModel = Self.getDeviceModel()
        deviceName = UIDevice.current.name
        osVersion = UIDevice.current.systemVersion
    }

    var userAgent: String {
        "DaidaiPanelApp/\(appVersion) (\(deviceModel); iOS \(osVersion))"
    }

    var clientHeaders: [String: String] {
        [
            "X-Client-App": "DaidaiPanelApp",
            "X-Client-Type": "ios",
            "X-Client-Platform": "iOS",
            "X-Client-Version": appVersion,
            "X-Device-Model": deviceModel,
            "X-Device-Name": deviceName,
            "X-OS-Version": "iOS \(osVersion)",
        ]
    }

    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier += String(UnicodeScalar(UInt8(value)))
        }
    }
}
