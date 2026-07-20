import SwiftUI

struct LogListView: View {
    @EnvironmentObject var apiService: ApiService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navManager: NavigationManager
    @StateObject private var viewModel = LogViewModel(api: ApiService(baseURL: "http://localhost", keychain: KeychainStorage.shared))

    @State private var showCleanConfirm = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            logContent
        }
    }

    private var logContent: some View {
        GlassScaffold {
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.logs.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView("加载中...")
                        Spacer()
                    }
                } else if viewModel.logs.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
        }
        .navigationTitle("执行日志")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showCleanConfirm = true
                    } label: {
                        Label("清空日志", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .fontWeight(.semibold)
                }
            }
        }
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.load()
        }
        .alert("确认清空", isPresented: $showCleanConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                Task { try? await viewModel.cleanLogs() }
            }
        } message: {
            Text("确定要清空所有日志吗？此操作不可恢复。")
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") { viewModel.error = nil }
            Button("重试") { Task { await viewModel.load() } }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.error) { newValue in
            showError = newValue != nil
        }
    }

    // MARK: - Log List

    private var logList: some View {
        List {
            ForEach(viewModel.logs) { log in
                logRow(log)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { try? await viewModel.deleteLog(log.id) }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        navManager.navigate(to: .logStream(logId: log.id))
                    }

                if viewModel.hasMore && log.id == viewModel.logs.last?.id {
                    HStack {
                        Spacer()
                        ProgressView()
                            .task { await viewModel.loadMore() }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.load() }
    }

    private func logRow(_ log: TaskLog) -> some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(log.taskName ?? "任务 #\(log.taskId)")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    StatusBadge(status: viewModel.statusType(for: log), size: .small)
                }

                HStack(spacing: 16) {
                    Label(TimeUtils.formatRelative(log.startedAt), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(log.durationText, systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !log.content.isEmpty {
                    Text(log.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无日志")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("任务执行后会在这里显示日志")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.tertiaryLabel))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .refreshable { await viewModel.load() }
    }
}


