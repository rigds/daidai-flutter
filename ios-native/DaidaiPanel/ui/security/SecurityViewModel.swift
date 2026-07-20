import Foundation

@MainActor
final class SecurityViewModel: ObservableObject {
    @Published var loginLogs: [[String: AnyCodable]] = []
    @Published var sessions: [[String: AnyCodable]] = []
    @Published var ipWhitelist: [String] = []
    @Published var auditLogs: [[String: AnyCodable]] = []
    @Published var twoFaEnabled = false
    @Published var twoFaSetupData: TwoFaSetupData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTab: SecurityTab = .loginLogs

    enum SecurityTab: String, CaseIterable {
        case loginLogs = "登录日志"
        case sessions = "会话管理"
        case ipWhitelist = "IP 白名单"
        case twoFa = "2FA"
        case auditLogs = "审计日志"
    }

    private var api: ApiService

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let loginLogsResult = api.getLoginLogs(page: 1, pageSize: 50)
            async let sessionsResult = api.getSessions()
            async let whitelistResult = api.getIpWhitelist()
            async let auditResult = api.getAuditLogs(page: 1, pageSize: 50)
            async let twoFaResult = api.twoFaStatus()

            let (loginResp, sessionsResp, whitelistResp, auditResp, twoFaResp) = try await (
                loginLogsResult, sessionsResult, whitelistResult, auditResult, twoFaResult
            )
            self.loginLogs = loginResp.data?.items ?? []
            self.sessions = sessionsResp.data ?? []
            self.ipWhitelist = whitelistResp.data ?? []
            self.auditLogs = auditResp.data?.items ?? []
            self.twoFaEnabled = twoFaResp.data?.enabled ?? false
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func kickSession(_ sessionId: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.post(
            api.endpoints.sessions + "/\(sessionId)/kick"
        )
        await load()
    }

    func addWhitelist(ip: String) async throws {
        var list = ipWhitelist
        if !list.contains(ip) { list.append(ip) }
        let _: ApiResponse<EmptyData> = try await api.updateIpWhitelist(list)
        self.ipWhitelist = list
    }

    func removeWhitelist(ip: String) async throws {
        let list = ipWhitelist.filter { $0 != ip }
        let _: ApiResponse<EmptyData> = try await api.updateIpWhitelist(list)
        self.ipWhitelist = list
    }

    func setup2Fa() async {
        do {
            let response: ApiResponse<TwoFaSetupData> = try await api.twoFaSetup()
            self.twoFaSetupData = response.data
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
    }

    func verify2Fa(code: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.twoFaVerify(code: code)
        twoFaEnabled = true
        twoFaSetupData = nil
    }

    func disable2Fa() async throws {
        let _: ApiResponse<EmptyData> = try await api.twoFaVerify(code: "disable")
        twoFaEnabled = false
    }
}
