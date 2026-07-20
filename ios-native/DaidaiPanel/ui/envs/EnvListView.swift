import SwiftUI

struct EnvListView: View {
    @EnvironmentObject var apiService: ApiService
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = EnvViewModel(api: ApiService(baseURL: "http://localhost", keychain: KeychainStorage.shared))

    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            envContent
        }
    }

    private var envContent: some View {
        GlassScaffold {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, placeholder: "搜索环境变量...") {
                    viewModel.keyword = searchText
                    Task { await viewModel.load() }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                groupFilter
                envList
            }
        }
        .navigationTitle("环境变量")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.load()
        }
        .sheet(isPresented: $showAddSheet) {
            EnvFormSheet(viewModel: viewModel, isPresented: $showAddSheet)
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .onChange(of: viewModel.error) { newValue in
            showError = newValue != nil
        }
    }

    // MARK: - Group Filter

    private var groupFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "全部", value: "")
                ForEach(viewModel.groups, id: \.self) { group in
                    filterChip(label: group, value: group)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func filterChip(label: String, value: String) -> some View {
        Button {
            viewModel.selectedGroup = value
            Task { await viewModel.load() }
        } label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(viewModel.selectedGroup == value ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .foregroundColor(viewModel.selectedGroup == value ? .white : .primary)
                .background(
                    Capsule()
                        .fill(viewModel.selectedGroup == value ? AppColors.primary : AppColors.glassBg)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Env List

    private var envList: some View {
        Group {
            if viewModel.isLoading && viewModel.envs.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                }
            } else if viewModel.envs.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.envs) { env in
                            envCard(env)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .refreshable { await viewModel.load() }
            }
        }
    }

    private func envCard(_ env: EnvVar) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                        .frame(width: 24, height: 24)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(env.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { env.enabled },
                        set: { _ in Task { try? await viewModel.toggleEnv(env) } }
                    ))
                    .tint(AppColors.primary)
                    .labelsHidden()
                    .scaleEffect(0.8)
                }

                HStack {
                    Text(viewModel.maskedValue(env.value))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = env.value
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(AppColors.primary)
                    }
                    .buttonStyle(.plain)
                }

                if !env.group.isEmpty || !env.remarks.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(env.groups, id: \.self) { group in
                            Text(group)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.purple100)
                                .foregroundColor(AppColors.purple600)
                                .clipShape(Capsule())
                        }

                            if !env.remarks.isEmpty {
                            Text(env.remarks)
                                .font(.caption2)
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                }
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = env.value
            } label: {
                Label("复制值", systemImage: "doc.on.doc")
            }

            Button {
                UIPasteboard.general.string = env.name
            } label: {
                Label("复制名称", systemImage: "textformat.abc")
            }

            Divider()

            Button {
                Task { try? await viewModel.toggleEnv(env) }
            } label: {
                Label(env.enabled ? "禁用" : "启用", systemImage: env.enabled ? "pause.circle" : "checkmark.circle")
            }

            Button(role: .destructive) {
                Task { try? await viewModel.deleteEnv(env.id) }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无环境变量")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("环境变量可在任务中引用")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.tertiaryLabel))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .refreshable { await viewModel.load() }
    }
}

// MARK: - Add/Edit Sheet

struct EnvFormSheet: View {
    @ObservedObject var viewModel: EnvViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var value = ""
    @State private var remarks = ""
    @State private var group = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("变量名", text: $name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("变量值", text: $value)
                }

                Section("分组与备注") {
                    TextField("分组（可选）", text: $group)
                    TextField("备注（可选）", text: $remarks)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(AppColors.error)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("添加环境变量")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || value.isEmpty || isLoading)
                }
            }
        }
    }

    private func save() async {
        isLoading = true
        error = nil

        var body: [String: Any] = [
            "name": name,
            "value": value,
            "remarks": remarks,
            "group": group
        ]

        do {
            try await viewModel.createEnv(body: body)
            isPresented = false
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }
}


