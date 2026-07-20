import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var keychain: KeychainStorage

    @State private var showLogoutConfirm = false

    private var user: User? { authViewModel.state.user }

    var body: some View {
        NavigationStack {
            GlassScaffold {
                List {
                    userSection
                    appSettingsSection
                    systemManagementSection
                    otherSection
                    logoutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - User Section

    private var userSection: some View {
        Section {
            HStack(spacing: 14) {
                avatarView
                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.username ?? "未登录")
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack(spacing: 6) {
                        Text(roleText)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(roleColor.opacity(0.15))
                            .foregroundColor(roleColor)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.vertical, 4)
        }
    }

    private var avatarView: some View {
        Group {
            if let urlString = user?.avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.primary.opacity(0.6))
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.primary.opacity(0.6))
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppColors.glassCardBorder, lineWidth: 1))
    }

    private var roleText: String {
        switch user?.role {
        case "admin": return "管理员"
        case "operator": return "操作员"
        default: return "观察者"
        }
    }

    private var roleColor: Color {
        switch user?.role {
        case "admin": return AppColors.primary
        case "operator": return AppColors.blue500
        default: return AppColors.slate500
        }
    }

    // MARK: - App Settings

    private var appSettingsSection: some View {
        Section("应用设置") {
            AppListTile(icon: "paintpalette.fill", title: "主题设置") {
                navManager.navigate(to: .themeSettings)
            }

            AppListTile(icon: "lock.fill", title: "应用锁") {
                navManager.navigate(to: .appLock)
            }
        }
    }

    // MARK: - System Management

    private var systemManagementSection: some View {
        Section("系统管理") {
            AppListTile(icon: "arrow.triangle.2.circlepath", title: "订阅管理") {
                navManager.navigate(to: .subscriptions)
            }

            AppListTile(icon: "doc.text.fill", title: "脚本管理") {
                navManager.navigate(to: .scripts)
            }

            AppListTile(icon: "bell.fill", title: "通知管理") {
                navManager.navigate(to: .notifications)
            }

            AppListTile(icon: "shippingbox.fill", title: "依赖管理") {
                navManager.navigate(to: .deps)
            }

            if user?.isAdmin == true {
                AppListTile(icon: "person.2.fill", title: "用户管理") {
                    navManager.navigate(to: .users)
                }

                AppListTile(icon: "lock.shield.fill", title: "安全设置") {
                    navManager.navigate(to: .security)
                }

                AppListTile(icon: "gearshape.2.fill", title: "系统设置") {
                    navManager.navigate(to: .systemSettings)
                }

                AppListTile(icon: "doc.text.magnifyingglass", title: "面板日志") {
                    navManager.navigate(to: .panelLog)
                }

                AppListTile(icon: "externaldrive.fill", title: "备份恢复") {
                    navManager.navigate(to: .backup)
                }

                AppListTile(icon: "point.3.connected.trianglepath.dotted", title: "Open API") {
                    navManager.navigate(to: .openApi)
                }
            }
        }
    }

    // MARK: - Other

    private var otherSection: some View {
        Section("其他") {
            AppListTile(icon: "heart.fill", title: "赞助者") {
                navManager.navigate(to: .sponsors)
            }

            AppListTile(icon: "info.circle", title: "关于") {
                navManager.navigate(to: .about)
            }

            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                Text("版本")
                    .font(.body)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Logout

    private var logoutSection: some View {
        Section {
            Button {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text("退出登录")
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.error)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(AppColors.glassCard)
        }
        .alert("确认退出", isPresented: $showLogoutConfirm) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                Task { await authViewModel.logout() }
            }
        } message: {
            Text("确定要退出登录吗？")
        }
    }
}
