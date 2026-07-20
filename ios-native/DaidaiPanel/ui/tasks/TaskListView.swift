import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var apiService: ApiService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navManager: NavigationManager
    @StateObject private var viewModel = TaskViewModel(api: ApiService(baseURL: "http://localhost", keychain: KeychainStorage.shared))

    @State private var isEditing = false
    @State private var selectedIds: Set<Int> = []
    @State private var showError = false
    @State private var searchText = ""

    private let statusFilters: [(label: String, value: String)] = [
        ("全部", ""),
        ("已启用", "1"),
        ("已禁用", "0"),
        ("运行中", "2"),
        ("排队中", "0.5")
    ]

    var body: some View {
        NavigationStack {
            GlassScaffold {
                VStack(spacing: 0) {
                    searchBar
                    filterChips
                    taskList
                }
            }
            .navigationTitle("任务管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            isEditing.toggle()
                            if !isEditing { selectedIds.removeAll() }
                        } label: {
                            Text(isEditing ? "完成" : "编辑")
                                .font(.subheadline)
                        }

                        Button {
                            navManager.navigate(to: .taskForm(taskId: nil))
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                    }
                }

                if isEditing && !selectedIds.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        editToolbar
                    }
                }
            }
            .task {
                viewModel.updateAPI(apiService)
                await viewModel.load()
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
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索任务...", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    viewModel.keyword = searchText
                    Task { await viewModel.load() }
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.keyword = ""
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            Group {
                if themeManager.glassMode {
                    RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 12).fill(AppColors.glassCard)
                }
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.glassCardBorder, lineWidth: 0.5))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Filters

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(statusFilters, id: \.value) { filter in
                    Button {
                        viewModel.statusFilter = filter.value
                        Task { await viewModel.load() }
                    } label: {
                        Text(filter.label)
                            .font(.subheadline)
                            .fontWeight(viewModel.statusFilter == filter.value ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .foregroundColor(viewModel.statusFilter == filter.value ? .white : .primary)
                            .background(
                                Capsule()
                                    .fill(viewModel.statusFilter == filter.value ? AppColors.primary : AppColors.glassBg)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        Group {
            if viewModel.isLoading && viewModel.tasks.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                }
            } else if viewModel.tasks.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.tasks) { task in
                        taskRow(task)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                swipeDeleteButton(task)
                            }
                            .swipeActions(edge: .leading) {
                                swipeRunButton(task)
                                swipeEnableButton(task)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    if viewModel.hasMore {
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await viewModel.load() }
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack {
            if isEditing {
                Button {
                    if selectedIds.contains(task.id) {
                        selectedIds.remove(task.id)
                    } else {
                        selectedIds.insert(task.id)
                    }
                } label: {
                    Image(systemName: selectedIds.contains(task.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedIds.contains(task.id) ? AppColors.primary : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            GlassCard(padding: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if task.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(AppColors.amber500)
                        }
                        Text(task.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer()
                        StatusBadge(status: viewModel.statusType(for: task), size: .small)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(task.cronExpression)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        if let lastRun = task.lastRunAt {
                            Label(TimeUtils.formatRelative(lastRun), systemImage: "clock.arrow.circlepath")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        ForEach(task.userLabelsForDisplay.prefix(2), id: \.self) { label in
                            Text(label)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.blue100)
                                .foregroundColor(AppColors.blue600)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func swipeRunButton(_ task: TaskItem) -> some View {
        Button {
            Task {
                if task.isRunning {
                    try? await viewModel.stopTask(task.id)
                } else {
                    try? await viewModel.runTask(task.id)
                }
            }
        } label: {
            Label(task.isRunning ? "停止" : "运行", systemImage: task.isRunning ? "stop.fill" : "play.fill")
        }
        .tint(task.isRunning ? AppColors.warning : AppColors.success)
    }

    private func swipeEnableButton(_ task: TaskItem) -> some View {
        Button {
            Task {
                if task.isEnabled || task.isRunning {
                    try? await viewModel.disableTask(task.id)
                } else {
                    try? await viewModel.enableTask(task.id)
                }
            }
        } label: {
            Label(
                task.isEnabled || task.isRunning ? "禁用" : "启用",
                systemImage: task.isEnabled || task.isRunning ? "pause.circle" : "checkmark.circle"
            )
        }
        .tint(task.isEnabled || task.isRunning ? AppColors.slate400 : AppColors.primary)
    }

    private func swipeDeleteButton(_ task: TaskItem) -> some View {
        Button(role: .destructive) {
            Task { try? await viewModel.deleteTask(task.id) }
        } label: {
            Label("删除", systemImage: "trash")
        }
    }

    private var editToolbar: some View {
        HStack(spacing: 16) {
            Button("全选") {
                selectedIds = Set(viewModel.tasks.map(\.id))
            }
            .font(.subheadline)

            Divider().frame(height: 20)

            Button("运行") {
                Task { try? await viewModel.batchRun(Array(selectedIds)) }
            }
            .font(.subheadline)
            .foregroundColor(AppColors.success)

            Button("启用") {
                Task { try? await viewModel.batchEnable(Array(selectedIds)) }
            }
            .font(.subheadline)
            .foregroundColor(AppColors.primary)

            Button("禁用") {
                Task { try? await viewModel.batchDisable(Array(selectedIds)) }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Button("删除") {
                Task { try? await viewModel.batchDelete(Array(selectedIds)) }
            }
            .font(.subheadline)
            .foregroundColor(AppColors.error)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无任务")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("创建第一个任务") {
                navManager.navigate(to: .taskForm(taskId: nil))
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}


