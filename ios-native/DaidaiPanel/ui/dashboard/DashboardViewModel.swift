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
        systemInfo?.hostname ?? dashboardData?.systemInfo?.hostname ?? "-"
    }

    var os: String {
        systemInfo?.os ?? dashboardData?.systemInfo?.os ?? "-"
    }

    var arch: String {
        systemInfo?.arch ?? dashboardData?.systemInfo?.arch ?? ""
    }

    var uptime: Int64 {
        systemInfo?.uptime ?? dashboardData?.systemInfo?.uptime ?? 0
    }

    var uptimeText: String {
        let seconds = uptime
        if seconds <= 0 { return "-" }
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 { return "\(days)天\(hours)小时" }
        if hours > 0 { return "\(hours)小时\(minutes)分" }
        return "\(minutes)分钟"
    }

    var cpuUsage: Double {
        systemInfo?.cpuUsage ?? dashboardData?.systemInfo?.cpuUsage ?? 0
    }

    var memoryUsage: Double {
        systemInfo?.memoryUsage ?? dashboardData?.systemInfo?.memoryUsage ?? 0
    }

    var memoryUsed: Int64 {
        systemInfo?.memoryUsed ?? dashboardData?.systemInfo?.memoryUsed ?? 0
    }

    var memoryTotal: Int64 {
        systemInfo?.memoryTotal ?? dashboardData?.systemInfo?.memoryTotal ?? 0
    }

    var diskUsage: Double {
        systemInfo?.diskUsage ?? dashboardData?.systemInfo?.diskUsage ?? 0
    }

    var diskUsed: Int64 {
        systemInfo?.diskUsed ?? dashboardData?.systemInfo?.diskUsed ?? 0
    }

    var diskTotal: Int64 {
        systemInfo?.diskTotal ?? dashboardData?.systemInfo?.diskTotal ?? 0
    }

    var taskCount: Int { dashboardData?.taskCount ?? 0 }
    var runningTaskCount: Int { dashboardData?.runningTaskCount ?? 0 }
    var enabledTaskCount: Int { dashboardData?.enabledTaskCount ?? 0 }
    var disabledTaskCount: Int { dashboardData?.disabledTaskCount ?? 0 }
    var todayRunCount: Int { dashboardData?.todayRunCount ?? 0 }
    var todayFailCount: Int { dashboardData?.todayFailCount ?? 0 }
    var depCount: Int { dashboardData?.depCount ?? 0 }
    var envCount: Int { dashboardData?.envCount ?? 0 }
    var subscriptionCount: Int { dashboardData?.subscriptionCount ?? 0 }

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
