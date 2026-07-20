import Foundation
import Security

@propertyWrapper
struct KeychainItem {
    let key: String
    let service: String

    var wrappedValue: String? {
        get { KeychainStorage.read(service: service, account: key) }
        nonmutating set {
            if let newValue {
                KeychainStorage.save(service: service, account: key, value: newValue)
            } else {
                KeychainStorage.delete(service: service, account: key)
            }
        }
    }
}

final class KeychainStorage: ObservableObject {
    static let shared = KeychainStorage()
    private let service = "com.daidai.panel"

    private init() {}

    // MARK: - Properties

    @KeychainItem(key: "access_token", service: "com.daidai.panel")
    var accessToken: String?

    @KeychainItem(key: "refresh_token", service: "com.daidai.panel")
    var refreshToken: String?

    @KeychainItem(key: "trusted_login_until", service: "com.daidai.panel")
    var trustedLoginUntil: String?

    @KeychainItem(key: "trusted_login_server_url", service: "com.daidai.panel")
    var trustedLoginServerURL: String?

    @KeychainItem(key: "server_url", service: "com.daidai.panel")
    var serverURL: String?

    @KeychainItem(key: "panels_config", service: "com.daidai.panel")
    var panelsConfigJSON: String?

    @KeychainItem(key: "auth_user", service: "com.daidai.panel")
    var authUserJSON: String?

    // MARK: - Computed

    var authUser: User? {
        get {
            guard let json = authUserJSON, let data = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(User.self, from: data)
        }
        set {
            if let user = newValue, let data = try? JSONEncoder().encode(user) {
                authUserJSON = String(data: data, encoding: .utf8)
            } else {
                authUserJSON = nil
            }
        }
    }

    var isAuthenticated: Bool {
        accessToken != nil && !(accessToken?.isEmpty ?? true)
    }

    var trustedLoginServerURLValue: URL? {
        guard let trustedLoginServerURL, !trustedLoginServerURL.isEmpty else { return nil }
        return URL(string: trustedLoginServerURL)
    }

    var trustedLoginUntilDate: Date? {
        guard let trustedLoginUntil, let interval = TimeInterval(trustedLoginUntil) else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    var isTrustedLoginValid: Bool {
        guard let until = trustedLoginUntilDate else { return false }
        return until > Date()
    }

    // MARK: - Actions

    func saveAuthTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearAuth() {
        accessToken = nil
        refreshToken = nil
        authUserJSON = nil
    }

    func clearAll() {
        accessToken = nil
        refreshToken = nil
        trustedLoginUntil = nil
        trustedLoginServerURL = nil
        serverURL = nil
        panelsConfigJSON = nil
        authUserJSON = nil
    }

    func setTrustedLogin(until: Date, serverURL: String) {
        trustedLoginUntil = "\(until.timeIntervalSince1970)"
        trustedLoginServerURL = serverURL
    }

    func clearTrustedLogin() {
        trustedLoginUntil = nil
        trustedLoginServerURL = nil
    }

    // MARK: - Raw Keychain Operations

    static func save(service: String, account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(service: service, account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
