import Foundation

protocol AuthInterceptorDelegate: AnyObject {
    func authInterceptorDidFailAuth(_ interceptor: AuthInterceptor)
}

final class AuthInterceptor: NSObject, URLSessionTaskDelegate {
    weak var delegate: AuthInterceptorDelegate?

    private let keychain: KeychainStorage
    private var isRefreshing = false
    private var pendingRequests: [(URLRequest, CheckedContinuation<URLSession.DataTaskPublisher.Output, Error>)] = []
    private let lock = NSLock()

    init(keychain: KeychainStorage) {
        self.keychain = keychain
        super.init()
    }

    func intercept(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var modifiedRequest = request

        if let token = keychain.accessToken, !token.isEmpty {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let userAgentProvider = UserAgentProvider.shared
        modifiedRequest.setValue(userAgentProvider.userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in userAgentProvider.clientHeaders {
            modifiedRequest.setValue(value, forHTTPHeaderField: key)
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(for: modifiedRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            return (data, response)
        }

        if httpResponse.statusCode == 401 {
            return try await handle401(originalRequest: modifiedRequest, session: session)
        }

        return (data, response)
    }

    private func handle401(originalRequest: URLRequest, session: URLSession) async throws -> (Data, URLResponse) {
        lock.lock()
        if isRefreshing {
            lock.unlock()
            return try await waitForRefreshAndRetry(originalRequest: originalRequest, session: session)
        }
        isRefreshing = true
        lock.unlock()

        defer {
            lock.lock()
            isRefreshing = false
            lock.unlock()
        }

        guard let refreshToken = keychain.refreshToken, !refreshToken.isEmpty else {
            await MainActor.run { delegate?.authInterceptorDidFailAuth(self) }
            throw ApiError.unauthorized
        }

        guard let serverURL = keychain.serverURL,
              let url = URL(string: "\(serverURL)/api/auth/refresh") else {
            await MainActor.run { delegate?.authInterceptorDidFailAuth(self) }
            throw ApiError.invalidURL
        }

        var refreshRequest = URLRequest(url: url)
        refreshRequest.httpMethod = "POST"
        refreshRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        refreshRequest.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])

        let userAgentProvider = UserAgentProvider.shared
        refreshRequest.setValue(userAgentProvider.userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in userAgentProvider.clientHeaders {
            refreshRequest.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (refreshData, refreshResponse) = try await session.data(for: refreshRequest)
            guard let refreshHTTP = refreshResponse as? HTTPURLResponse,
                  refreshHTTP.statusCode == 200 else {
                keychain.clearAuth()
                await MainActor.run { delegate?.authInterceptorDidFailAuth(self) }
                throw ApiError.unauthorized
            }

            let refreshResult = try JSONDecoder().decode(ApiResponse<RefreshTokenData>.self, from: refreshData)
            guard refreshResult.isSuccess, let data = refreshResult.data else {
                keychain.clearAuth()
                await MainActor.run { delegate?.authInterceptorDidFailAuth(self) }
                throw ApiError.unauthorized
            }

            keychain.accessToken = data.accessToken
            keychain.refreshToken = data.refreshToken

            var retryRequest = originalRequest
            retryRequest.setValue("Bearer \(data.accessToken)", forHTTPHeaderField: "Authorization")
            return try await session.data(for: retryRequest)
        } catch {
            keychain.clearAuth()
            await MainActor.run { delegate?.authInterceptorDidFailAuth(self) }
            throw error
        }
    }

    private func waitForRefreshAndRetry(originalRequest: URLRequest, session: URLSession) async throws -> (Data, URLResponse) {
        try await Task.sleep(nanoseconds: 100_000_000)
        return try await intercept(originalRequest)
    }
}

private struct RefreshTokenData: Codable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

enum ApiError: Error, LocalizedError {
    case unauthorized
    case invalidURL
    case invalidResponse
    case serverError(Int, String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "认证失败，请重新登录"
        case .invalidURL: return "无效的请求地址"
        case .invalidResponse: return "无效的服务器响应"
        case .serverError(_, let msg): return msg
        case .decodingError(let err): return "数据解析错误: \(err.localizedDescription)"
        }
    }
}
