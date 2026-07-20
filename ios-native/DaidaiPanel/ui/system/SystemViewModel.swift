import Foundation

@MainActor
final class SystemViewModel: ObservableObject {
    @Published var settings: [String: AnyCodable] = [:]
    @Published var logs: [[String: AnyCodable]] = []
    @Published var backups: [BackupData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var restoreProgress: RestoreProgressData?

    var concurrentTasks: Int {
        get { (settings["concurrent_tasks"]?.value as? Int) ?? 1 }
    }

    var logRetention: Int {
        get { (settings["log_retention_days"]?.value as? Int) ?? 30 }
    }

    var proxyUrl: String {
        get { (settings["proxy_url"]?.value as? String) ?? "" }
    }

    var dockerMirror: String {
        get { (settings["docker_mirror"]?.value as? String) ?? "" }
    }

    private var api: ApiService

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    func loadSettings() async {
        isLoading = true
        error = nil
        do {
            let response: ApiResponse<[String: AnyCodable]> = try await api.getPanelSettings()
            self.settings = response.data ?? [:]
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func saveSettings(_ newSettings: [String: Any]) async throws {
        let _: ApiResponse<EmptyData> = try await api.updatePanelSettings(newSettings)
        await loadSettings()
    }

    func loadLogs(page: Int = 1) async {
        isLoading = true
        error = nil
        do {
            let response: ApiResponse<PaginatedData<[String: AnyCodable]>> = try await api.getPanelLog(page: page)
            self.logs = response.data?.items ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func loadBackups() async {
        isLoading = true
        error = nil
        do {
            let response: ApiResponse<[BackupData]> = try await api.getBackups()
            self.backups = response.data ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func createBackup() async throws {
        let _: ApiResponse<EmptyData> = try await api.createBackup()
        await loadBackups()
    }

    func restore(backupName: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.restore(backupName: backupName)
    }

    func checkRestoreProgress() async {
        do {
            let response: ApiResponse<RestoreProgressData> = try await api.restoreProgress()
            self.restoreProgress = response.data
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
    }
}
