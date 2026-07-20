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
        let result: ApiResponse<LoginData> = try await api.login(username: username, password: password, captcha: captcha)
        guard let data = result.data else {
            throw ApiError.invalidResponse
        }

        keychain.saveAuthTokens(accessToken: data.accessToken, refreshToken: data.refreshToken)
        keychain.authUser = data.user
        return data.user
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
        let result: ApiResponse<User> = try await api.getUser()
        guard let user = result.data else {
            throw ApiError.invalidResponse
        }
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
