import SwiftUI

struct NotificationListView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = NotificationViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var showAddSheet = false
    @State private var editingChannel: NotifyChannel?
    @State private var showDeleteConfirm = false
    @State private var channelToDelete: NotifyChannel?
    @State private var showTestResult = false
    @State private var testMessage = ""

    var body: some View {
        GlassScaffold {
            Group {
                if viewModel.isLoading && viewModel.channels.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.channels.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("通知管理")
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
            NotificationFormView(viewModel: viewModel, types: viewModel.types)
        }
        .sheet(item: $editingChannel) { channel in
            NotificationFormView(viewModel: viewModel, types: viewModel.types, channel: channel)
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let ch = channelToDelete {
                    Task { try? await viewModel.delete(ch.id) }
                }
            }
        } message: {
            Text("确定要删除通知渠道「\(channelToDelete?.name ?? "")」吗？")
        }
        .alert(testMessage, isPresented: $showTestResult) {
            Button("确定", role: .cancel) {}
        }
    }

    private func load() async {
        viewModel.updateAPI(apiService)
        await viewModel.load()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无通知渠道")
                .font(.title3)
                .foregroundColor(.secondary)
            Button("添加通知渠道") { showAddSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listView: some View {
        List {
            ForEach(viewModel.channels) { channel in
                NotificationChannelRow(channel: channel)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            channelToDelete = channel
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash.fill")
                        }
                        .tint(AppColors.error)

                        Button {
                            Task { try? await viewModel.toggle(channel) }
                        } label: {
                            Label(channel.enabled ? "禁用" : "启用",
                                  systemImage: channel.enabled ? "pause.circle.fill" : "play.circle.fill")
                        }
                        .tint(channel.enabled ? AppColors.warning : AppColors.primary)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            Task {
                                do {
                                    try await viewModel.test(channel.id)
                                    testMessage = "测试消息已发送"
                                } catch {
                                    testMessage = "测试失败: \(ApiUtils.extractErrorMessage(from: error))"
                                }
                                showTestResult = true
                            }
                        } label: {
                            Label("测试", systemImage: "paperplane.fill")
                        }
                        .tint(AppColors.blue500)
                    }
                    .onTapGesture { editingChannel = channel }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Channel Row

struct NotificationChannelRow: View {
    let channel: NotifyChannel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 36, height: 36)
                .background(AppColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.headline)
                Text(typeName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if channel.enabled {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(AppColors.disabled)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 2)
    }

    private var typeIcon: String {
        switch channel.type {
        case "telegram": return "paperplane.fill"
        case "wechat", "wecom": return "message.fill"
        case "dingtalk": return "bubble.left.fill"
        case "feishu": return "bird.fill"
        case "email": return "envelope.fill"
        case "webhook": return "globe"
        case "bark": return "bell.fill"
        case "gotify": return "bolt.fill"
        default: return "bell.fill"
        }
    }

    private var typeName: String {
        switch channel.type {
        case "telegram": return "Telegram"
        case "wechat": return "微信"
        case "wecom": return "企业微信"
        case "dingtalk": return "钉钉"
        case "feishu": return "飞书"
        case "email": return "邮件"
        case "webhook": return "Webhook"
        case "bark": return "Bark"
        case "gotify": return "Gotify"
        default: return channel.type
        }
    }
}

// MARK: - Notification Form

struct NotificationFormView: View {
    @ObservedObject var viewModel: NotificationViewModel
    @Environment(\.dismiss) var dismiss

    let types: [NotifyTypeData]
    var channel: NotifyChannel?

    @State private var name = ""
    @State private var selectedType = ""
    @State private var configValues: [String: String] = [:]
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                    Picker("类型", selection: $selectedType) {
                        ForEach(types, id: \.type) { t in
                            Text(t.name).tag(t.type)
                        }
                    }
                }

                if let typeData = types.first(where: { $0.type == selectedType }),
                   let fields = typeData.fields {
                    Section("配置") {
                        ForEach(fields, id: \.key) { field in
                            if field.type == "password" {
                                SecureField(field.label, text: binding(for: field.key))
                            } else {
                                TextField(field.placeholder ?? field.label, text: binding(for: field.key))
                                    .autocapitalization(.none)
                            }
                        }
                    }
                }
            }
            .navigationTitle(channel == nil ? "添加通知" : "编辑通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.isEmpty || selectedType.isEmpty)
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

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { configValues[key] ?? "" },
            set: { configValues[key] = $0 }
        )
    }

    private func loadExisting() {
        guard let ch = channel else {
            if selectedType.isEmpty, let first = types.first {
                selectedType = first.type
            }
            return
        }
        name = ch.name
        selectedType = ch.type
        for (key, value) in ch.config {
            if let str = value.value as? String {
                configValues[key] = str
            }
        }
    }

    private func save() {
        var body: [String: Any] = [
            "name": name,
            "type": selectedType,
            "config": configValues
        ]
        Task {
            do {
                if let ch = channel {
                    try await viewModel.update(ch.id, body: body)
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
