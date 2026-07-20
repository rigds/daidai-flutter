import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var apiService: ApiService
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navManager: NavigationManager
    @StateObject private var viewModel = DashboardViewModel(api: ApiService(baseURL: "http://localhost", keychain: KeychainStorage.shared))
    @StateObject private var taskViewModel = TaskViewModel(api: ApiService(baseURL: "http://localhost", keychain: KeychainStorage.shared))
    var selectedTab: Binding<Int>?

    var body: some View {
        NavigationStack {
            GlassScaffold {
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        resourceSection
                        taskStatsSection
                        quickActionsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await viewModel.load()
                }
            }
            .navigationTitle("仪表盘")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    userAvatarButton
                }
            }
            .task {
                viewModel.updateAPI(apiService)
                taskViewModel.updateAPI(apiService)
                await viewModel.load()
            }
            .alert("错误", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("确定") { viewModel.error = nil }
                Button("重试") {
                    Task { await viewModel.load() }
                }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.hostname)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label(viewModel.os, systemImage: "desktopcomputer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !viewModel.arch.isEmpty {
                            Text(viewModel.arch)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(Capsule())
                                .foregroundColor(AppColors.primary)
                        }
                    }

                    Label("运行 \(viewModel.uptimeText)", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let user = authViewModel.state.user {
                    VStack(spacing: 4) {
                        avatarView(url: user.avatarUrl, size: 44)
                        Text(user.username)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var userAvatarButton: some View {
        Group {
            if let user = authViewModel.state.user {
                avatarView(url: user.avatarUrl, size: 28)
                    .onTapGesture {
                        navManager.navigate(to: .more)
                    }
            }
        }
    }

    private func avatarView(url: String?, size: CGFloat) -> some View {
        Group {
            if let urlString = url, !urlString.isEmpty, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        fallbackAvatar(size: size)
                    default:
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
            } else {
                fallbackAvatar(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppColors.glassCardBorder, lineWidth: 1))
    }

    private func fallbackAvatar(size: CGFloat) -> some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: size))
            .foregroundColor(AppColors.primary.opacity(0.6))
    }

    // MARK: - Resources

    private var resourceSection: some View {
        HStack(spacing: 12) {
            ResourceCard.cpu(percentage: viewModel.cpuUsage)
            ResourceCard.memory(percentage: viewModel.memoryUsage)
            ResourceCard.disk(percentage: viewModel.diskUsage)
        }
    }

    // MARK: - Task Stats

    private var taskStatsSection: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("任务概览", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                    .foregroundColor(.primary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    statItem(count: viewModel.taskCount, label: "总任务", color: AppColors.info)
                    statItem(count: viewModel.runningTaskCount, label: "运行中", color: AppColors.success)
                    statItem(count: viewModel.todaySuccessCount, label: "今日成功", color: AppColors.primary)
                    statItem(count: viewModel.todayFailCount, label: "今日失败", color: AppColors.error)
                }

                Divider()

                HStack(spacing: 16) {
                    miniStat(count: viewModel.enabledTaskCount, label: "已启用", icon: "checkmark.circle")
                }
            }
        }
    }

    private func statItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func miniStat(count: Int, label: String, icon: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("快捷操作", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    quickAction(icon: "play.fill", title: "运行全部", color: AppColors.success) {
                        Task {
                            await taskViewModel.load()
                            let enabledIds = taskViewModel.tasks.filter { $0.isEnabled }.map { $0.id }
                            if !enabledIds.isEmpty {
                                try? await taskViewModel.batchRun(enabledIds)
                            }
                        }
                    }
                    quickAction(icon: "plus.circle", title: "新建任务", color: AppColors.primary) {
                        navManager.navigate(to: .taskForm(taskId: nil))
                    }
                    quickAction(icon: "list.bullet", title: "任务管理", color: AppColors.amber500) {
                        if let binding = selectedTab {
                            binding.wrappedValue = 1
                        } else {
                            navManager.navigate(to: .tasks)
                        }
                    }
                    quickAction(icon: "terminal", title: "查看日志", color: AppColors.blue500) {
                        if let binding = selectedTab {
                            binding.wrappedValue = 2
                        } else {
                            navManager.navigate(to: .logs)
                        }
                    }
                    quickAction(icon: "key", title: "环境变量", color: AppColors.purple500) {
                        navManager.navigate(to: .envs)
                    }
                    quickAction(icon: "arrow.triangle.2.circlepath", title: "订阅管理", color: AppColors.amber500) {
                        navManager.navigate(to: .subscriptions)
                    }
                    quickAction(icon: "shippingbox", title: "依赖管理", color: AppColors.slate500) {
                        navManager.navigate(to: .deps)
                    }
                    quickAction(icon: "gearshape", title: "系统设置", color: AppColors.slate600) {
                        navManager.navigate(to: .systemSettings)
                    }
                }
            }
        }
    }

    private func quickAction(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColors.glassBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
