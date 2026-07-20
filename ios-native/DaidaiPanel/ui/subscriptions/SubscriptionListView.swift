import SwiftUI

struct SubscriptionListView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = SubscriptionViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var showAddSheet = false
    @State private var editingSub: Subscription?
    @State private var showDeleteConfirm = false
    @State private var subToDelete: Subscription?

    var body: some View {
        GlassScaffold {
            Group {
                if viewModel.isLoading && viewModel.subscriptions.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.subscriptions.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("订阅管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $showAddSheet) {
            SubscriptionFormView(viewModel: viewModel)
        }
        .sheet(item: $editingSub) { sub in
            SubscriptionFormView(viewModel: viewModel, subscription: sub)
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let sub = subToDelete {
                    Task { try? await viewModel.delete(sub.id) }
                }
            }
        } message: {
            Text("确定要删除订阅「\(subToDelete?.name ?? "")」吗？")
        }
    }

    private func load() async {
        viewModel.updateAPI(apiService)
        await viewModel.load()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无订阅")
                .font(.title3)
                .foregroundColor(.secondary)
            Button("添加订阅") { showAddSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listView: some View {
        List {
            ForEach(viewModel.subscriptions) { sub in
                SubscriptionCard(sub: sub)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            subToDelete = sub
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash.fill")
                        }
                        .tint(AppColors.error)

                        Button {
                            Task { try? await viewModel.toggle(sub) }
                        } label: {
                            Label(sub.enabled ? "禁用" : "启用",
                                  systemImage: sub.enabled ? "pause.circle.fill" : "play.circle.fill")
                        }
                        .tint(sub.enabled ? AppColors.warning : AppColors.primary)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            Task { try? await viewModel.pull(sub.id) }
                        } label: {
                            Label("拉取", systemImage: "arrow.down.circle.fill")
                        }
                        .tint(AppColors.blue500)
                    }
                    .onTapGesture { editingSub = sub }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let sub: Subscription

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sub.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(sub.typeLabel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppColors.blue500.opacity(0.15))
                    .foregroundColor(AppColors.blue500)
                    .clipShape(Capsule())
                statusBadge
            }
            Text(sub.url)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            HStack {
                if let lastPull = sub.lastPullAt {
                    Label(TimeUtils.formatRelative(lastPull), systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(sub.schedule)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(sub.statusText)
                .font(.caption2)
                .foregroundColor(statusColor)
        }
    }

    private var statusColor: Color {
        if sub.isRunning { return AppColors.primary }
        if sub.enabled { return AppColors.blue500 }
        return AppColors.disabled
    }
}

// MARK: - Subscription Form

struct SubscriptionFormView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) var dismiss

    var subscription: Subscription?

    @State private var name = ""
    @State private var type = "public-repo"
    @State private var url = ""
    @State private var branch = "main"
    @State private var schedule = ""
    @State private var autoAddTask = true
    @State private var showError = false
    @State private var errorMessage = ""

    private let types = ["public-repo", "private-repo", "single-file"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                    Picker("类型", selection: $type) {
                        ForEach(types, id: \.self) { t in
                            Text(typeLabel(t)).tag(t)
                        }
                    }
                    TextField("URL", text: $url)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                }
                Section("配置") {
                    TextField("分支", text: $branch)
                    TextField("定时规则 (Cron)", text: $schedule)
                    Toggle("自动添加任务", isOn: $autoAddTask)
                }
            }
            .navigationTitle(subscription == nil ? "添加订阅" : "编辑订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.isEmpty || url.isEmpty)
                }
            }
            .onAppear { loadExisting() }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func typeLabel(_ t: String) -> String {
        switch t {
        case "public-repo": return "公开仓库"
        case "private-repo": return "私有仓库"
        case "single-file": return "单文件"
        default: return t
        }
    }

    private func loadExisting() {
        guard let sub = subscription else { return }
        name = sub.name
        type = sub.normalizedType
        url = sub.url
        branch = sub.branch
        schedule = sub.schedule
        autoAddTask = sub.autoAddTask
    }

    private func save() {
        let body: [String: Any] = [
            "name": name,
            "type": type,
            "url": url,
            "branch": branch,
            "schedule": schedule,
            "auto_add_task": autoAddTask
        ]
        Task {
            do {
                if let sub = subscription {
                    try await viewModel.update(sub.id, body: body)
                } else {
                    try await viewModel.create(body: body)
                }
                dismiss()
            } catch {
                errorMessage = ApiUtils.extractErrorMessage(from: error)
                showError = true
            }
        }
    }
}
