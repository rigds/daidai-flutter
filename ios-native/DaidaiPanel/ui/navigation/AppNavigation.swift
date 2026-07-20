import SwiftUI

enum AppRoute: Hashable {
    case boot
    case serverConfig
    case login
    case main
    case dashboard
    case tasks
    case logs
    case envs
    case more
    case taskForm(taskId: Int?)
    case logStream(logId: Int)
    case subscriptions
    case scripts
    case notifications
    case deps
    case users
    case security
    case systemSettings
    case panelLog
    case backup
    case openApi
    case themeSettings
    case appLock
    case sponsors
}

@MainActor
final class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func goToRoot() {
        path = NavigationPath()
    }

    func replace(with route: AppRoute) {
        path = NavigationPath()
        path.append(route)
    }
}

struct AppNavigationStack<Content: View>: View {
    @StateObject private var navManager = NavigationManager()
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack(path: $navManager.path) {
            content()
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
        }
        .environmentObject(navManager)
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .boot:
            BootPage()
        case .serverConfig:
            ServerConfigPage()
        case .login:
            LoginPage()
        case .main:
            MainTabView()
        case .dashboard:
            DashboardView()
        case .tasks:
            TaskListView()
        case .logs:
            LogListView()
        case .envs:
            EnvListView()
        case .more:
            MoreView()
        case .taskForm(let taskId):
            TaskFormPlaceholder(taskId: taskId)
        case .logStream(let logId):
            LogStreamPlaceholder(logId: logId)
        case .subscriptions:
            SubscriptionListView()
        case .scripts:
            ScriptListView()
        case .notifications:
            NotificationListView()
        case .deps:
            DepListView()
        case .users:
            UserListView()
        case .security:
            SecurityView()
        case .systemSettings:
            SystemSettingsView()
        case .panelLog:
            PanelLogView()
        case .backup:
            BackupView()
        case .openApi:
            OpenApiView()
        case .themeSettings:
            ThemeSettingsView()
        case .appLock:
            AppLockSettingsView()
        case .sponsors:
            SponsorView()
        }
    }
}

struct PlaceholderPage: View {
    let title: String
    let icon: String

    var body: some View {
        GlassScaffold {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primary.opacity(0.5))
                Text(title)
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("功能开发中...")
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TaskFormPlaceholder: View {
    let taskId: Int?

    var body: some View {
        PlaceholderPage(
            title: taskId == nil ? "新建任务" : "编辑任务",
            icon: "plus.circle.fill"
        )
    }
}

struct LogStreamPlaceholder: View {
    let logId: Int

    var body: some View {
        PlaceholderPage(title: "日志详情 #\(logId)", icon: "terminal.fill")
    }
}
