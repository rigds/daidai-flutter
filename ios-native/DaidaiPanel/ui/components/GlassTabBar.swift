import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    let tabs: [TabItem] = [
        TabItem(
            icon: "square.grid.2x2",
            activeIcon: "square.grid.2x2.fill",
            label: "主页"
        ),
        TabItem(
            icon: "clock",
            activeIcon: "clock.fill",
            label: "任务"
        ),
        TabItem(
            icon: "terminal",
            activeIcon: "terminal.fill",
            label: "日志"
        ),
        TabItem(
            icon: "key",
            activeIcon: "key.fill",
            label: "环境变量"
        ),
        TabItem(
            icon: "ellipsis",
            activeIcon: "ellipsis",
            label: "更多"
        )
    ]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Dashboard
            Text("Dashboard View")
                .tag(0)
                .tabItem {
                    tabItemView(for: 0)
                }
            
            // Tab 1: Tasks
            Text("Tasks View")
                .tag(1)
                .tabItem {
                    tabItemView(for: 1)
                }
            
            // Tab 2: Logs
            Text("Logs View")
                .tag(2)
                .tabItem {
                    tabItemView(for: 2)
                }
            
            // Tab 3: Envs
            Text("Envs View")
                .tag(3)
                .tabItem {
                    tabItemView(for: 3)
                }
            
            // Tab 4: More
            Text("More View")
                .tag(4)
                .tabItem {
                    tabItemView(for: 4)
                }
        }
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: themeManager.glassMode) { _ in
            configureTabBarAppearance()
        }
    }
    
    private func tabItemView(for index: Int) -> some View {
        let tab = tabs[index]
        let isActive = selectedTab == index
        
        return VStack(spacing: 2) {
            Image(systemName: isActive ? tab.activeIcon : tab.icon)
                .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? Color(AppColors.primary) : .secondary)
            
            Text(tab.label)
                .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? Color(AppColors.primary) : .secondary)
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        if themeManager.glassMode {
            // Glass mode: transparent background with blur effect
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor.clear
            
            // Configure normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 10, weight: .regular)
            ]
            
            // Configure selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(AppColors.primary))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(AppColors.primary)),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
        } else {
            // Classic mode: solid background
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Configure normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.systemFont(ofSize: 10, weight: .regular)
            ]
            
            // Configure selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(AppColors.primary))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(AppColors.primary)),
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct TabItem {
    let icon: String
    let activeIcon: String
    let label: String
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab = 0
        
        var body: some View {
            GlassTabBar(selectedTab: $selectedTab)
                .environmentObject(ThemeManager.shared)
        }
    }
    
    return PreviewWrapper()
}