import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var dashboardData: DashboardData?
    @Published var systemInfo: SystemInfoData?
    @Published var isLoading = false
    @Published var error: String?

    private var api: ApiService

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    var hostname: String {
        systemInfo?.hostname ?? "-"
    }

    var os: String {
        systemInfo?.os ?? "-"
    }

    var arch: String {
        systemInfo?.arch ?? ""
    }

    var uptimeText: String {
        systemInfo?.uptime ?? "-"
    }

    var cpuUsage: Double {
        systemInfo?.cpuUsage ?? 0
    }

    var memoryUsage: Double {
        systemInfo?.memoryUsage ?? 0
    }

    var memoryUsed: Int64 {
        systemInfo?.memoryUsed ?? 0
    }

    var memoryTotal: Int64 {
        systemInfo?.memoryTotal ?? 0
    }

    var diskUsage: Double {
        systemInfo?.diskUsage ?? 0
    }

    var diskUsed: Int64 {
        systemInfo?.diskUsed ?? 0
    }

    var diskTotal: Int64 {
        systemInfo?.diskTotal ?? 0
    }

    var taskCount: Int { dashboardData?.taskCount ?? 0 }
    var runningTaskCount: Int { dashboardData?.runningTaskCount ?? 0 }
    var enabledTaskCount: Int { dashboardData?.enabledTaskCount ?? 0 }
    var todaySuccessCount: Int { dashboardData?.todaySuccessCount ?? 0 }
    var todayFailCount: Int { dashboardData?.todayFailCount ?? 0 }
    var dailyStats: [DailyStat] { dashboardData?.dailyStats ?? [] }

    var memoryText: String {
        "\(TimeUtils.formatFileSize(memoryUsed)) / \(TimeUtils.formatFileSize(memoryTotal))"
    }

    var diskText: String {
        "\(TimeUtils.formatFileSize(diskUsed)) / \(TimeUtils.formatFileSize(diskTotal))"
    }

    func load() async {
        isLoading = true
        error = nil

        async let dashboardResult: ApiResponse<DashboardData> = api.dashboard()
        async let systemResult: ApiResponse<SystemInfoData> = api.systemInfo()

        do {
            let (dash, sys) = try await (dashboardResult, systemResult)
            self.dashboardData = dash.data
            self.systemInfo = sys.data
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }

        isLoading = false
    }
}
