import Foundation

final class AuthService {
    private let api: ApiService
    private let keychain: KeychainStorage

    init(api: ApiService, keychain: KeychainStorage) {
        self.api = api
        self.keychain = keychain
    }

    func checkInit() async throws -> Bool {
        let result: ApiResponse<CheckInitData> = try await api.checkInit()
        return result.data?.initialized ?? false
    }

    func initAdmin(username: String, password: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.initAdmin(username: username, password: password)
    }

    func login(username: String, password: String, captcha: String? = nil) async throws -> User {
        // Use raw request to handle non-standard response format
        var body: [String: Any] = ["username": username, "password": password]
        if let captcha { body["captcha"] = captcha }

        let (data, response) = try await api.requestRaw(api.endpoints.login, method: "POST", body: body)

        guard response.statusCode == 200 else {
            // Parse error message from server response
            let message: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                message = json["error"] as? String
                    ?? json["message"] as? String
                    ?? "登录失败 (\(response.statusCode))"
            } else {
                message = "登录失败 (\(response.statusCode))"
            }
            throw ApiError.serverError(response.statusCode, message)
        }

        // Parse success response - server returns {"access_token": "...", "refresh_token": "..."}
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ApiError.invalidResponse
        }

        let accessToken = json["access_token"] as? String ?? ""
        let refreshToken = json["refresh_token"] as? String ?? ""

        guard !accessToken.isEmpty else {
            throw ApiError.invalidResponse
        }

        keychain.saveAuthTokens(accessToken: accessToken, refreshToken: refreshToken)

        // Fetch user info
        let user = try await getUser()
        keychain.authUser = user
        return user
    }

    func logout() async {
        do {
            let _: ApiResponse<EmptyData> = try await api.logout()
        } catch {}
        keychain.clearAuth()
    }

    func refreshToken() async throws {
        guard let refreshToken = keychain.refreshToken else {
            throw ApiError.unauthorized
        }

        let result: ApiResponse<RefreshTokenData> = try await api.refreshToken(refreshToken)
        guard let data = result.data else {
            throw ApiError.invalidResponse
        }

        keychain.saveAuthTokens(accessToken: data.accessToken, refreshToken: data.refreshToken)
    }

    func getUser() async throws -> User {
        let (data, response) = try await api.requestRaw(api.endpoints.getUser)
        guard response.statusCode == 200 else {
            throw ApiError.serverError(response.statusCode, "获取用户信息失败")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ApiError.invalidResponse
        }

        // Server returns {"user": {...}} or {"data": {...}}
        let userData = json["user"] as? [String: Any]
            ?? json["data"] as? [String: Any]
            ?? json

        guard let jsonData = try? JSONSerialization.data(withJSONObject: userData) else {
            throw ApiError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            return DateParser.parse(dateString) ?? Date()
        }

        let user = try decoder.decode(User.self, from: jsonData)
        keychain.authUser = user
        return user
    }

    func changePassword(oldPassword: String, newPassword: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.changePassword(oldPassword: oldPassword, newPassword: newPassword)
    }

    func captchaConfig() async throws -> CaptchaConfigData? {
        let result: ApiResponse<CaptchaConfigData> = try await api.captchaConfig()
        return result.data
    }
}
