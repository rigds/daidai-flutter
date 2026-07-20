import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tag(0)
                .tabItem {
                    Label("主页", systemImage: selectedTab == 0 ? "square.grid.2x2.fill" : "square.grid.2x2")
                }

            TaskListView()
                .tag(1)
                .tabItem {
                    Label("任务", systemImage: selectedTab == 1 ? "clock.fill" : "clock")
                }

            LogListView()
                .tag(2)
                .tabItem {
                    Label("日志", systemImage: selectedTab == 2 ? "terminal.fill" : "terminal")
                }

            EnvListView()
                .tag(3)
                .tabItem {
                    Label("环境变量", systemImage: selectedTab == 3 ? "key.fill" : "key")
                }

            MoreView()
                .tag(4)
                .tabItem {
                    Label("更多", systemImage: "ellipsis")
                }
        }
        .tint(AppColors.primary)
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: themeManager.glassMode) { _ in
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()

        if themeManager.glassMode {
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor.clear
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
        }

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppColors.primary),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
